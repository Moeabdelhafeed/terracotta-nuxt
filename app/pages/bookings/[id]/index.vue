<template>
  <main v-if="status !== 'success' && !booking" class="mx-auto max-w-6xl px-6 py-16" aria-busy="true">
    <AppSkeleton class="h-9 w-2/3" />
    <div class="mt-8 grid gap-8 lg:grid-cols-[1.5fr_1fr]">
      <AppSkeleton class="h-48 w-full !rounded-3xl" />
      <AppSkeleton class="h-28 w-full !rounded-3xl" />
    </div>
  </main>

  <main v-else-if="booking" class="bg-background">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex items-start justify-between gap-4">
        <h1 class="font-display text-3xl font-semibold sm:text-4xl">
          {{ booking.workshop_title }}<span v-if="booking.has_celebration"> {{ t('with_celebration', 'with a celebration', 'مع احتفال') }}</span>
        </h1>
        <BookingStatusBadge :booking="booking" />
      </div>

      <!--
        A confirmed booking leads with the drawn calendar and the one instruction that
        matters — scan the code when you arrive — because at this point there is nothing
        to decide, only something to remember. Every other status keeps the panel in the
        aside, where it sits beside the thing it is describing.
      -->
      <section v-if="heroArt" class="mt-8 flex flex-col items-center text-center">
        <div class="flex w-full justify-center overflow-hidden rounded-card bg-primary/5 px-6 py-8">
          <img
            :src="heroArt"
            alt=""
            aria-hidden="true"
            class="w-full max-w-sm"
          />
        </div>
        <h2 class="mt-6 font-display text-2xl font-semibold sm:text-3xl">{{ panel.title }}</h2>
        <p class="mt-2 max-w-md text-sm text-muted-foreground">{{ panel.body }}</p>
      </section>

      <div
        class="mt-8 grid gap-8"
        :class="heroArt ? 'mx-auto w-full max-w-2xl' : 'lg:grid-cols-[1.5fr_1fr] lg:items-start'"
      >
        <div class="flex flex-col gap-6">
          <!-- Six tiles (gE058): date · people · price · code · time · celebration -->
          <!-- Photos: only while the session is running (qQmRc / QCR16). -->
          <BookingPieceUploader
            v-if="state === 'attending'"
            :booking="booking"
            @uploaded="onUploaded"
            @remove-piece="askRemovePiece"
            @remove-image="removeImage"
          />

          <!--
            Six tiles, as the app draws them: the glyph above the fact, on a wash of the
            workshop's own colour. The code is the one you act on, so it is filled rather
            than washed; the celebration is the studio's pink with its confetti, because
            it is the one tile that is not about logistics.
          -->
          <dl class="grid grid-cols-2 gap-3 sm:grid-cols-3">
            <div class="flex flex-col gap-2 rounded-2xl bg-primary/10 p-4 text-primary">
              <LucideCalendar class="size-5" />
              <dt class="sr-only">{{ t('tile_date', 'Date', 'التاريخ') }}</dt>
              <dd class="font-display text-sm font-semibold text-foreground">{{ formatBookingDate(booking.booking_date, code) }}</dd>
            </div>

            <div class="flex flex-col gap-2 rounded-2xl bg-primary/10 p-4 text-primary">
              <LucideUsers class="size-5" />
              <dt class="sr-only">{{ t('tile_people', 'People', 'الأشخاص') }}</dt>
              <dd class="font-display text-sm font-semibold text-foreground">{{ t('n_people', ':n people', ':n اشخاص', { n: booking.people_count }) }}</dd>
            </div>

            <div class="flex flex-col gap-2 rounded-2xl bg-primary/10 p-4 text-primary">
              <LucideTag class="size-5" />
              <dt class="sr-only">{{ t('tile_price', 'Price', 'السعر') }}</dt>
              <dd class="font-display text-sm font-semibold text-foreground">{{ format(booking.total_price) }}</dd>
            </div>

            <div class="flex flex-col gap-2 rounded-2xl bg-primary/10 p-4 text-primary">
              <LucideClock class="size-5" />
              <dt class="sr-only">{{ t('tile_time', 'Time', 'الوقت') }}</dt>
              <dd class="font-display text-sm font-semibold text-foreground"><bdi>{{ formatSlotTime(booking.start_time, booking.end_time, code) }}</bdi></dd>
            </div>

            <!--
              The only tile that does something, so it is the only filled one. It stays
              for the whole life of the booking — the code is also its REFERENCE, the
              digits read out at the counter when a piece is collected — and goes only on
              a cancelled booking, which has no counter conversation left.
            -->
            <div v-if="state !== 'cancelled'" class="relative overflow-hidden rounded-2xl bg-primary text-white transition-opacity hover:opacity-90">
              <dt class="sr-only">{{ t('tile_code', 'Check-in code', 'رمز المسح') }}</dt>
              <dd>
                <button type="button" class="relative flex w-full flex-col gap-2 p-4 text-start" @click="qrOpen = true">
                  <LucideQrCode class="size-5" />
                  <span class="font-display text-sm font-semibold">{{ t('tile_code', 'Check-in code', 'رمز المسح') }}</span>
                </button>
              </dd>
            </div>

            <div
              class="relative flex flex-col gap-2 overflow-hidden rounded-2xl p-4"
              :class="booking.has_celebration ? 'bg-brand-blush/15 text-brand-blush' : 'bg-primary/10 text-primary'"
            >
              <span
                v-if="booking.has_celebration"
                class="pointer-events-none absolute inset-y-0 end-0 aspect-square scale-150 bg-[url('/confetti.png')] bg-contain bg-no-repeat opacity-60"
                aria-hidden="true"
              />
              <LucideCake class="relative size-5" />
              <dt class="sr-only">{{ t('tile_celebration', 'Celebration', 'الاحتفال') }}</dt>
              <dd
                class="relative font-display text-sm font-semibold"
                :class="booking.has_celebration ? 'text-brand-blush' : 'text-foreground'"
              >
                {{ booking.has_celebration ? t('with_celebration_short', 'With a celebration', 'مع احتفال') : t('no_celebration', 'None', 'بدون') }}
              </dd>
            </div>
          </dl>

          <!--
            «قطعك» — the pictures UNDER the piece they belong to, never a flat wall of
            photographs beside a list of names. A piece IS its photographs: the label is
            the only thing that says which cup is whose, and two friends can both call
            theirs "mug", so a grid that has been cut loose from the names cannot be read.
          -->
          <section v-if="booking.pieces?.length && state !== 'attending'">
            <h2 class="font-display text-xl font-semibold">{{ t('pieces_title_detail', 'Your pieces', 'قطعك') }}</h2>
            <p class="mt-1 text-sm text-muted-foreground">
              {{ t('pieces_closed', 'The session is over, so no more photos can be added to this booking.', 'انتهت الورشة، لذا لا يمكن إضافة مزيد من الصور إلى هذا الحجز.') }}
            </p>
            <ul class="mt-4 flex flex-col gap-3">
              <li v-for="piece in booking.pieces" :key="piece.id" class="rounded-2xl border bg-card p-4" data-test="piece">
                <p class="truncate font-display font-semibold">{{ pieceLabel(piece) }}</p>
                <p class="text-xs text-muted-foreground">{{ t('n_photos', ':n photos', ':n صور', { n: piece.images?.length ?? 0 }) }}</p>

                <ul v-if="piece.images?.length" class="mt-3 flex flex-wrap gap-2">
                  <li v-for="(image, index) in piece.images" :key="image.id">
                    <button
                      type="button"
                      class="block overflow-hidden rounded-xl transition-opacity hover:opacity-80"
                      :aria-label="t('view_photo', 'View photo', 'عرض الصورة')"
                      @click="openPhotos(piece.images, index)"
                    >
                      <AppImage :src="image" :alt="pieceLabel(piece)" class="size-20 object-cover" />
                    </button>
                  </li>
                </ul>
              </li>
            </ul>
          </section>

          <!--
            Photographs the server sends with no piece behind them — bookings shot before
            the studio grouped them. Nothing names these, so they can only be shown as
            what they are.
          -->
          <section v-if="looseImages.length">
            <h2 class="font-display text-xl font-semibold">{{ t('photos_title', 'Your photos', 'صور قطعك') }}</h2>
            <ul class="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
              <li v-for="(image, index) in looseImages" :key="image.id" class="overflow-hidden rounded-2xl border">
                <button
                  type="button"
                  class="block w-full transition-opacity hover:opacity-80"
                  :aria-label="t('view_photo', 'View photo', 'عرض الصورة')"
                  @click="openPhotos(looseImages, index)"
                >
                  <AppImage :src="image" :alt="booking.workshop_title" class="aspect-square w-full object-cover" />
                </button>
              </li>
            </ul>
          </section>
        </div>

        <aside class="flex flex-col gap-4">
          <!-- Status panel: illustration, title and the copy for this exact state. The
               confirmed state says it in the hero above instead, so it is skipped here. -->
          <section v-if="!heroArt" class="flex items-start gap-4 rounded-3xl border bg-card p-6">
            <span class="flex size-12 shrink-0 items-center justify-center rounded-2xl" :class="panel.tone">
              <component :is="panel.icon" class="size-6" />
            </span>
            <div class="flex-1">
              <h2 class="font-display text-xl font-semibold">{{ panel.title }}</h2>
              <p class="mt-1 text-sm text-muted-foreground">{{ panel.body }}</p>
            </div>
            <Button
              v-if="holdNotice"
              type="button"
              size="icon"
              variant="ghost"
              class="size-9 shrink-0 rounded-control text-destructive"
              :aria-label="t('pickup_warning_title', 'Notice', 'تحذير')"
              @click="warningOpen = true"
            >
              <LucideTriangleAlert class="size-5" />
            </Button>
          </section>

          <!-- The one thing on this frame a customer can lose a piece by not reading, so
               it is on the page rather than behind the mark that reopens it. -->
          <p v-if="holdNotice" class="rounded-card bg-destructive/10 p-4 text-sm text-destructive" data-test="hold-notice">
            {{ holdNotice }}
          </p>

          <!-- A held booking still needs paying; the countdown is the server's, not ours. -->
          <CheckoutPaymentHold
            v-if="state === 'pending_payment'"
            :amount-due="booking.amount_due"
            :payment-status="booking.payment_status"
            :expires-at="booking.payment_expires_at"
            :pay="actions.pay"
            :restart-to="`/workshops/${booking.workshop_id}/book`"
            @paid="apply"
            @expired="refresh"
          />

          <!-- Piece ready (rourY / vONkg): pickup or delivery, and the paint-it-again upsell.
               Both ways stay reachable after one is picked — the other takes the place of
               the pair, worded as a switch. -->
          <div v-if="handover.length" class="flex flex-col gap-3 sm:flex-row lg:flex-col" data-test="handover">
            <Button
              v-for="option in handover"
              :key="option.method"
              as-child
              class="h-12 flex-1 rounded-xl px-8 text-base"
              :class="option.accent"
            >
              <NuxtLink :to="`/bookings/${booking.id}/delivery?method=${option.method}`" :data-test="`handover-${option.method}`">
                {{ option.label }}
              </NuxtLink>
            </Button>
          </div>

          <p v-if="switchRefund" class="rounded-card bg-success/10 p-4 text-sm text-success" data-test="handover-refund">
            {{ t('pickup_refunds_fee', 'The :amount delivery fee goes back to your Terracotta balance. Asking for delivery again later is charged at the rate on the day.', 'ستعاد رسوم التوصيل :amount إلى رصيدك في تيراكوتا. وإذا طلبت التوصيل لاحقًا فستُحتسب الرسوم من جديد بسعر اليوم.', { amount: format(booking.delivery_fee_wallet_applied) }) }}
          </p>

          <!-- A piece already on its way somewhere is not also going back to be painted. -->
          <Button v-if="paintable && !booking.delivery_method" as-child class="h-12 w-full rounded-xl bg-primary text-base hover:bg-primary/90">
            <NuxtLink :to="`/workshops/${paintable.id}/book?people=${booking.people_count}`">{{ t('paint_this_piece', 'Paint my piece', 'لوني الكوب') }}</NuxtLink>
          </Button>

          <!-- Actions -->
          <div class="flex flex-wrap gap-3">
            <Button
              v-if="booking.can_cancel"
              type="button"
              variant="outline"
              class="h-12 flex-1 rounded-xl border-destructive/40 text-destructive hover:border-destructive hover:bg-destructive hover:text-white"
              @click="cancelOpen = true"
            >{{ t('cancel_booking', 'Cancel the booking', 'الغاء موعد') }}</Button>

            <Button
              v-if="booking.can_edit"
              type="button"
              variant="outline"
              class="h-12 flex-1 rounded-xl border-warning/40 text-warning hover:border-warning hover:bg-warning hover:text-white"
              @click="openReschedule"
            >{{ t('reschedule', 'Change the time', 'تغير موعد') }}</Button>

            <!-- Only while there is still a reason to go: once the session has run, the
                 piece is what moves, not the customer. -->
            <Button v-if="booking.location_url && state === 'confirmed'" as-child variant="outline" class="h-12 flex-1 rounded-xl">
              <a :href="booking.location_url" target="_blank" rel="noopener noreferrer">{{ t('the_location', 'The location', 'الموقع') }}</a>
            </Button>
          </div>

          <p v-if="booking.editable_until" class="text-xs text-muted-foreground">
            {{ t('editable_until', 'You can change or cancel this booking until :at.', 'يمكنك تعديل الحجز أو إلغاؤه حتى :at.', { at: formatDate(booking.editable_until) }) }}
          </p>

          <p v-if="booking.delivery_fee_amount_due && !isZeroMoney(booking.delivery_fee_amount_due)" class="rounded-2xl bg-brand-mist/60 p-4 text-sm">
            {{ t('delivery_fee_owed', 'Delivery fee still owed: :amount — settle it at the studio.', 'رسوم توصيل مستحقة: :amount — تُدفع في الاستوديو.', { amount: format(booking.delivery_fee_amount_due) }) }}
          </p>
        </aside>
      </div>
    </div>

    <!--
      The photographs, full size. The run is ONE PIECE's angles, not the whole booking's:
      swiping is how a customer compares two shots of the same cup, and sliding into
      somebody else's pictures is not what the tap meant.
    -->
    <AppLightbox v-model="viewing" :items="viewingImages" :alt="booking.workshop_title" />

    <!-- QR / check-in code (rO1Zg) -->
    <BookingSheet :open="qrOpen" :title="t('tile_code', 'Check-in code', 'رمز المسح')" @close="qrOpen = false">
      <template #icon><LucideQrCode class="size-5" /></template>
      <div class="flex flex-col items-center gap-5 text-center">
        <!--
          The admin CMS scans `qr_value` back to look this booking up. The code is drawn
          in the workshop's own colour on a wash of it, with the studio's line behind —
          the app's treatment, and it makes the panel read as this workshop's pass rather
          than a generic barcode. The digits stay beneath as the manual fallback for a
          scanner that will not read.
        -->
        <div class="relative w-full overflow-hidden rounded-card bg-primary/5 p-6">
          <CardLineArt class="absolute inset-0 size-full opacity-40" />

          <!-- eslint-disable-next-line vue/no-v-html -- generated locally by uqr, not user input -->
          <div
            v-if="qrSvg"
            class="relative mx-auto w-52 text-primary [&>svg]:h-auto [&>svg]:w-full"
            role="img"
            :aria-label="t('qr_alt', 'Check-in QR code', 'رمز الاستجابة السريعة لتسجيل الحضور')"
            v-html="qrSvg"
          />

          <p
            class="relative mt-4 font-display text-3xl font-black tracking-[0.2em] tabular-nums text-primary sm:text-4xl"
            dir="ltr"
          >{{ booking.checkin_code }}</p>
        </div>

        <p class="text-sm text-muted-foreground">
          {{ t('qr_note', 'Show this code at the desk when you arrive to check in.', 'يرجى مسح رمز الاستجابة السريعة عند الوصول لتسجيل حضورك في الورشة.') }}
        </p>
      </div>
      <template #footer>
        <Button type="button" class="h-12 flex-1 rounded-xl bg-primary text-base hover:bg-primary/90" @click="qrOpen = false">{{ t('close', 'Close', 'اغلاق') }}</Button>
      </template>
    </BookingSheet>

    <!-- Collection deadline (aiejA / ZoX5e) — the booking's own `pickup_deadline`, which
         the studio sets per workshop as `piece_warning_days`. -->
    <BookingSheet :open="warningOpen" :title="t('pickup_warning_title', 'Notice', 'تحذير')" @close="warningOpen = false">
      <template #icon><LucideTriangleAlert class="size-5" /></template>
      <p class="text-sm text-muted-foreground">{{ holdNotice }}</p>
      <template #footer>
        <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" @click="warningOpen = false">{{ t('close', 'Close', 'اغلاق') }}</Button>
      </template>
    </BookingSheet>

    <!-- Reschedule (VbB9C / XRwpj / LUWVe) — only ever offered when `can_edit`. -->
    <BookingSheet :open="rescheduleOpen" wide :busy="rescheduling" :title="t('reschedule_title', 'Change the time', 'تغيير موعد')" @close="rescheduleOpen = false">
      <template #icon><LucideCalendarClock class="size-5" /></template>
      <BookingSlotPicker
        v-if="workshop"
        :workshop="workshop"
        v-model:people="reschedulePeople"
        v-model:date="rescheduleDate"
        v-model:slot-id="rescheduleSlotId"
        lock-people
        :current-slot-id="booking.workshop_slot_id ?? null"
        :current-date="booking.booking_date"
        :errors="rescheduleErrors"
      />
      <span v-if="rescheduleError" class="mt-3 block text-xs text-destructive">{{ rescheduleError }}</span>
      <template #footer>
        <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" :disabled="rescheduling" @click="rescheduleOpen = false">{{ t('close', 'Close', 'اغلاق') }}</Button>
        <Button type="button" class="h-12 flex-1 rounded-xl bg-primary hover:bg-primary/90" :disabled="rescheduling || !rescheduleSlotId" @click="doReschedule">
          {{ t('reschedule_action', 'Change', 'تغيير') }}
        </Button>
      </template>
    </BookingSheet>

    <!-- Cancel (k6bTIc / AYqlP / i5M6B) -->
    <BookingSheet :open="cancelOpen" :busy="cancelling" :title="t('cancel_title', 'Cancel the booking', 'الغاء الحجز')" @close="cancelOpen = false">
      <template #icon><LucideCalendarX class="size-5" /></template>
      <p class="text-sm text-muted-foreground">{{ t('cancel_confirm', 'Are you sure you want to cancel this booking?', 'هل أنت متأكد من رغبتك في إلغاء الحجز؟') }}</p>
      <p class="mt-3 text-sm text-muted-foreground">
        {{ booking.payment_status === 'paid'
          ? t('cancel_refund', 'The full :amount goes back to your Terracotta balance.', 'سيعاد كامل المبلغ :amount إلى رصيدك في تيراكوتا.', { amount: format(booking.total_price) })
          : t('cancel_no_refund', 'Nothing has been paid yet, so there is nothing to refund.', 'لم يتم دفع أي مبلغ بعد، لذلك لا يوجد ما يُعاد.') }}
      </p>
      <span v-if="cancelError" class="mt-3 block text-xs text-destructive">{{ cancelError }}</span>
      <template #footer>
        <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" :disabled="cancelling" @click="cancelOpen = false">{{ t('no', 'No', 'لا') }}</Button>
        <Button type="button" class="h-12 flex-1 rounded-xl bg-destructive text-white hover:bg-destructive/90" :disabled="cancelling" @click="doCancel">{{ t('yes', 'Yes', 'نعم') }}</Button>
      </template>
    </BookingSheet>

    <!-- Deleting a piece takes its photos with it. -->
    <BookingSheet
      :open="!!pieceToRemove"
      :title="t('remove_piece_title', 'Remove :label?', 'حذف :label؟', { label: pieceLabel(pieceToRemove) })"
      @close="pieceToRemove = null"
    >
      <template #icon><LucideTrash2 class="size-5" /></template>
      <p class="text-sm text-muted-foreground">
        {{ t('remove_piece_body', 'Every photo of it goes too.', 'ستُحذف كل صورها أيضاً.') }}
      </p>

      <!-- The photographs, not just the count: this cannot be undone, and two pieces can
           carry the same name — the pictures are what tell the customer which one it is. -->
      <ul v-if="pieceToRemove?.images?.length" class="mt-4 flex flex-wrap gap-2">
        <li v-for="image in pieceToRemove.images" :key="image.id">
          <AppImage :src="image" :alt="pieceLabel(pieceToRemove)" class="size-20 rounded-xl object-cover" />
        </li>
      </ul>
      <template #footer>
        <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" @click="pieceToRemove = null">{{ t('no', 'No', 'لا') }}</Button>
        <Button type="button" class="h-12 flex-1 rounded-xl bg-destructive text-white hover:bg-destructive/90" @click="doRemovePiece">{{ t('yes', 'Yes', 'نعم') }}</Button>
      </template>
    </BookingSheet>
  </main>
</template>

<script setup>
import { renderSVG } from 'uqr'
/**
 * One booking, in every state it can be in. Each action answers with the fresh presented
 * booking, which is dropped straight back into the page — no refetch, no local patching.
 */
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'booking',
})

const route = useRoute()
const { t, code } = useLang('web', 'bookings')
const { format } = usePrice()
const { formatDate } = useDateFormat()
const toast = useToast()

const { booking, status, error, refresh, set } = useBooking(() => route.params.id)

// Someone else's booking answers 404 — "gone", never "forbidden".
watchEffect(() => {
  if (status.value === 'error' || (status.value === 'success' && !booking.value)) {
    showError({ statusCode: error.value?.statusCode ?? 404, statusMessage: 'Booking not found' })
  }
})

const actions = useBookingActions(() => route.params.id)
const { refresh: refreshWallet } = useWallet()
const { refreshIdentity } = useSanctumAuth()

/**
 * A cancel and a reschedule-down both credit the wallet, and the site reads a balance from
 * two places — the ledger and the identity every other screen shows. Refetching only the
 * booking left the checkout's wallet toggle disabled over money the toast had just said
 * the customer had.
 */
const refreshMoney = () => Promise.all([refreshWallet(), refreshIdentity()])

// Only the reschedule sheet needs the FULL workshop (its type decides whether the party
// size is locked), so that is fetched when the sheet opens rather than on every render.
const workshop = ref(null)

/**
 * The booking payload carries no colour, so the catalogue answers it, matched on
 * `workshop_id` — the same lookup `BookingCard` makes, off the same cached list. A
 * booking of a retired workshop finds nothing and simply keeps the studio's own hue.
 */
const { workshops } = useWorkshops()
const workshopMatch = computed(
  () => workshops.value.find((entry) => entry.id === booking.value?.workshop_id) ?? null,
)
const tone = computed(() => (workshopMatch.value ? workshopColour(workshopMatch.value) : null))

/**
 * `--chrome` as well, for the band at the top: a custom property inherits the value it
 * already RESOLVED to on the ancestor, so `--chrome: var(--brand-terracotta)` was
 * substituted back at :root and cannot be reached by overriding the brand hue lower down.
 *
 * `:root:root`, not `:root`: on a cold load the stylesheet is served AFTER this tag, and
 * at equal specificity the last rule wins — the colour would hold on a click-in and be
 * lost on a refresh. Doubling the selector wins on specificity whatever the order.
 */
useHead(() => ({
  style: tone.value
    ? [{ innerHTML: `:root:root{--chrome:${tone.value};--primary:${tone.value}}` }]
    : [],
}))

const apply = (res) => { set(res?.data ?? res) }

const state = computed(() => bookingState(booking.value))
const family = computed(() => workshopMatch.value?.type ?? null)

/**
 * The states that lead with a drawn illustration and centred copy instead of the panel in
 * the aside: the two where the booking is settled and there is nothing left to decide —
 * it is confirmed, or it is off. Everything in between is a step in a process, and a step
 * belongs beside the thing it describes.
 */
const HERO_ART = {
  confirmed: '/booking-confirmed.png',
  attending: '/booking-attending.png',
  absent: '/booking-absent.png',
  preparing: '/booking-preparing.png',
  // One drawing for both: the app has no separate frame for a piece whose owner has
  // chosen to collect it — it is the same screen, and what changes is the copy and which
  // way out is still on offer.
  ready: '/booking-ready.png',
  awaiting_pickup: '/booking-ready.png',
  getting_ready: '/booking-packing.png',
  on_the_way: '/booking-on-the-way.png',
  cancelled: '/booking-cancelled.png',
}
/**
 * «حاضرة» is the one frame drawn per FAMILY. Every other one is about the PIECE — the
 * kiln, the van, the calendar — and is the same picture whichever workshop it belongs to;
 * this one draws the customer doing the thing they came for, and that is a potter at her
 * wheel in one workshop and a painter with her palette in another.
 *
 * A family with no drawing of its own falls back to the potter rather than to nothing.
 */
const ATTENDING_ART = {
  paint_your_piece: '/booking-attending-paint.png',
  make_your_candle: '/booking-attending-candle.png',
}
const heroArt = computed(() =>
  state.value === 'attending'
    ? (ATTENDING_ART[family.value] ?? HERO_ART.attending)
    : (HERO_ART[state.value] ?? null),
)

/**
 * Photographs that belong to no piece. The API groups every upload under one, so this is
 * empty on anything shot since — but a booking from before that has pictures and no
 * pieces, and dropping the flat grid outright would have hidden them for good.
 */
const looseImages = computed(() => {
  const grouped = new Set(
    (booking.value?.pieces ?? []).flatMap((piece) => (piece.images ?? []).map((image) => image.id)),
  )
  return (booking.value?.images ?? []).filter((image) => !grouped.has(image.id))
})

// An option with no id has no schedule to send anyone to.
const paintable = computed(() => booking.value?.paintable_at?.find((option) => option.id) ?? null)

/**
 * The ways the finished piece can still leave. Nothing chosen yet draws both; once one is
 * chosen the OTHER stays, worded as a switch — the choice is the customer's until the
 * piece is handed over, and switching back to pickup credits the delivery fee.
 */
const handover = computed(() => {
  if (!canChooseHandover(booking.value)) return []
  const pickup = {
    method: 'pickup',
    accent: 'bg-brand-green hover:bg-brand-green/90',
    label: t('choose_pickup', 'Pick it up', 'استلام'),
    switchLabel: t('switch_to_pickup', 'Collect it myself instead', 'سأستلمها بنفسي بدلًا من ذلك'),
  }
  const delivery = {
    method: 'delivery',
    accent: 'bg-primary hover:bg-primary/90',
    label: t('choose_delivery', 'Have it delivered', 'توصيل'),
    switchLabel: t('switch_to_delivery', 'Have it delivered instead', 'اطلب توصيلها بدلًا من ذلك'),
  }

  const chosen = booking.value.delivery_method
  if (!chosen) return [pickup, delivery]
  const other = chosen === 'pickup' ? delivery : pickup
  return [{ ...other, label: other.switchLabel }]
})

/** Only the wallet slice was ever taken, so only that slice can come back. */
const switchRefund = computed(
  () =>
    booking.value?.delivery_method === 'delivery' &&
    handover.value.length > 0 &&
    !!booking.value.delivery_fee_wallet_applied &&
    !isZeroMoney(booking.value.delivery_fee_wallet_applied),
)

/**
 * How long the studio will still hold the piece, from the booking's own `pickup_deadline`
 * — the per-workshop `piece_warning_days` counted from completion. Null when nothing is
 * running.
 */
const holdDaysLeft = computed(() => {
  const hours = hoursUntil(booking.value?.pickup_deadline)
  return hours === null ? null : Math.floor(hours / 24)
})

/**
 * The server goes on sending `pickup_deadline` after the piece has left, so a warning
 * gated on that field alone tells a customer the studio will stop holding a piece which
 * is already on a van. Only the two frames where it is still at the studio.
 */
const holdNotice = computed(() => {
  if (!['ready', 'awaiting_pickup'].includes(state.value)) return ''
  if (!booking.value || holdDaysLeft.value === null) return ''
  if (booking.value.is_pickup_overdue) {
    return t(
      'pickup_overdue_real',
      'The time we could hold your piece has passed. It is still with us — come by or ask for delivery and we will sort it out.',
      'انتهت المدة التي يمكننا خلالها الاحتفاظ بقطعتك. ما زالت لدينا — مر علينا أو اطلب التوصيل وسنرتب الأمر.',
    )
  }
  return holdDaysLeft.value >= 1
    ? t(
        'pickup_days_left',
        'You have :n more day(s) to collect your piece or ask for delivery — until :at. After that the studio cannot hold it.',
        'أمامك :n يوم لاستلام قطعتك أو طلب توصيلها — حتى :at. بعد ذلك لا يمكن للاستوديو الاحتفاظ بها.',
        { n: holdDaysLeft.value, at: formatDate(booking.value.pickup_deadline) },
      )
    : t(
        'pickup_last_day',
        'Today is the last day to collect your piece or ask for delivery — until :at. After that the studio cannot hold it.',
        'اليوم آخر يوم لاستلام قطعتك أو طلب توصيلها — حتى :at. بعد ذلك لا يمكن للاستوديو الاحتفاظ بها.',
        { at: formatDate(booking.value.pickup_deadline) },
      )
})

const viewingImages = ref([])
const viewing = ref(null)
const openPhotos = (images, index) => {
  viewingImages.value = images
  viewing.value = index
}

const qrOpen = ref(false)
// Rendered locally — the value never leaves the browser, and no image is fetched.
const qrSvg = computed(() => {
  const value = booking.value?.qr_value ?? booking.value?.checkin_code
  if (!value) return ''
  // `currentColor` so the modules inherit the workshop's hue from the panel, and a
  // transparent ground so the wash behind shows through instead of a white card.
  return renderSVG(String(value), {
    border: 1,
    blackColor: 'currentColor',
    whiteColor: 'transparent',
  })
})
const warningOpen = ref(false)
const cancelOpen = ref(false)
const rescheduleOpen = ref(false)
const pieceToRemove = ref(null)

/**
 * A piece with no name still has to be called something — the app falls back to «قطعة»
 * rather than printing an empty pair of quotes. Whitespace counts as blank.
 */
const pieceLabel = (piece) =>
  (piece?.label ?? '').trim() || t('piece_untitled_short', 'Piece', 'قطعة')

// How far off the session is, worded the way a person would: hours on the day itself,
// "soon" inside the last hour, days before that. Counting whole calendar days alone said
// "0 day(s) to go" for a session six hours away.
const countdownBody = () => {
  const hours = booking.value
    ? hoursUntilSession(booking.value.booking_date, booking.value.start_time)
    : null
  const days = booking.value ? daysUntil(booking.value.booking_date) : 0

  if (hours !== null && hours < 1) {
    return t('panel_confirmed_body_soon', 'Please show your code when you arrive at the studio — it starts soon.', 'يرجى مسح الرمز عند الوصول إلى موقع الورشة — تبدأ قريبًا.')
  }
  if (hours !== null && hours < 24) {
    return t('panel_confirmed_body_hours', 'Please show your code when you arrive at the studio — :n hour(s) to go.', 'يرجى مسح الرمز عند الوصول إلى موقع الورشة، والمتبقي على موعدها :n ساعة.', { n: hours })
  }
  return t('panel_confirmed_body', 'Please show your code when you arrive at the studio — :n day(s) to go.', 'يرجى مسح الرمز عند الوصول إلى موقع الورشة، والمتبقي على موعدها :n أيام.', { n: Math.max(days, 0) })
}

const panel = computed(() => {
  return {
    pending_payment: {
      icon: resolveComponent('LucideTimer'),
      tone: 'bg-warning/15 text-warning',
      title: t('panel_pending_title', 'Seat held', 'المقعد محجوز مؤقتًا'),
      body: t('panel_pending_body', 'We are holding your seat — complete the payment before the timer runs out.', 'نحتفظ لك بالمقعد — أكمل الدفع قبل انتهاء الوقت.'),
    },
    confirmed: {
      icon: resolveComponent('LucideCalendarCheck'),
      tone: 'bg-brand-green/15 text-brand-green',
      title: t('panel_confirmed_title', 'Booking confirmed', 'الحجز مؤكد'),
      body: countdownBody(),
    },
    attending: {
      icon: resolveComponent('LucideUserCheck'),
      tone: 'bg-brand-green/15 text-brand-green',
      title: t('panel_attending_title', 'Checked in', 'حاضرة'),
      body: t('panel_attending_body', 'Your attendance is recorded and the session is under way.', 'تم تسجيل حضورك بنجاح، وأنت الآن مشارك في الورشة.'),
    },
    absent: {
      icon: resolveComponent('LucideUserX'),
      tone: 'bg-muted text-muted-foreground',
      title: t('panel_absent_title', 'You did not attend', 'لم تحضر'),
      // NOT a refund. The app's own copy promises the money back, and this backend says
      // the opposite outright — `POST /scan/sessions/start` and `/finish` both state that
      // a no-show keeps the seat they booked and is never refunded, and the wallet reason
      // `booking_absent` is declared and never written. What IS true is that the booking
      // stands: the desk can still check in a late arrival, which puts it back to
      // `attending`.
      body: t('panel_absent_body_desk', 'The session started without you. If you are on your way, the desk can still check you in with your code.', 'بدأت الورشة ولم يتم تسجيل حضورك. إن كنت في طريقك، لا يزال بإمكان الاستقبال تسجيل حضورك برمزك.'),
    },
    preparing: {
      icon: resolveComponent('LucideFlame'),
      tone: 'bg-brand-terracotta/10 text-brand-terracotta',
      title: t('panel_preparing_title', 'Being prepared', 'قيد التحضير'),
      // WITH NO NUMBER IN IT. Nothing on the booking says when a piece will be fired —
      // there is no `ready_at` server-side — so a turnaround here is a commitment the
      // studio never made. «تلوين كوبك» is worded differently again: the piece already
      // exists there, so what is being arranged is the painting, not a firing.
      body: family.value === 'paint_your_piece'
        ? t('panel_preparing_body_painted', 'Your piece is being prepared; the details will be confirmed shortly.', 'جاري تجهيز القطعة وسيتم تاكيد التفاصيل قريبا.')
        : t('panel_preparing_body_plain', 'Your piece is being finished with care.', 'جاري تجهيز قطعتك بعناية.'),
    },
    ready: {
      icon: resolveComponent('LucidePackageCheck'),
      tone: 'bg-brand-blush/40 text-brand-terracotta',
      title: t('panel_ready_title', 'Your piece is ready', 'القطعة جاهزة'),
      body: t('panel_ready_body', 'Your piece is ready now — pick it up or have it delivered.', 'قطعتك جاهزة الآن للاستلام أو التوصيل.'),
    },
    awaiting_pickup: {
      icon: resolveComponent('LucideStore'),
      tone: 'bg-brand-blush/40 text-brand-terracotta',
      title: t('panel_awaiting_pickup_title', 'Ready for pickup', 'جاهزة للاستلام'),
      body: t('panel_awaiting_pickup_body', 'Your piece is waiting for you at the studio.', 'قطعتك بانتظارك في الاستوديو.'),
    },
    getting_ready: {
      icon: resolveComponent('LucidePackage'),
      tone: 'bg-brand-terracotta/10 text-brand-terracotta',
      title: t('panel_getting_ready_title', 'Being wrapped', 'قيد التغليف'),
      body: t('panel_getting_ready_body', 'Your piece is being wrapped and made ready for delivery.', 'جارٍ تغليف قطعتك وتجهيزها بعناية استعدادًا للتوصيل.'),
    },
    on_the_way: {
      icon: resolveComponent('LucideTruck'),
      tone: 'bg-brand-terracotta/10 text-brand-terracotta',
      title: t('panel_on_the_way_title', 'Out for delivery', 'خرجت للتوصيل'),
      body: t('panel_on_the_way_body', 'Your piece is on its way to you and will arrive soon.', 'قطعتك الآن في طريقها إليك وسيتم تسليمها قريبًا.'),
    },
    delivered: {
      icon: resolveComponent('LucideCheckCircle2'),
      tone: 'bg-brand-green/15 text-brand-green',
      title: t('panel_delivered_title', 'Delivered', 'مسلمة'),
      body: t('panel_delivered_body', 'The workshop is finished and the piece is yours.', 'تم الانتهاء من الورشة، وأصبحت القطعة بحوزتك الآن.'),
    },
    cancelled: {
      icon: resolveComponent('LucideCalendarX'),
      tone: 'bg-destructive/10 text-destructive',
      title: t('panel_cancelled_title', 'Cancelled', 'ملغاة'),
      body: t('panel_cancelled_body', 'This booking was cancelled. We will let you know about any updates or other dates.', 'تم إلغاء الورشة، وسيتم إبلاغك بأي تحديثات أو مواعيد بديلة.'),
    },
  }[state.value]
})

/* ---- photos ---- */
const onUploaded = (res) => {
  apply(res)
  toast.success(res?.message ?? '')
}

const removeImage = async (imageId) => {
  try {
    apply(await actions.removeImage(imageId))
  } catch (err) {
    toast.error(normalizeApiError(err).message)
  }
}

const askRemovePiece = (piece) => { pieceToRemove.value = piece }

const doRemovePiece = async () => {
  try {
    apply(await actions.removePiece(pieceToRemove.value.id))
  } catch (err) {
    toast.error(normalizeApiError(err).message)
  } finally {
    pieceToRemove.value = null
  }
}

/* ---- reschedule ---- */
const reschedulePeople = ref(1)
const rescheduleDate = ref('')
const rescheduleSlotId = ref(null)
const rescheduling = ref(false)
const rescheduleErrors = ref({})
const rescheduleError = ref('')

watch(booking, (value) => { if (value) reschedulePeople.value = value.people_count }, { immediate: true })

const openReschedule = async () => {
  // The sheet opens on the booking as it stands — same party, same day, same session — so
  // this reads as an edit of a booking rather than a second one built from nothing. The
  // picker only reaches for the first open date when it is handed no date at all.
  reschedulePeople.value = booking.value.people_count
  rescheduleDate.value = booking.value.booking_date
  rescheduleSlotId.value = booking.value.workshop_slot_id ?? null

  rescheduleOpen.value = true
  if (!workshop.value) {
    const res = await useApi()(`/api/workshops/${booking.value.workshop_id}`)
    workshop.value = res?.data ?? null
  }
}

const doReschedule = async () => {
  rescheduling.value = true
  rescheduleErrors.value = {}
  rescheduleError.value = ''
  try {
    // Day and time only — the API refuses `people_count` here. The party size, the
    // products and the price are the sale; changing those means cancelling and booking
    // again. `reschedulePeople` still feeds the picker's availability lookup.
    const res = await actions.reschedule({
      workshop_slot_id: rescheduleSlotId.value,
      booking_date: rescheduleDate.value,
    })
    apply(res)
    rescheduleOpen.value = false
    await refreshMoney()
    toast.success(res?.message ?? '')
  } catch (err) {
    const normalized = normalizeApiError(err)
    rescheduleErrors.value = normalized.errors
    if (!Object.keys(normalized.errors).length) rescheduleError.value = normalized.message
  } finally {
    rescheduling.value = false
  }
}

/* ---- cancel ---- */
const cancelling = ref(false)
const cancelError = ref('')

const doCancel = async () => {
  cancelling.value = true
  cancelError.value = ''
  try {
    // Cancel does NOT answer with `present()` — refetch instead of patching.
    const res = await actions.cancel()
    cancelOpen.value = false
    await Promise.all([refresh(), refreshMoney()])
    const balance = res?.data?.wallet_balance
    toast.success(balance
      ? t('cancel_done_wallet', 'Booking cancelled. Your balance is now :amount.', 'تم إلغاء الحجز. رصيدك الآن :amount.', { amount: format(balance) })
      : (res?.message ?? ''))
  } catch (err) {
    // `workshop_booking_not_cancellable` carries `errors: null` — read the message.
    cancelError.value = normalizeApiError(err).message
  } finally {
    cancelling.value = false
  }
}

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/bookings', label: t('bookings_title', 'My bookings', 'ورشاتي') },
  { label: booking.value?.workshop_title ?? '' },
])

useSeoMeta({ title: () => booking.value?.workshop_title ?? t('booking_title', 'Booking', 'الحجز'), robots: 'noindex' })
</script>
