<template>
  <main
    v-if="status !== 'success' && !workshop"
    class="mx-auto max-w-6xl px-6 py-16"
    aria-busy="true"
  >
    <AppSkeleton class="h-9 w-2/3" />
    <AppSkeleton class="mt-6 h-24 w-full !rounded-2xl" />
    <AppSkeleton class="mt-4 h-64 w-full !rounded-3xl" />
  </main>

  <main v-else-if="workshop">
    <PageBar :crumbs="crumbs" :back="`/workshops/${route.params.id}`" />

    <div
      class="mx-auto max-w-6xl px-6 py-16"
      :style="{ '--primary': workshopColour(workshop) }"
    >
      <!-- Success (rDHVc / BhI1o / C75dHn) -->
      <section
        v-if="step === 'done'"
        class="relative mx-auto max-w-xl overflow-hidden rounded-3xl border bg-card p-8 text-center sm:p-12"
      >
        <AppConfetti />
        <span
          class="mx-auto flex size-16 items-center justify-center rounded-full bg-brand-green/15 text-brand-green"
        >
          <LucideCheck class="size-8" />
        </span>
        <h1 class="mt-6 font-display text-3xl font-semibold sm:text-4xl">
          {{
            t(
              "booking_done_title",
              "Your booking is confirmed!",
              "تم تاكيد حجز الورشة !",
            )
          }}
        </h1>
        <!-- A zero window is a real setting: the studio is saying there is no cut-off
             beyond the session itself. "up to 0 hours before" reads as nonsense. -->
        <p class="mt-3 text-muted-foreground">
          {{
            workshop.cancellation_window_hours
              ? t(
                  "booking_done_body",
                  "You can cancel or move your booking up to :n hours before the session.",
                  "يمكنك إلغاء الحجز أو تغيير الموعد حتى :n ساعات قبل موعد الجلسة.",
                  { n: workshop.cancellation_window_hours },
                )
              : t(
                  "booking_done_body_no_window",
                  "You can cancel or move your booking any time before the session starts.",
                  "يمكنك إلغاء الحجز أو تغيير الموعد في أي وقت قبل بدء الجلسة.",
                )
          }}
        </p>
        <Button
          as-child
          class="mt-8 h-12 rounded-xl bg-primary px-8 text-base hover:bg-primary/90"
        >
          <NuxtLink :to="`/bookings/${booking.id}`">{{
            t("track_booking", "Track my booking", "تتبع الحجز")
          }}</NuxtLink>
        </Button>
      </section>

      <template v-else>
        <h1 class="font-display text-3xl font-semibold sm:text-4xl">
          {{ workshop.title }}
        </h1>


        <!-- Step 1 — people, date, slot (oDD24 / uA4fJ / Kzosl) -->
        <section v-show="step === 'when'" data-step="when" class="mt-10">
          <BookingSlotPicker
            ref="picker"
            :workshop="workshop"
            v-model:people="people"
            v-model:date="date"
            v-model:slot-id="slotId"
            v-model:slot="slot"
            :errors="allErrors"
          />

          <Button
            type="button"
            class="mt-10 h-14 w-full justify-between rounded-2xl bg-primary px-6 text-base hover:bg-primary/90"
            :disabled="!slotId"
            @click="goNext"
          >
            <span class="size-5" />
            {{
              catalogue
                ? t("next", "Next", "التالي")
                : t("to_payment", "Payment", "الدفع")
            }}
            <LucideArrowRight class="size-5 rtl:-scale-x-100" />
          </Button>
        </section>

        <!-- Step 2 — catalogue pieces (hDFHD / R2fBVR) -->
        <section v-if="catalogue" v-show="step === 'pieces'" data-step="pieces" class="mt-10">
          <BookingPiecePicker
            v-model="lines"
            :workshop="workshop"
            :people-count="people"
            :errors="allErrors"
          />

          <div class="mt-10 flex flex-wrap gap-3">
            <Button
              type="button"
              variant="outline"
              class="h-12 rounded-xl px-8"
              @click="step = 'when'"
              >{{ t("back", "Back", "رجوع") }}</Button
            >
            <Button
              type="button"
              class="h-12 rounded-xl bg-primary px-10 text-base hover:bg-primary/90"
              :disabled="!piecesValid"
              @click="goPay"
              >{{ t("to_payment", "Payment", "الدفع") }}</Button
            >
          </div>
        </section>

        <!-- Step 3 — pay (hbg4J / FDjK9 / MEIJN) -->
        <!-- Step 3 — pay (hbg4J / FDjK9 / MEIJN). One column, in the app's order:
             what is being bought, what it costs, what it adds up to, then the buttons. -->
        <section
          data-step="pay"
          v-show="step === 'pay'"
          class="mt-10 flex flex-col gap-4"
        >
          <!-- The celebration rides ABOVE the card it was added to, so taking it off is
               where it was put on. -->
          <button
            v-if="withCelebration && !booking"
            type="button"
            class="relative -mb-10 flex h-20 items-start justify-center overflow-hidden rounded-2xl bg-brand-blush text-sm font-semibold text-white transition-colors hover:bg-brand-blush"
            @click="withCelebration = false"
          >
            <!--
              `-mb-8` tucks the bottom 32px of this button behind the card below it, so
              only the top 48px is ever seen. Both the confetti and the label are sized to
              that visible strip (`h-12`) rather than to the button — centring on the full
              80px put the words low and looked like a mistake.
            -->
            <span
              class="pointer-events-none absolute start-0 top-0 aspect-square h-12 bg-[url('/confetti.png')] bg-contain bg-no-repeat scale-200"
              aria-hidden="true"
            />
            <span
              class="pointer-events-none absolute end-0 top-0 aspect-square h-12 bg-[url('/confetti.png')] bg-contain bg-no-repeat scale-200"
              aria-hidden="true"
            />
            <span class="relative flex h-12 mt-1 items-center">
              {{ t("remove_celebration", "Remove the celebration", "ازالة الاحتفال") }}
            </span>
          </button>

          <!-- The workshop card, exactly as the listing draws it: coloured band, art in
               its own well at the end. One card for one workshop, everywhere it appears. -->
          <div
            class="relative z-10 flex min-h-[110px] overflow-hidden rounded-control p-1"
            :style="{ backgroundColor: workshopColour(workshop) }"
          >
            <div class="flex min-w-0 flex-1 flex-col gap-1 pb-4 pe-2 ps-4 pt-4 text-white">
              <h3 class="font-display text-xl font-semibold leading-snug">{{ workshop.title }}</h3>

              <p class="text-xs leading-relaxed text-white/85">
                {{ t("n_people", ":n people", ":n اشخاص", { n: people }) }} ·
                {{ formatBookingDate(date, code) }} ·
                {{ t("slot_from_to", "Session :from to :to", "ورشة من :from الى :to", {
                  from: formatClock(slot?.start_time, code),
                  to: formatClock(slot?.end_time, code),
                }) }}
              </p>

              <p v-if="quote" class="mt-auto pt-2 font-display text-xl font-bold">
                {{ format(quote.total_price) }}
              </p>
            </div>

            <div class="w-[101px] shrink-0 self-stretch overflow-hidden rounded-[6px]">
              <AppImage
                v-if="workshop.image?.image_api"
                :src="workshop.image"
                :alt="workshop.title"
                class="size-full object-cover"
              />
              <div v-else class="size-full bg-white/45">
                <img
                  v-if="art"
                  :src="art"
                  alt=""
                  class="size-full object-cover opacity-90 [filter:brightness(0)_invert(1)]"
                />
              </div>
            </div>
          </div>

          <!-- What the price is made of. The celebration is priced in the studio's coral,
               the one colour that is not the workshop's. -->
          <dl class="flex flex-col gap-3 rounded-2xl border bg-card p-5 text-sm">
            <div v-if="!catalogue" class="flex items-center justify-between gap-4">
              <dt>
                {{ t("line_workshop", ":title for :n people", ":title من :n اشخاص", {
                  title: workshop.title,
                  n: people,
                }) }}
              </dt>
              <dd class="font-display font-bold text-primary">{{ format(lineTotal(workshop.price, people)) }}</dd>
            </div>

            <div
              v-for="line in lines"
              :key="line.workshop_product_id ?? `own-${line.workshop_booking_piece_id}`"
              class="flex items-center justify-between gap-4"
            >
              <dt>{{ line.title }} × {{ line.quantity }}</dt>
              <dd class="font-display font-bold text-primary">{{ format(lineTotal(line.price, line.quantity)) }}</dd>
            </div>

            <div v-if="withCelebration" class="flex items-center justify-between gap-4">
              <dt>{{ t("add_celebration", "Add a celebration", "اضافة احتفال") }}</dt>
              <dd class="font-display font-bold text-brand-blush">{{ format(workshop.celebration_price) }}</dd>
            </div>
          </dl>

          <!-- The session is inside its own cancellation window. Said at the till as well
               as at the slot, because this is the screen where the money goes. -->
          <p
            v-if="slot && !slotCancellable(slot)"
            class="flex items-start gap-2 text-sm text-warning"
            data-test="pay-no-cancel"
          >
            <LucideLock class="mt-0.5 size-4 shrink-0" />
            {{ t("slot_no_cancel_short", "This session starts sooner than it can be cancelled or moved.", "موعد هذه الجلسة أقرب من أن تُلغى أو يُغيَّر موعدها.") }}
          </p>

          <CheckoutWalletToggle
            v-if="!booking && isRegistered"
            v-model="payWithWallet"
            :disabled="creating"
          />

          <CheckoutSummary :quote="quote ?? booking" />

          <p v-if="collectionNote" class="flex items-start gap-2 rounded-2xl bg-brand-mist/60 p-4 text-sm text-muted-foreground">
            <LucidePackage class="mt-0.5 size-4 shrink-0" />{{ collectionNote }}
          </p>

          <p v-if="workshop.location_url" class="text-sm">
            <a
              :href="workshop.location_url"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1.5 text-primary underline"
            >
              <LucideMapPin class="size-4" />{{ t("the_location", "The location", "الموقع") }}
            </a>
          </p>

          <span v-if="quoteMessage" class="text-xs text-destructive">{{ quoteMessage }}</span>
          <span v-if="createError" class="text-xs text-destructive">{{ createError }}</span>

          <!-- The hold: `amount_due === "0.00"` never gets here, it goes straight to done. -->
          <CheckoutPaymentHold
            v-if="booking"
            :amount-due="booking.amount_due"
            :payment-status="booking.payment_status"
            :expires-at="booking.payment_expires_at"
            :pay="payBooking"
            :restart-to="`/workshops/${workshop.id}/book`"
            @paid="onPaid"
            @expired="onExpired"
          />

          <template v-else>
            <Button
              v-if="hasCelebration && !withCelebration"
              type="button"
              class="relative h-14 w-full overflow-hidden rounded-2xl bg-brand-blush text-base text-white hover:bg-brand-blush"
              @click="celebrationOpen = true"
            >
              <!-- The sheet's own confetti, a square at each end, so the button reads as
                   the door to it. Decorative, and never in the way of the tap. -->
              <span
                class="pointer-events-none absolute inset-y-0 start-0 aspect-square bg-[url('/confetti.png')] bg-contain bg-no-repeat  scale-200"
                aria-hidden="true"
              />
              <span
                class="pointer-events-none absolute inset-y-0 end-0 aspect-square bg-[url('/confetti.png')] bg-contain bg-no-repeat scale-200"
                aria-hidden="true"
              />
              <span class="relative">{{ t("add_celebration", "Add a celebration", "اضافة احتفال") }}</span>
            </Button>

            <Button
              type="button"
              class="h-14 w-full rounded-2xl bg-primary text-base hover:bg-primary/90"
              :disabled="creating || !quote"
              @click="createBooking"
            >
              {{
                creating
                  ? t("booking_saving", "Booking…", "جارٍ الحجز...")
                  : t("confirm_and_pay", "Confirm the booking and pay", "تاكيد الحجز و الدفع")
              }}
            </Button>

            <Button
              type="button"
              variant="ghost"
              class="h-12 rounded-2xl"
              @click="step = catalogue ? 'pieces' : 'when'"
            >{{ t("back", "Back", "رجوع") }}</Button>
          </template>
        </section>
      </template>
    </div>

    <!-- The session is inside its own cancellation window: said ONCE, at the step where
         the seat is actually taken, rather than as a line on every card. -->
    <Teleport to="body">
      <div
        v-if="noCancelOpen"
        class="fixed inset-0 z-[70] flex items-center justify-center p-6"
        role="dialog"
        aria-modal="true"
      >
        <div class="fixed inset-0 bg-black/50" @click="noCancelOpen = false" />

        <div class="relative w-full max-w-md rounded-sheet bg-background p-6 shadow-2xl">
          <div class="flex items-start justify-between gap-4">
            <h2 class="font-display text-lg font-bold">
              {{ t("slot_no_cancel_title", "This session cannot be cancelled", "لا يمكن إلغاء هذه الجلسة") }}
            </h2>
            <button
              type="button"
              class="flex size-9 shrink-0 items-center justify-center rounded-xl bg-brand-mist text-primary transition-colors hover:text-foreground"
              :aria-label="t('close', 'Close', 'إغلاق')"
              @click="noCancelOpen = false"
            >
              <LucideX class="size-4" />
            </button>
          </div>

          <p class="mt-3 text-sm leading-relaxed text-muted-foreground">
            {{
              t(
                "slot_no_cancel_body",
                "It starts sooner than the cancellation window allows. You can still book it, but you will not be able to cancel it or move it afterwards.",
                "موعدها أقرب من مدة الإلغاء المسموحة. يمكنك الحجز، لكن لن تتمكن من الإلغاء أو تغيير الموعد بعدها.",
              )
            }}
          </p>

          <div class="mt-6 grid grid-cols-2 gap-3">
            <Button
              class="h-12 rounded-xl bg-primary text-base hover:bg-primary/90"
              @click="confirmNoCancel"
            >
              {{ t("slot_no_cancel_confirm", "Book anyway", "احجز على أي حال") }}
            </Button>
            <Button variant="outline" class="h-12 rounded-xl text-base" @click="noCancelOpen = false">
              {{ t("cancel", "Cancel", "إلغاء") }}
            </Button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Celebration add-on (K7pta / h1Mfn / adW7i) -->
    <BookingCelebrationSheet
      :open="celebrationOpen"
      :title="t('celebration_title', 'Celebrate with Terracotta', 'احتفل مع تيراكوتا')"
      :confirm-label="
        t('add_amount', 'Add :price', 'اضافة :price', {
          price: format(workshop?.celebration_price),
        })
      "
      @close="celebrationOpen = false"
      @confirm="addCelebration"
    >
      <p>
        {{
          t(
            'celebration_body_1',
            'Add a small party to your session: a cake, decorations and a corner set up for the occasion.',
            'أضف احتفالًا صغيرًا إلى جلستك: كيكة وزينة وركن مجهّز للمناسبة.',
          )
        }}
      </p>
      <p>
        {{
          t(
            'celebration_body_2',
            'Tell us the occasion when you arrive and the team will take care of the rest.',
            'أخبرنا بالمناسبة عند وصولك وسيتكفّل الفريق بالباقي.',
          )
        }}
      </p>
    </BookingCelebrationSheet>
  </main>
</template>

<script setup>
/**
 * quote → create (hold) → pay, the workshop half of the two-phase checkout.
 *
 * The quote is the only source of money: every change re-asks the server, and the create
 * call repeats the same `use_wallet` / `discount_code` so the totals match. A create that
 * comes back with `amount_due` at zero is already paid — it skips the hold entirely.
 */
definePageMeta({
  // Not `require-registered`: a guest walks the whole stepper and is asked for an account
  // at the pay button, where the account is what is actually missing.
  middleware: ["auth-mode"],
  name: "workshop-book",
});

const route = useRoute();
const router = useRouter();
const { workshop, error, status } = useWorkshop(() => route.params.id);

watchEffect(() => {
  if (
    status.value === "error" ||
    (status.value === "success" && !workshop.value)
  ) {
    showError({
      statusCode: error.value?.statusCode ?? 404,
      statusMessage: "Workshop not found",
    });
  }
});

const { t, code } = useLang("web", "bookings");

/**
 * The page bar, footer and scrollbar belong to the layout — `--chrome` is what they read.
 *
 * `:root:root`, not `:root`: on a cold load the stylesheet is served AFTER this tag, and
 * at equal specificity the last rule wins — so the colour held on a click-in and was lost
 * on a refresh. Doubling the selector wins on specificity, whatever the order.
 */
useHead(() => ({
  style: workshop.value
    ? [{ innerHTML: `:root:root{--chrome:${workshopColour(workshop.value)}}` }]
    : [],
}));
const { isRegistered } = useIsRegistered();
const { artFor } = useWorkshopArt();
const art = computed(() => (workshop.value ? artFor(workshop.value) : null));
const { format } = usePrice();

// The breakdown has to add up to the total the server charges: printing a unit price
// beside a "x 3" label showed 35 SAR over a total of 105.
const lineTotal = (price, quantity) => fromHalalas(toHalalas(price) * (quantity ?? 1));
const toast = useToast();
const bookingApi = useWorkshopBooking(() => route.params.id);

const step = ref("when");
// The people who made the pieces are the people coming back to paint them, so a booking
// that sends its party size here opens on it rather than asking again. The picker's own
// `max_available_seats` still narrows it.
const people = ref(Math.max(1, Number(route.query.people) || 1));
const date = ref("");
const slotId = ref(null);
const slot = ref(null);
const lines = ref([]);
const withCelebration = ref(false);
const payWithWallet = ref(false);
const celebrationOpen = ref(false);
const picker = ref(null);

const quote = ref(null);
const quoteErrors = ref({});
const quoteMessage = ref("");
const booking = ref(null);
const creating = ref(false);
const createErrors = ref({});
const createError = ref("");

const catalogue = computed(() => isCatalogueType(workshop.value?.type));

/**
 * Arriving from «قطعي» with a piece already named (`?piece=2`): the reader chose that cup
 * and the workshop to paint it at, so the picker two steps on opens holding it rather
 * than making them find it again among the catalogue. Only ever a piece this workshop's
 * own `own_pieces` actually offers — anything else is silently ignored.
 */
watch(
  () => workshop.value,
  (loaded) => {
    const wanted = Number(route.query.piece)
    if (!loaded || !wanted || lines.value.length) return

    const block = loaded.own_pieces
    const piece = asList(block?.pieces).find((candidate) => candidate.id === wanted)
    if (!piece) return

    lines.value = [{
      workshop_booking_piece_id: piece.id,
      quantity: 1,
      title: piece.label ?? t("your_piece", "Your piece", "قطعتك"),
      subtitle: null,
      price: block?.price ?? "0.00",
    }];
  },
  { immediate: true },
);

// `has_delivery` is the API's "this workshop leaves a piece behind" flag — false only for
// make_your_candle, which the customer carries home the same evening and never collects.
const collectionNote = computed(() =>
  workshop.value?.has_delivery
    ? t(
        "pickup_window_note",
        "You'll have :n days to collect your piece once it's ready.",
        "أمامك :n يوم لاستلام قطعتك بعد أن تصبح جاهزة.",
        { n: workshop.value.piece_warning_days ?? 7 },
      )
    : "",
);
const hasCelebration = computed(
  () => !!workshop.value && !isZeroMoney(workshop.value.celebration_price),
);
const allErrors = computed(() => ({
  ...quoteErrors.value,
  ...createErrors.value,
}));

const crumbs = computed(() => [
  {
    to: "/",
    label: t("nav_home", "Home", "الرئيسية", { subGroup: "general" }),
  },
  {
    to: "/workshops",
    label: t("nav_workshops", "Workshops", "الورشات", { subGroup: "general" }),
  },
  { to: `/workshops/${route.params.id}`, label: workshop.value?.title ?? "" },
  { label: t("book_now", "Book", "احجز") },
]);

const stepNames = computed(() => [
  { key: "when", label: t("step_when", "Date and time", "الموعد") },
  ...(catalogue.value
    ? [{ key: "pieces", label: t("step_pieces", "Pieces", "القطع") }]
    : []),
  { key: "pay", label: t("step_pay", "Payment", "الدفع") },
]);
const stepIndex = computed(() =>
  stepNames.value.findIndex((entry) => entry.key === step.value),
);

const totalPieces = computed(() =>
  lines.value.reduce((sum, line) => sum + line.quantity, 0),
);
const piecesValid = computed(() => {
  const { min, max } = catalogueBounds(workshop.value, people.value);
  return totalPieces.value >= min && totalPieces.value <= max;
});

const noCancelOpen = ref(false);
useModalScrollLock(noCancelOpen);

/** Straight past the slot step, the customer having said yes or the slot being cancellable. */
const advance = () => {
  step.value = catalogue.value ? "pieces" : "pay";
};
/**
 * `is_non_cancellable` is the server's verdict at the moment the slots were fetched.
 * `cancel_until` is the deadline itself, so a picker left open across that instant would
 * otherwise go on promising a cancellation the customer can no longer make.
 */
const slotCancellable = (s) =>
  !!s && !s.is_non_cancellable && (!s.cancel_until || new Date(s.cancel_until) > new Date());

const goNext = () => {
  // Asked once, here — the seat is taken from this step on.
  if (slot.value && !slotCancellable(slot.value)) {
    noCancelOpen.value = true;
    return;
  }
  advance();
};

const confirmNoCancel = () => {
  noCancelOpen.value = false;
  advance();
};

const goPay = () => {
  step.value = "pay";
};

const addCelebration = () => {
  withCelebration.value = true;
  celebrationOpen.value = false;
};

const loadQuote = async () => {
  if (!slotId.value || !date.value) return;
  quoteErrors.value = {};
  quoteMessage.value = "";
  try {
    const res = await bookingApi.quote({
      workshop_slot_id: slotId.value,
      booking_date: date.value,
      people_count: people.value,
      with_celebration: withCelebration.value ? 1 : 0,
      use_wallet: payWithWallet.value ? 1 : 0,
      products: catalogue.value ? lines.value : [],
    });
    quote.value = res?.data ?? null;
  } catch (err) {
    const normalized = normalizeApiError(err);
    quoteErrors.value = normalized.errors;
    quoteMessage.value = Object.keys(normalized.errors).length
      ? ""
      : normalized.message;
    quote.value = null;
  }
};

/**
 * The stepper, kept across a sign-in.
 *
 * A guest walks the whole thing and is only stopped at the pay button, which is the first
 * step that needs an account — and signing in means leaving this page. Coming back
 * remounted it: party size, day, session and chosen pieces all gone, and the reader was
 * put back at "pick a date" having already picked one. The redirect was never the
 * problem; the choices were.
 *
 * `sessionStorage`, so it dies with the tab and never outlives the visit, and keyed per
 * workshop so two open tabs do not overwrite each other. It is only ever read back on the
 * return from that sign-in (`?resume=1`); without the marker the page is a fresh booking. The server object (`booking`) is
 * deliberately NOT kept: a held seat is the server's to describe, and a stale copy of one
 * would offer to pay for something that may have expired.
 */
const DRAFT_KEY = `terracotta:booking-draft:${route.params.id}`;

const readDraft = () => {
  try {
    return JSON.parse(sessionStorage.getItem(DRAFT_KEY) || "null");
  } catch {
    // Private browsing, or storage disabled. A lost draft is not worth a broken page.
    return null;
  }
};

const writeDraft = (value) => {
  try {
    if (value) sessionStorage.setItem(DRAFT_KEY, JSON.stringify(value));
    else sessionStorage.removeItem(DRAFT_KEY);
  } catch {
    /* as above */
  }
};

onMounted(() => {
  // The draft is for one thing only: the sign-in round trip, which comes back here with
  // `?resume=1` on it. A plain visit is a new booking, so an abandoned draft from earlier
  // in the tab is dropped rather than dumping the reader back on the pay step.
  if (!route.query.resume) return writeDraft(null);

  const saved = readDraft();
  if (!saved) return;

  people.value = saved.people ?? people.value;
  date.value = saved.date ?? date.value;
  slotId.value = saved.slotId ?? slotId.value;
  withCelebration.value = !!saved.withCelebration;
  payWithWallet.value = !!saved.payWithWallet;
  lines.value = saved.lines ?? [];
  step.value = saved.step ?? step.value;
});

watch(
  [step, people, date, slotId, withCelebration, payWithWallet, lines],
  () => {
    // Booked: there is nothing left to come back to, and a draft left behind would reopen
    // the stepper over a seat the customer already holds.
    if (step.value === "done") return writeDraft(null);

    writeDraft({
      step: step.value,
      people: people.value,
      date: date.value,
      slotId: slotId.value,
      withCelebration: withCelebration.value,
      payWithWallet: payWithWallet.value,
      lines: lines.value,
    });
  },
  { deep: true },
);

// The price endpoint writes nothing, but it shares the 60/min throttle with everything
// else on the page — a stepper can blow that in seconds.
let quoteTimer = null;
const scheduleQuote = () => {
  if (booking.value) return; // the hold owns the money now
  clearTimeout(quoteTimer);
  quoteTimer = setTimeout(loadQuote, 350);
};
watch(
  [slotId, date, people, withCelebration, payWithWallet, lines, step],
  scheduleQuote,
  { deep: true },
);
onBeforeUnmount(() => clearTimeout(quoteTimer));

const createBooking = async () => {
  // The seat is held against an ACCOUNT, so this is the first step a guest cannot take.
  // Asked here, the answer comes back to this page with the stepper still on screen.
  if (!isRegistered.value)
    return useLoginPrompt().ask(
      router.resolve({ query: { ...route.query, resume: 1 } }).fullPath,
    );

  creating.value = true;
  createErrors.value = {};
  createError.value = "";
  try {
    const res = await bookingApi.create({
      workshop_slot_id: slotId.value,
      booking_date: date.value,
      people_count: people.value,
      with_celebration: withCelebration.value,
      use_wallet: payWithWallet.value,
      ...(catalogue.value ? { products: productsBody(lines.value) } : {}),
    });
    booking.value = res?.data ?? null;
    // Wallet or a full discount covered it: the server already marked it paid.
    if (booking.value && isZeroMoney(booking.value.amount_due))
      step.value = "done";
  } catch (err) {
    const normalized = normalizeApiError(err);
    createErrors.value = normalized.errors;
    createError.value = Object.keys(normalized.errors).length
      ? ""
      : normalized.message;

    // Capacity is taken under a row lock at submit: the day has changed under us, so the
    // real slots go back on screen rather than a toast.
    const stale = ["people_count", "workshop_slot_id", "booking_date"].some(
      (key) => normalized.errors[key],
    );
    if (stale) {
      step.value = "when";
      await nextTick();
      await picker.value?.refreshCalendar();
      await picker.value?.refreshSlots();
    }
  } finally {
    creating.value = false;
  }
};

const payBooking = () =>
  useApi()(`/api/workshops/bookings/${booking.value.id}/pay`, {
    method: "POST",
  });

// Both surfaces of the balance go stale the moment the wallet pays for anything: the
// toggle reads it off the Sanctum identity, the wallet page off its own ledger.
const { refreshIdentity } = useSanctumAuth();
const { refresh: refreshWallet } = useWallet();

const onPaid = (res) => {
  booking.value = res?.data ?? booking.value;
  step.value = "done";
};

const onExpired = async () => {
  booking.value = null;
  quote.value = null;
  step.value = "when";
  toast.error(
    t(
      "hold_lapsed",
      "The payment window closed and the seat was released. Please pick a time again.",
      "انتهت مهلة الدفع وتم تحرير المقعد. يرجى اختيار الموعد من جديد.",
    ),
  );
  await nextTick();
  await picker.value?.refreshCalendar();
  await picker.value?.refreshSlots();
};

// Landing on `done` is the one seam both paid paths cross — `/pay`, and a create the
// wallet or a full discount already settled. Own pieces are claimed at booking, so the
// workshop detail behind us is stale; so is the balance, on both surfaces that show it.
watch(
  () => step.value === "done",
  (done) => {
    if (!done) return;
    refreshNuxtData(`workshop-${route.params.id}`);
    refreshIdentity();
    refreshWallet();
  },
);

useSeoMeta({
  title: () =>
    t("workshop_book_title", "Book this workshop", "احجز هذه الورشة"),
  robots: "noindex",
});
</script>
