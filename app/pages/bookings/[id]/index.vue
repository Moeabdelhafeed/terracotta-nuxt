<template>
  <main v-if="status !== 'success' && !booking" class="mx-auto max-w-6xl px-6 py-16" aria-busy="true">
    <AppSkeleton class="h-9 w-2/3" />
    <div class="mt-8 grid gap-8 lg:grid-cols-[1.5fr_1fr]">
      <AppSkeleton class="h-48 w-full !rounded-3xl" />
      <AppSkeleton class="h-28 w-full !rounded-3xl" />
    </div>
  </main>

  <main v-else-if="booking" class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex items-start justify-between gap-4">
        <h1 class="font-display text-3xl font-semibold sm:text-4xl">
          {{ booking.workshop_title }}<span v-if="booking.has_celebration"> {{ t('with_celebration', 'with a celebration', 'مع احتفال') }}</span>
        </h1>
        <BookingStatusBadge :booking="booking" />
      </div>

      <div class="mt-8 grid gap-8 lg:grid-cols-[1.5fr_1fr] lg:items-start">
        <div class="flex flex-col gap-6">
          <!-- Six tiles (gE058): date · people · price · code · time · celebration -->
          <dl class="grid grid-cols-2 gap-3 sm:grid-cols-3">
            <div class="rounded-2xl border bg-card p-4">
              <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ t('tile_date', 'Date', 'التاريخ') }}</dt>
              <dd class="mt-1 font-display text-lg font-semibold">{{ formatBookingDate(booking.booking_date, code) }}</dd>
            </div>
            <div class="rounded-2xl border bg-card p-4">
              <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ t('tile_people', 'People', 'الأشخاص') }}</dt>
              <dd class="mt-1 font-display text-lg font-semibold">{{ t('n_people', ':n people', ':n اشخاص', { n: booking.people_count }) }}</dd>
            </div>
            <div class="rounded-2xl border bg-card p-4">
              <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ t('tile_price', 'Price', 'السعر') }}</dt>
              <dd class="mt-1 font-display text-lg font-semibold text-primary">{{ format(booking.total_price) }}</dd>
            </div>
            <button type="button" class="rounded-2xl border bg-card p-4 text-start transition-colors hover:border-brand-rust" @click="qrOpen = true">
              <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ t('tile_code', 'Check-in code', 'رمز المسح') }}</dt>
              <dd class="mt-1 font-display text-lg font-semibold tabular-nums" dir="ltr">{{ booking.checkin_code }}</dd>
            </button>
            <div class="rounded-2xl border bg-card p-4">
              <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ t('tile_time', 'Time', 'الوقت') }}</dt>
              <dd class="mt-1 font-display text-lg font-semibold" dir="ltr">{{ formatSlotTime(booking.start_time, booking.end_time) }}</dd>
            </div>
            <div class="rounded-2xl border bg-card p-4">
              <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ t('tile_celebration', 'Celebration', 'الاحتفال') }}</dt>
              <dd class="mt-1 font-display text-lg font-semibold">
                {{ booking.has_celebration ? t('with_celebration_short', 'With a celebration', 'مع احتفال') : t('no_celebration', 'None', 'بدون') }}
              </dd>
            </div>
          </dl>

          <!-- Photos: only while the session is running (qQmRc / QCR16). -->
          <BookingPieceUploader
            v-if="booking.status === 'attending'"
            :booking="booking"
            @uploaded="onUploaded"
            @remove-piece="askRemovePiece"
          />

          <section v-if="booking.images?.length">
            <h2 class="font-display text-xl font-semibold">{{ t('photos_title', 'Your photos', 'صور قطعك') }}</h2>
            <ul class="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
              <li v-for="image in booking.images" :key="image.id" class="relative overflow-hidden rounded-2xl border">
                <AppImage :src="image" :alt="booking.workshop_title" class="aspect-square w-full object-cover" />
                <Button
                  v-if="booking.status === 'attending'"
                  type="button"
                  size="icon"
                  variant="secondary"
                  class="absolute top-2 size-8 rounded-lg ltr:right-2 rtl:left-2"
                  :aria-label="t('remove', 'Remove', 'إزالة')"
                  @click="removeImage(image.id)"
                >
                  <LucideX class="size-4" />
                </Button>
              </li>
            </ul>
          </section>

          <section v-if="booking.pieces?.length && booking.status !== 'attending'">
            <h2 class="font-display text-xl font-semibold">{{ t('pieces_title_detail', 'Your pieces', 'قطعك') }}</h2>
            <p class="mt-1 text-sm text-muted-foreground">
              {{ t('pieces_closed', 'The session is over, so no more photos can be added to this booking.', 'انتهت الورشة، لذا لا يمكن إضافة مزيد من الصور إلى هذا الحجز.') }}
            </p>
            <ul class="mt-4 flex flex-col gap-3">
              <li v-for="piece in booking.pieces" :key="piece.id" class="flex items-center justify-between gap-4 rounded-2xl border bg-card p-4">
                <div class="min-w-0">
                  <p class="truncate font-medium">{{ piece.label }}</p>
                  <p class="text-xs text-muted-foreground">{{ t('n_photos', ':n photos', ':n صور', { n: piece.images?.length ?? 0 }) }}</p>
                </div>
              </li>
            </ul>
          </section>
        </div>

        <aside class="flex flex-col gap-4">
          <!-- Status panel: illustration, title and the copy for this exact state. -->
          <section class="flex items-start gap-4 rounded-3xl border bg-card p-6">
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
            v-if="booking.status === 'pending_payment'"
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
              class="h-12 flex-1 rounded-control px-8 text-base"
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
          <Button v-if="paintable && !booking.delivery_method" as-child class="h-12 w-full rounded-control bg-brand-rust text-base hover:bg-brand-rust/90">
            <NuxtLink :to="`/workshops/${paintable.id}/book?people=${booking.people_count}`">{{ t('paint_this_piece', 'Paint my piece', 'لوني الكوب') }}</NuxtLink>
          </Button>

          <!-- Actions -->
          <div class="flex flex-wrap gap-3">
            <Button
              v-if="booking.can_cancel"
              type="button"
              variant="outline"
              class="h-12 flex-1 rounded-xl border-destructive/40 text-destructive hover:bg-destructive/10"
              @click="cancelOpen = true"
            >{{ t('cancel_booking', 'Cancel the booking', 'الغاء موعد') }}</Button>

            <Button
              v-if="booking.can_edit"
              type="button"
              variant="outline"
              class="h-12 flex-1 rounded-control border-warning/40 text-warning hover:bg-warning/10"
              @click="openReschedule"
            >{{ t('reschedule', 'Change the time', 'تغير موعد') }}</Button>

            <Button v-if="booking.location_url" as-child variant="outline" class="h-12 flex-1 rounded-xl">
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

    <!-- QR / check-in code (rO1Zg) -->
    <BookingSheet :open="qrOpen" :title="t('tile_code', 'Check-in code', 'رمز المسح')" @close="qrOpen = false">
      <template #icon><LucideQrCode class="size-5" /></template>
      <div class="flex flex-col items-center gap-4 text-center">
        <p class="font-display text-4xl font-black tracking-[0.2em] tabular-nums sm:text-5xl" dir="ltr">{{ booking.checkin_code }}</p>
        <p class="text-sm text-muted-foreground">
          {{ t('qr_note', 'Show this code at the desk when you arrive to check in.', 'يرجى مسح رمز الاستجابة السريعة عند الوصول لتسجيل حضورك في الورشة.') }}
        </p>
      </div>
      <template #footer>
        <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" @click="qrOpen = false">{{ t('close', 'Close', 'اغلاق') }}</Button>
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
        :lock-people="isCatalogueType(workshop.type)"
        :errors="rescheduleErrors"
      />
      <span v-if="rescheduleError" class="mt-3 block text-xs text-destructive">{{ rescheduleError }}</span>
      <template #footer>
        <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" :disabled="rescheduling" @click="rescheduleOpen = false">{{ t('close', 'Close', 'اغلاق') }}</Button>
        <Button type="button" class="h-12 flex-1 rounded-xl bg-brand-rust hover:bg-brand-rust/90" :disabled="rescheduling || !rescheduleSlotId" @click="doReschedule">
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
    <BookingSheet :open="!!pieceToRemove" :title="t('remove_piece_title', 'Remove this piece', 'حذف القطعة')" @close="pieceToRemove = null">
      <template #icon><LucideTrash2 class="size-5" /></template>
      <p class="text-sm text-muted-foreground">
        {{ t('remove_piece_confirm', 'This removes “:label” and its :n photo(s).', 'سيؤدي هذا إلى حذف «:label» و :n من صورها.', { label: pieceToRemove?.label ?? '', n: pieceToRemove?.images?.length ?? 0 }) }}
      </p>
      <template #footer>
        <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" @click="pieceToRemove = null">{{ t('no', 'No', 'لا') }}</Button>
        <Button type="button" class="h-12 flex-1 rounded-xl bg-destructive text-white hover:bg-destructive/90" @click="doRemovePiece">{{ t('yes', 'Yes', 'نعم') }}</Button>
      </template>
    </BookingSheet>
  </main>
</template>

<script setup>
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

// Only the reschedule sheet needs the workshop (its type decides whether the party size is
// locked), so it is fetched when that sheet opens rather than on every render.
const workshop = ref(null)

const apply = (res) => { set(res?.data ?? res) }

const state = computed(() => bookingState(booking.value))

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
    accent: 'bg-brand-rust hover:bg-brand-rust/90',
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

const qrOpen = ref(false)
const warningOpen = ref(false)
const cancelOpen = ref(false)
const rescheduleOpen = ref(false)
const pieceToRemove = ref(null)

const panel = computed(() => {
  const days = booking.value ? daysUntil(booking.value.booking_date) : 0
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
      body: t('panel_confirmed_body', 'Please show your code when you arrive at the studio — :n day(s) to go.', 'يرجى مسح الرمز عند الوصول إلى موقع الورشة، والمتبقي على موعدها :n أيام.', { n: Math.max(days, 0) }),
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
      title: t('panel_absent_title', 'Not checked in', 'لم تحضر'),
      body: t('panel_absent_body', 'The session started and your attendance was not recorded.', 'بدأت الورشة ولم يتم تسجيل حضورك بعد.'),
    },
    preparing: {
      icon: resolveComponent('LucideFlame'),
      tone: 'bg-brand-rust/10 text-brand-rust',
      title: t('panel_preparing_title', 'Being prepared', 'قيد التحضير'),
      // WITH NO NUMBER IN IT. Nothing on the booking says when a piece will be fired —
      // there is no `ready_at` server-side — so a turnaround here is a commitment the
      // studio never made.
      body: t('panel_preparing_body_plain', 'Your piece is being finished with care.', 'جاري تجهيز قطعتك بعناية.'),
    },
    ready: {
      icon: resolveComponent('LucidePackageCheck'),
      tone: 'bg-brand-blush/40 text-brand-rust',
      title: t('panel_ready_title', 'Your piece is ready', 'القطعة جاهزة'),
      body: t('panel_ready_body', 'Your piece is ready now — pick it up or have it delivered.', 'قطعتك جاهزة الآن للاستلام أو التوصيل.'),
    },
    awaiting_pickup: {
      icon: resolveComponent('LucideStore'),
      tone: 'bg-brand-blush/40 text-brand-rust',
      title: t('panel_awaiting_pickup_title', 'Ready for pickup', 'جاهزة للاستلام'),
      body: t('panel_awaiting_pickup_body', 'Your piece is waiting for you at the studio.', 'قطعتك بانتظارك في الاستوديو.'),
    },
    getting_ready: {
      icon: resolveComponent('LucidePackage'),
      tone: 'bg-brand-rust/10 text-brand-rust',
      title: t('panel_getting_ready_title', 'Being packed', 'قيد التجهيز'),
      body: t('panel_getting_ready_body', 'We are packing your piece carefully, ready for delivery.', 'جارٍ تغليف قطعتك وتجهيزها بعناية استعدادًا للتوصيل.'),
    },
    on_the_way: {
      icon: resolveComponent('LucideTruck'),
      tone: 'bg-brand-rust/10 text-brand-rust',
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
    const res = await actions.reschedule({
      workshop_slot_id: rescheduleSlotId.value,
      booking_date: rescheduleDate.value,
      people_count: reschedulePeople.value,
    })
    apply(res)
    rescheduleOpen.value = false
    toast.success(res?.message ?? '')
    // Growing a paid booking past the wallet drops it back to a fresh hold.
    if (booking.value?.status === 'pending_payment') {
      toast.info(t('reschedule_needs_payment', 'The new time costs more than the wallet covers — please pay the difference.', 'الموعد الجديد أعلى مما تغطيه المحفظة — يرجى دفع الفرق.'))
    }
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
    await refresh()
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
