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

/**
 * Hours from now to a session, from its studio wall-clock date + start time. Riyadh is a
 * fixed UTC+3 with no DST, so the instant is the wall clock less three hours.
 *
 * A countdown that only counts calendar days told somebody with a session at 19:00 that
 * it was "0 day(s) to go" at lunchtime, which reads as already over rather than today.
 */
export const hoursUntilSession = (ymd, startTime) => {
  if (!ymd) return null;
  const [y, m, d] = ymd.split("-").map(Number);
  const [hh = 0, mm = 0] = String(startTime ?? "00:00").split(":").map(Number);
  const at = Date.UTC(y, m - 1, d, hh - 3, mm);
  return Number.isNaN(at) ? null : Math.floor((at - Date.now()) / 3600000);
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

/**
 * «السبت، ٣ أكتوبر» / "Saturday, October 3" — the locale's own order, not one assembled
 * by hand. Building it as `month day weekday` printed «أكتوبر 3 السبت», which is not how
 * either language says a date; the app takes the pattern from the locale
 * (`DateFormat.MMMMEEEEd`) and so does this.
 */
export const formatBookingDate = (ymd, code = "en") => {
  if (!ymd) return "";
  const [y, m, d] = ymd.split("-").map(Number);
  const locale = code === "ar" ? "ar-u-ca-gregory-nu-latn" : code;
  return new Intl.DateTimeFormat(locale, {
    weekday: "long",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  }).format(new Date(Date.UTC(y, m - 1, d)));
};

/**
 * The API's `"13:00"` wall-clock strings, read the way the studio says them: 12-hour with
 * am/pm, in Arabic «م»/«ص». Latin digits in both locales — the app prints «2:30 م», not
 * «٢:٣٠ م». Anchored on a fixed UTC date so the zone can never shift the hour.
 */
export const formatClock = (value, code = "en") => {
  if (!value) return "";
  const [hours, minutes] = String(value).split(":");
  if (hours === undefined || minutes === undefined) return "";
  return new Intl.DateTimeFormat(`${code}-u-nu-latn`, {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
    timeZone: "UTC",
  }).format(new Date(Date.UTC(2000, 0, 1, Number(hours), Number(minutes))));
};

export const formatSlotTime = (start, end, code = "en") =>
  [start, end].filter(Boolean).map((value) => formatClock(value, code)).join(" – ");

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
 * The studio stops the collection clock while a piece is booked into a painting session —
 * it is holding that piece deliberately, so `pickup_deadline` comes back null exactly as
 * it does for a candle. The two cannot be told apart from the deadline alone, and reading
 * "no deadline" as "handed over" told a customer their piece was already theirs while it
 * sat on a shelf at the studio.
 */
export const isAwaitingPainting = (booking) =>
  asList(booking?.pieces).some((piece) => piece.painting_session?.is_upcoming);

/**
 * One key for the badge, the illustration and the copy. `completed` splits by the delivery
 * choice, and a workshop with no handover step at all (a candle, which is never given a
 * pickup deadline) reads as delivered the moment it completes.
 */
export const bookingState = (booking) => {
  if (!booking) return "confirmed";
  if (booking.status !== "completed") return booking.status;
  if (booking.delivery_status)
    return booking.delivery_status === "completed"
      ? "delivered"
      : booking.delivery_status;
  if (isAwaitingPainting(booking)) return "ready";
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
  (booking.pickup_deadline !== null ||
    booking.delivery_method !== null ||
    // The deadline is suspended, not absent: the piece is still the studio's to hand over.
    isAwaitingPainting(booking));

/**
 * Whether the handover choice is still the customer's to make. The spec keeps it
 * re-choosable until `delivery_status` reaches `completed` — switching back to pickup
 * credits the delivery fee to the wallet, so a piece still at the studio or still on its
 * way has money riding on the button.
 */
export const canChooseHandover = (booking) =>
  hasDeliveryStep(booking) && booking.delivery_status !== "completed";

/** Whole hours from now to an offset-bearing timestamp, floored at zero; null without one. */
export const hoursUntil = (at) => {
  if (!at) return null;
  const ms = new Date(at).getTime() - Date.now();
  return Number.isNaN(ms) ? null : Math.max(0, Math.floor(ms / 3600000));
};

/**
 * Why this piece cannot be booked in to be painted, as a key the caller words:
 * `booked` while the painting session is still ahead, `painted` once it has run.
 * Null when the piece is free.
 */
export const pieceUnavailableReason = (piece) => {
  if (piece?.is_available_to_paint !== false) return null;
  return piece.painting_session?.is_upcoming ? "booked" : "painted";
};

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
