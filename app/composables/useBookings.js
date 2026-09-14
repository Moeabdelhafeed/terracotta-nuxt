/**
 * Workshop bookings: availability, quote, hold → pay, my bookings, detail actions and the
 * finished-piece delivery step. Every call goes through `useApi()` / `useApiFetch()`.
 *
 * Dates and times the API returns (`booking_date`, `start_time`, `end_time`) are already
 * studio time — they are shown as the strings they arrive as, never parsed as instants.
 */

export const ACTIVE_STATUSES = [
  "pending_payment",
  "confirmed",
  "attending",
  "preparing",
];

const localeKeys = () => [useCookie("lang"), useCookie("i18n_locale")];

/** Today on the studio calendar (Asia/Riyadh), as `YYYY-MM-DD`. Never the browser's day. */
export const todayInStudio = () =>
  new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Riyadh" }).format(
    new Date(),
  );

/** `from` plus `days` consecutive calendar days, as `YYYY-MM-DD` strings. */
export const dateRange = (from, days) => {
  const [y, m, d] = from.split("-").map(Number);
  return Array.from({ length: days }, (_, i) =>
    new Date(Date.UTC(y, m - 1, d + i)).toISOString().slice(0, 10),
  );
};

/** Whole calendar days from studio-today to a `YYYY-MM-DD` (negative once it has passed). */
export const daysUntil = (ymd, today = todayInStudio()) => {
  const at = (s) => {
    const [y, m, d] = s.split("-").map(Number);
    return Date.UTC(y, m - 1, d);
  };
  return Math.round((at(ymd) - at(today)) / 86400000);
};

/** Weekday / day / month labels for a `YYYY-MM-DD` — a calendar date, so no timezone is involved. */
export const dateParts = (ymd, code = "en") => {
  const [y, m, d] = ymd.split("-").map(Number);
  const date = new Date(Date.UTC(y, m - 1, d));
  const locale = code === "ar" ? "ar-u-ca-gregory-nu-latn" : code;
  const part = (options) =>
    new Intl.DateTimeFormat(locale, { timeZone: "UTC", ...options }).format(
      date,
    );
  return {
    weekday: part({ weekday: "long" }),
    day: part({ day: "numeric" }),
    month: part({ month: "long" }),
  };
};

export const formatBookingDate = (ymd, code = "en") => {
  if (!ymd) return "";
  const { weekday, day, month } = dateParts(ymd, code);
  return `${month} ${day} ${weekday}`;
};

/** The API's `"13:00"` strings, joined — displayed as-is. */
export const formatSlotTime = (start, end) =>
  [start, end].filter(Boolean).join(" – ");

/** Σ quantity bounds for a catalogue workshop, scaled by the party size. */
export const catalogueBounds = (workshop, peopleCount) => {
  const people = Math.max(1, Number(peopleCount) || 1);
  const min = people * (workshop?.min_products_per_person ?? 1);
  const max = workshop?.max_products_per_person
    ? people * workshop.max_products_per_person
    : Infinity;
  return { min, max };
};

export const isCatalogueType = (type) =>
  type === "paint_your_piece" || type === "make_your_candle";

/**
 * One key for the badge, the illustration and the copy. `completed` splits by the delivery
 * choice, and a workshop with no delivery step (candle: `pickup_deadline` is never set)
 * reads as delivered the moment it completes.
 */
export const bookingState = (booking) => {
  if (!booking) return "confirmed";
  if (booking.status !== "completed") return booking.status;
  if (booking.delivery_status)
    return booking.delivery_status === "completed"
      ? "delivered"
      : booking.delivery_status;
  return booking.pickup_deadline === null ? "delivered" : "ready";
};

/**
 * The booking carries no `has_delivery`; the contract pins `pickup_deadline` to the
 * workshop's own collection window (`piece_warning_days`, 7 by default) counted from
 * completion, and `null` forever for candles.
 */
export const hasDeliveryStep = (booking) =>
  !!booking &&
  booking.status === "completed" &&
  (booking.pickup_deadline !== null || booking.delivery_method !== null);

export const isActiveBooking = (booking) =>
  ACTIVE_STATUSES.includes(booking?.status);

/** `products[i][…]` query keys for `GET /price`. ufo would stringify nested objects. */
export const productsQuery = (products = []) =>
  Object.fromEntries(
    products.flatMap((line, i) => {
      const entries = [];
      if (line.workshop_product_id)
        entries.push([
          `products[${i}][workshop_product_id]`,
          line.workshop_product_id,
        ]);
      if (line.workshop_booking_piece_id)
        entries.push([
          `products[${i}][workshop_booking_piece_id]`,
          line.workshop_booking_piece_id,
        ]);
      if (line.quantity)
        entries.push([`products[${i}][quantity]`, line.quantity]);
      return entries;
    }),
  );

/** Only the keys the API accepts — the picker also carries titles and prices for the UI. */
export const productsBody = (products = []) =>
  products.map((line) =>
    line.workshop_booking_piece_id
      ? { workshop_booking_piece_id: line.workshop_booking_piece_id }
      : {
          workshop_product_id: line.workshop_product_id,
          quantity: line.quantity,
        },
  );

export const useWorkshopBooking = (workshopId) => {
  const api = useApi();
  const id = () => toValue(workshopId);

  return {
    calendar: (params) =>
      api(`/api/workshops/${id()}/availability`, { query: params }).then(
        (res) => res?.data ?? { max_available_seats: 0, blocked_dates: [] },
      ),
    slots: (date, peopleCount) =>
      api(`/api/workshops/${id()}/availability`, {
        query: { date, people_count: peopleCount },
      }).then((res) => res?.data ?? []),
    quote: ({ products, ...params }) =>
      api(`/api/workshops/${id()}/price`, {
        query: { ...params, ...productsQuery(products) },
      }),
    create: (body) =>
      api(`/api/workshops/${id()}/bookings`, { method: "POST", body }),
  };
};

export const useBookingActions = (bookingId) => {
  const api = useApi();
  const base = () => `/api/workshops/bookings/${toValue(bookingId)}`;

  return {
    pay: () => api(`${base()}/pay`, { method: "POST" }),
    reschedule: (body) => api(base(), { method: "PUT", body }),
    cancel: () => api(base(), { method: "DELETE" }),
    /**
     * `pieces` is one entry per file: `{ file, label, key, id }`. The **key** is what says
     * which photos show the same object — two friends can both call their cup "mug" and
     * still end up with two pieces, which matching on the label text could never express.
     * `id` names a piece from an earlier upload, to add another angle to it.
     */
    uploadImages: (pieces) => {
      const form = new FormData();
      pieces.forEach(({ file, label, key, id }) => {
        form.append("images[]", file);
        form.append("piece_labels[]", label);
        form.append("piece_keys[]", key ?? "");
        form.append("piece_ids[]", id ?? "");
      });
      return api(`${base()}/images`, { method: "POST", body: form });
    },
    removeImage: (imageId) =>
      api(`${base()}/images/${imageId}`, { method: "DELETE" }),
    removePiece: (pieceId) =>
      api(`${base()}/pieces/${pieceId}`, { method: "DELETE" }),
    deliveryQuote: (params) =>
      api(`${base()}/delivery/quote`, { query: params }),
    chooseDelivery: (body) =>
      api(`${base()}/delivery`, { method: "POST", body }),
  };
};

/** `GET /api/workshops/bookings/{id}` — own bookings only; a 404 is "gone", never "forbidden". */
export const useBooking = (id) => {
  const { data, pending, error, status, refresh } = useApiFetch(
    () => `/api/workshops/bookings/${toValue(id)}`,
    {
      key: () => `booking-${toValue(id)}`,
      lazy: import.meta.client,
      transform: (res) => res?.data ?? null,
      default: () => null,
      watch: [() => toValue(id), ...localeKeys()],
    },
  );

  return {
    booking: computed(() => data.value),
    pending,
    error,
    status,
    refresh,
    /** Every action answers with the fresh `present()` — drop it in instead of refetching. */
    set: (booking) => {
      data.value = booking;
    },
  };
};

/**
 * `GET /api/workshops/bookings`, paginated. `page`, `status` and `sort` may be refs.
 *
 * The API orders newest-booked first, so the booking just paid for is at the top; `sort`
 * takes `newest`, `oldest`, `session_soonest` or `session_latest`. `status` is one status
 * or several comma-separated. `statusCounts` covers the customer's whole history whatever
 * the filter says — the numbers exist to label the tabs before one is opened.
 */
export const useBookings = ({
  page = 1,
  perPage = 10,
  status,
  sort,
  key = "bookings",
} = {}) => {
  const list = useApiList("/api/workshops/bookings", {
    key,
    query: { page, per_page: perPage, status, sort },
  });

  return {
    ...list,
    statusCounts: computed(() => list.meta.value?.status_counts ?? null),
  };
};

/** Statuses a customer's own tabs are built from, in the order they happen. */
export const BOOKING_TABS = [
  "all",
  "pending_payment",
  "confirmed",
  "attending",
  "preparing",
  "completed",
  "absent",
  "cancelled",
];

export const BOOKING_SORTS = [
  "newest",
  "oldest",
  "session_soonest",
  "session_latest",
];

/** How many bookings still need the user's attention — the hub tab badge. */
export const useActiveBookingsCount = () => {
  const { user } = useSanctumAuth();
  const isRegistered = computed(
    () => !!user.value && !(user.value?.data?.is_guest ?? user.value?.is_guest),
  );

  const { data } = useApiFetch("/api/workshops/bookings", {
    key: "bookings-active-count",
    query: { per_page: "all" },
    transform: (res) =>
      unwrapList(res?.data).items.filter(isActiveBooking).length,
    default: () => 0,
    immediate: isRegistered.value,
    watch: [isRegistered, ...localeKeys()],
  });

  return { activeCount: computed(() => data.value ?? 0), isRegistered };
};
