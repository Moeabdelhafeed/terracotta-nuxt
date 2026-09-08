<template>
  <main v-if="status !== 'success' && !workshop" class="mx-auto max-w-4xl px-6 py-16" aria-busy="true">
    <AppSkeleton class="h-9 w-2/3" />
    <AppSkeleton class="mt-6 h-24 w-full !rounded-2xl" />
    <AppSkeleton class="mt-4 h-64 w-full !rounded-3xl" />
  </main>

  <main v-else-if="workshop">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-4xl px-6 py-16">
      <!-- Success (rDHVc / BhI1o / C75dHn) -->
      <section v-if="step === 'done'" class="relative overflow-hidden rounded-3xl border bg-card p-8 text-center sm:p-12">
        <AppConfetti />
        <span class="mx-auto flex size-16 items-center justify-center rounded-full bg-brand-green/15 text-brand-green">
          <LucideCheck class="size-8" />
        </span>
        <h1 class="mt-6 font-display text-3xl font-semibold sm:text-4xl">{{ t('booking_done_title', 'Your booking is confirmed!', 'تم تاكيد حجز الورشة !') }}</h1>
        <p class="mt-3 text-muted-foreground">
          {{ t('booking_done_body', 'You can cancel or move your booking up to :n hours before the session.', 'يمكنك إلغاء الحجز أو تغيير الموعد حتى :n ساعات قبل موعد الجلسة.', { n: workshop.cancellation_window_hours }) }}
        </p>
        <Button as-child class="mt-8 h-12 rounded-xl bg-brand-rust px-8 text-base hover:bg-brand-rust/90">
          <NuxtLink :to="`/bookings/${booking.id}`">{{ t('track_booking', 'Track my booking', 'تتبع الحجز') }}</NuxtLink>
        </Button>
      </section>

      <template v-else>
        <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ workshop.title }}</h1>

        <ol class="mt-6 flex flex-wrap gap-2 text-sm">
          <li v-for="(name, index) in stepNames" :key="name.key">
            <span
              class="rounded-xl px-3 py-1"
              :class="index === stepIndex ? 'bg-brand-rust text-white' : 'bg-brand-mist text-muted-foreground'"
            >{{ index + 1 }}. {{ name.label }}</span>
          </li>
        </ol>

        <!-- Step 1 — people, date, slot (oDD24 / uA4fJ / Kzosl) -->
        <section v-show="step === 'when'" class="mt-10">
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
            class="mt-10 h-12 w-full rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90 sm:w-auto sm:px-10"
            :disabled="!slotId"
            @click="goNext"
          >
            {{ catalogue ? t('next', 'Next', 'التالي') : t('to_payment', 'Payment', 'الدفع') }}
          </Button>
        </section>

        <!-- Step 2 — catalogue pieces (hDFHD / R2fBVR) -->
        <section v-if="catalogue" v-show="step === 'pieces'" class="mt-10">
          <BookingPiecePicker
            v-model="lines"
            :workshop="workshop"
            :people-count="people"
            :errors="allErrors"
          />

          <div class="mt-10 flex flex-wrap gap-3">
            <Button type="button" variant="outline" class="h-12 rounded-xl px-8" @click="step = 'when'">{{ t('back', 'Back', 'رجوع') }}</Button>
            <Button
              type="button"
              class="h-12 rounded-xl bg-brand-rust px-10 text-base hover:bg-brand-rust/90"
              :disabled="!piecesValid"
              @click="goPay"
            >{{ t('to_payment', 'Payment', 'الدفع') }}</Button>
          </div>
        </section>

        <!-- Step 3 — pay (hbg4J / FDjK9 / MEIJN) -->
        <section v-show="step === 'pay'" class="mt-10 grid gap-8 lg:grid-cols-[1.3fr_1fr] lg:items-start">
          <div>
            <div class="rounded-3xl border bg-card p-6">
              <div class="flex items-start justify-between gap-4">
                <div>
                  <h2 class="font-display text-xl font-semibold">
                    {{ workshop.title }}<span v-if="withCelebration"> {{ t('with_celebration', 'with a celebration', 'مع احتفال') }}</span>
                  </h2>
                  <p class="mt-1 text-sm text-muted-foreground">
                    {{ t('n_people', ':n people', ':n اشخاص', { n: people }) }}
                    · {{ formatBookingDate(date, code) }}
                    · <span dir="ltr">{{ formatSlotTime(slot?.start_time, slot?.end_time) }}</span>
                  </p>
                </div>
                <p v-if="quote" class="font-display text-2xl font-black text-primary">{{ format(quote.total_price) }}</p>
              </div>

              <button
                v-if="withCelebration"
                type="button"
                class="mt-4 inline-flex items-center gap-2 rounded-md bg-brand-blush/40 px-3 py-1 text-xs font-medium text-brand-rust"
                @click="withCelebration = false"
              >
                <LucideX class="size-3.5" />{{ t('remove_celebration', 'Remove the celebration', 'ازالة الاحتفال') }}
              </button>

              <dl class="mt-6 flex flex-col gap-2 border-t pt-4 text-sm">
                <div v-if="!catalogue" class="flex items-center justify-between gap-4">
                  <dt class="text-muted-foreground">{{ t('line_workshop', ':title for :n people', ':title من :n اشخاص', { title: workshop.title, n: people }) }}</dt>
                  <dd class="font-medium">{{ format(workshop.price) }} × {{ people }}</dd>
                </div>
                <div v-for="line in lines" :key="line.workshop_product_id ?? `own-${line.workshop_booking_piece_id}`" class="flex items-center justify-between gap-4">
                  <dt class="text-muted-foreground">{{ line.title }} × {{ line.quantity }}</dt>
                  <dd class="font-medium">{{ format(line.price) }}</dd>
                </div>
                <div v-if="withCelebration" class="flex items-center justify-between gap-4">
                  <dt class="text-muted-foreground">{{ t('add_celebration', 'Add a celebration', 'اضافة احتفال') }}</dt>
                  <dd class="font-medium">{{ format(workshop.celebration_price) }}</dd>
                </div>
              </dl>
            </div>

            <Button
              v-if="hasCelebration && !withCelebration && !booking"
              type="button"
              variant="outline"
              class="mt-4 h-12 w-full rounded-xl border-brand-blush bg-brand-blush/20 text-brand-rust hover:bg-brand-blush/40"
              @click="celebrationOpen = true"
            >
              <LucideCake class="me-2 size-5" />{{ t('add_celebration', 'Add a celebration', 'اضافة احتفال') }}
            </Button>

            <p v-if="workshop.location_url" class="mt-6 text-sm text-muted-foreground">
              <a :href="workshop.location_url" target="_blank" rel="noopener noreferrer" class="inline-flex items-center gap-1.5 text-primary underline">
                <LucideMapPin class="size-4" />{{ t('the_location', 'The location', 'الموقع') }}
              </a>
            </p>
          </div>

          <aside class="flex flex-col gap-4">
            <CheckoutDiscountCodeInput v-if="!booking" v-model="discountCode" :errors="allErrors" :disabled="creating" />
            <CheckoutWalletToggle v-if="!booking" v-model="useWallet" :disabled="creating" />

            <CheckoutSummary :quote="quote ?? booking" :title="t('summary_title', 'Summary', 'الملخص')" />

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
              <Button type="button" variant="outline" class="h-12 rounded-xl" @click="step = catalogue ? 'pieces' : 'when'">{{ t('back', 'Back', 'رجوع') }}</Button>
              <Button
                type="button"
                class="h-12 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
                :disabled="creating || !quote"
                @click="createBooking"
              >
                {{ creating ? t('booking_saving', 'Booking…', 'جارٍ الحجز...') : t('confirm_and_pay', 'Confirm the booking and pay', 'تاكيد الحجز و الدفع') }}
              </Button>
            </template>
          </aside>
        </section>
      </template>
    </div>

    <!-- Celebration add-on (K7pta / h1Mfn / adW7i) -->
    <BookingSheet :open="celebrationOpen" :title="t('celebration_title', 'Celebrate with Terracotta', 'احتفل مع تيراكوتا')" @close="celebrationOpen = false">
      <template #icon><LucideCake class="size-5" /></template>
      <p class="text-sm text-muted-foreground">
        {{ t('celebration_body_1', 'Add a small party to your session: a cake, decorations and a corner set up for the occasion.', 'أضف احتفالًا صغيرًا إلى جلستك: كيكة وزينة وركن مجهّز للمناسبة.') }}
      </p>
      <p class="mt-3 text-sm text-muted-foreground">
        {{ t('celebration_body_2', 'Tell us the occasion when you arrive and the team will take care of the rest.', 'أخبرنا بالمناسبة عند وصولك وسيتكفّل الفريق بالباقي.') }}
      </p>
      <template #footer>
        <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" @click="celebrationOpen = false">{{ t('close', 'Close', 'اغلاق') }}</Button>
        <Button type="button" class="h-12 flex-1 rounded-xl bg-brand-rust hover:bg-brand-rust/90" @click="addCelebration">
          {{ t('add_amount', 'Add :price', 'اضافة :price', { price: format(workshop?.celebration_price) }) }}
        </Button>
      </template>
    </BookingSheet>
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
  middleware: ['auth-mode', 'require-registered'],
  name: 'workshop-book',
})

const route = useRoute()
const router = useRouter()
const { workshop, error, status } = useWorkshop(() => route.params.id)

watchEffect(() => {
  if (status.value === 'error' || (status.value === 'success' && !workshop.value)) {
    showError({ statusCode: error.value?.statusCode ?? 404, statusMessage: 'Workshop not found' })
  }
})

const { t, code } = useLang('web', 'bookings')
const { format } = usePrice()
const toast = useToast()
const bookingApi = useWorkshopBooking(() => route.params.id)

const step = ref('when')
const people = ref(1)
const date = ref('')
const slotId = ref(null)
const slot = ref(null)
const lines = ref([])
const withCelebration = ref(false)
const discountCode = ref('')
const useWallet = ref(false)
const celebrationOpen = ref(false)
const picker = ref(null)

const quote = ref(null)
const quoteErrors = ref({})
const quoteMessage = ref('')
const booking = ref(null)
const creating = ref(false)
const createErrors = ref({})
const createError = ref('')

const catalogue = computed(() => isCatalogueType(workshop.value?.type))
const hasCelebration = computed(() => !!workshop.value && !isZeroMoney(workshop.value.celebration_price))
const allErrors = computed(() => ({ ...quoteErrors.value, ...createErrors.value }))

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/workshops', label: t('nav_workshops', 'Workshops', 'الورشات', { subGroup: 'general' }) },
  { to: `/workshops/${route.params.id}`, label: workshop.value?.title ?? '' },
  { label: t('book_now', 'Book', 'احجز') },
])

const stepNames = computed(() => [
  { key: 'when', label: t('step_when', 'Date and time', 'الموعد') },
  ...(catalogue.value ? [{ key: 'pieces', label: t('step_pieces', 'Pieces', 'القطع') }] : []),
  { key: 'pay', label: t('step_pay', 'Payment', 'الدفع') },
])
const stepIndex = computed(() => stepNames.value.findIndex((entry) => entry.key === step.value))

const totalPieces = computed(() => lines.value.reduce((sum, line) => sum + line.quantity, 0))
const piecesValid = computed(() => {
  const { min, max } = catalogueBounds(workshop.value, people.value)
  return totalPieces.value >= min && totalPieces.value <= max
})

const goNext = () => { step.value = catalogue.value ? 'pieces' : 'pay' }
const goPay = () => { step.value = 'pay' }

const addCelebration = () => {
  withCelebration.value = true
  celebrationOpen.value = false
}

const loadQuote = async () => {
  if (!slotId.value || !date.value) return
  quoteErrors.value = {}
  quoteMessage.value = ''
  try {
    const res = await bookingApi.quote({
      workshop_slot_id: slotId.value,
      booking_date: date.value,
      people_count: people.value,
      with_celebration: withCelebration.value ? 1 : 0,
      use_wallet: useWallet.value ? 1 : 0,
      discount_code: discountCode.value || undefined,
      products: catalogue.value ? lines.value : [],
    })
    quote.value = res?.data ?? null
  } catch (err) {
    const normalized = normalizeApiError(err)
    quoteErrors.value = normalized.errors
    quoteMessage.value = Object.keys(normalized.errors).length ? '' : normalized.message
    quote.value = null
  }
}

// The price endpoint writes nothing, but it shares the 60/min throttle with everything
// else on the page — a stepper can blow that in seconds.
let quoteTimer = null
const scheduleQuote = () => {
  if (booking.value) return // the hold owns the money now
  clearTimeout(quoteTimer)
  quoteTimer = setTimeout(loadQuote, 350)
}
watch([slotId, date, people, withCelebration, useWallet, discountCode, lines, step], scheduleQuote, { deep: true })
onBeforeUnmount(() => clearTimeout(quoteTimer))

const createBooking = async () => {
  creating.value = true
  createErrors.value = {}
  createError.value = ''
  try {
    const res = await bookingApi.create({
      workshop_slot_id: slotId.value,
      booking_date: date.value,
      people_count: people.value,
      with_celebration: withCelebration.value,
      use_wallet: useWallet.value,
      discount_code: discountCode.value || undefined,
      ...(catalogue.value ? { products: productsBody(lines.value) } : {}),
    })
    booking.value = res?.data ?? null
    // Wallet or a full discount covered it: the server already marked it paid.
    if (booking.value && isZeroMoney(booking.value.amount_due)) step.value = 'done'
  } catch (err) {
    const normalized = normalizeApiError(err)
    createErrors.value = normalized.errors
    createError.value = Object.keys(normalized.errors).length ? '' : normalized.message

    // Capacity is taken under a row lock at submit: the day has changed under us, so the
    // real slots go back on screen rather than a toast.
    const stale = ['people_count', 'workshop_slot_id', 'booking_date'].some((key) => normalized.errors[key])
    if (stale) {
      step.value = 'when'
      await nextTick()
      await picker.value?.refreshCalendar()
      await picker.value?.refreshSlots()
    }
  } finally {
    creating.value = false
  }
}

const payBooking = () => useApi()(`/api/workshops/bookings/${booking.value.id}/pay`, { method: 'POST' })

const onPaid = (res) => {
  booking.value = res?.data ?? booking.value
  step.value = 'done'
}

const onExpired = async () => {
  booking.value = null
  quote.value = null
  step.value = 'when'
  toast.error(t('hold_lapsed', 'The payment window closed and the seat was released. Please pick a time again.', 'انتهت مهلة الدفع وتم تحرير المقعد. يرجى اختيار الموعد من جديد.'))
  await nextTick()
  await picker.value?.refreshCalendar()
  await picker.value?.refreshSlots()
}

// Own pieces are claimed at booking, so the workshop detail behind us is stale.
watch(() => step.value === 'done', (done) => { if (done) refreshNuxtData(`workshop-${route.params.id}`) })

useSeoMeta({ title: () => t('workshop_book_title', 'Book this workshop', 'احجز هذه الورشة'), robots: 'noindex' })
</script>
