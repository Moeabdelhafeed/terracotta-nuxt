<template>
  <section v-if="attending || next || order" class="mx-auto flex max-w-6xl flex-col gap-3 px-6 pt-14">
    <!-- The session the desk has already scanned them into. `attending` is the only
         status that means now — a booking three days out is not happening. -->
    <NuxtLink
      v-if="attending"
      :to="`/bookings/${attending.id}`"
      data-test="live-workshop"
      class="flex items-center gap-4 rounded-card border bg-card p-4 transition-colors hover:bg-brand-mist/40"
    >
      <span
        class="flex size-11 shrink-0 items-center justify-center rounded-control"
        :style="wellStyle(colourFor(attending))"
      >
        <LucideBrush class="size-5" />
      </span>
      <span class="min-w-0 flex-1">
        <span class="block text-xs font-semibold uppercase tracking-[0.18em] text-success">
          {{ t('live_workshop', 'Happening now', 'يحدث الآن') }}
        </span>
        <span class="mt-0.5 block truncate font-display text-base font-semibold text-foreground">
          {{ attending.workshop_title }}
        </span>
        <span class="mt-0.5 block text-xs text-muted-foreground">
          <template v-if="attending.checkin_code">{{ t('live_show_code', 'Show my code', 'اعرض رمزي') }} · </template>
          <span dir="ltr">{{ t('live_workshop_until', 'Until :time', 'حتى :time', { time: formatClock(attending.end_time, code) }) }}</span>
        </span>
      </span>
      <LucideChevronRight class="size-4 shrink-0 text-muted-foreground rtl:-scale-x-100" />
    </NuxtLink>

    <!-- The seat already booked and not yet sat in. A date, not a code: the code is for
         the desk on the day, and this row is about a day that has not come. -->
    <NuxtLink
      v-if="next"
      :to="`/bookings/${next.id}`"
      data-test="live-next"
      class="flex items-center gap-4 rounded-card border bg-card p-4 transition-colors hover:bg-brand-mist/40"
    >
      <span
        class="flex size-11 shrink-0 items-center justify-center rounded-control"
        :style="wellStyle(colourFor(next))"
      >
        <LucideCalendarCheck class="size-5" />
      </span>
      <span class="min-w-0 flex-1">
        <span class="block text-xs font-semibold uppercase tracking-[0.18em] text-primary">
          {{ t('next_booking', 'Your next workshop', 'ورشتك القادمة') }}
        </span>
        <span class="mt-0.5 block truncate font-display text-base font-semibold text-foreground">
          {{ next.workshop_title }}
        </span>
        <span class="mt-0.5 block text-xs text-muted-foreground">
          {{ t('next_booking_when', ':date · :time', ':date · :time', {
            date: formatBookingDate(next.booking_date, code),
            time: formatClock(next.start_time, code),
          }) }}
        </span>
      </span>
      <LucideChevronRight class="size-4 shrink-0 text-muted-foreground rtl:-scale-x-100" />
    </NuxtLink>

    <!-- The order the studio has not finished with. An unpaid hold counts — it is the
         one with a clock on it. -->
    <NuxtLink
      v-if="order"
      :to="`/orders/${order.id}`"
      data-test="live-order"
      class="flex items-center gap-4 rounded-card border bg-card p-4 transition-colors hover:bg-brand-mist/40"
    >
      <span class="flex size-11 shrink-0 items-center justify-center rounded-control bg-brand-terracotta/10 text-brand-terracotta">
        <LucideTruck class="size-5" />
      </span>
      <span class="min-w-0 flex-1">
        <span class="flex items-center gap-2">
          <span class="truncate font-display text-base font-semibold text-foreground">
            {{ t('order_number', 'Order #:id', 'الطلب رقم :id', { id: order.id, subGroup: 'shop' }) }}
          </span>
          <ShopOrderStatusBadge :status="order.status" />
        </span>
        <span class="mt-0.5 block text-xs text-muted-foreground">{{ itemsLabel }}</span>
      </span>
      <span class="shrink-0 font-display text-base font-black text-primary">{{ format(order.total_price) }}</span>
    </NuxtLink>
  </section>
</template>

<script setup>
/**
 * What the visitor has in flight, above everything else on the front door: the workshop
 * they are sitting in right now, and the order the studio has not finished with.
 *
 * Both are registered-only endpoints and neither belongs in the SSR payload of a page
 * every crawler hits, so they are fetched after hydration and only for a real account.
 * `GET /api/home`'s `current_booking` is deliberately not used for the workshop row: it
 * is the *next* seat, and a seat still to come is not a session happening now.
 */
const TERMINAL_ORDER_STATUSES = ['completed', 'cancelled']

const { t, code } = useLang('web', 'home')
const { format } = usePrice()
const { isRegistered } = useIsRegistered()

const { items: bookings } = useApiList('/api/workshops/bookings', {
  key: 'home-live-booking',
  // Both rows come out of ONE list: the session they are in, and the seat they are coming
  // back for. `GET /api/home`'s `current_booking` answers only the second, and only on
  // this page — the workshops page needs the same row.
  query: { status: 'attending,confirmed', sort: 'session_soonest', per_page: 10 },
  server: false,
  lazy: true,
  immediate: isRegistered.value,
  watch: [isRegistered],
})

const { items: orders } = useApiList('/api/shop/orders', {
  key: 'home-live-order',
  query: { per_page: 5 },
  server: false,
  lazy: true,
  immediate: isRegistered.value,
  watch: [isRegistered],
})

const attending = computed(() => bookings.value.find((b) => b.status === 'attending') ?? null)
// Sorted by the server, so the first confirmed row IS the soonest. A booking cannot be
// both the session happening now and the one still to come.
const next = computed(() => bookings.value.find((b) => b.status === 'confirmed') ?? null)
const order = computed(() => orders.value.find((o) => !TERMINAL_ORDER_STATUSES.includes(o.status)) ?? null)

/**
 * A booking's own workshop colour, matched on `workshop_id` against the catalogue — the
 * booking payload carries none. The same lookup `BookingCard` and the booking page make,
 * off the same cached list; an unmatched row keeps the studio's hue.
 */
const { workshops } = useWorkshops()
const colourFor = (booking) =>
  workshopColour(workshops.value.find((entry) => entry.id === booking?.workshop_id))

/**
 * The same treatment the order row wears — a wash of the colour behind the glyph, and the
 * glyph in the colour itself. `color-mix` rather than an opacity class because the hue is
 * the workshop's own hex, not a token Tailwind can suffix.
 */
const wellStyle = (colour) => ({
  backgroundColor: `color-mix(in oklch, ${colour} 12%, transparent)`,
  color: colour,
})

const itemCount = computed(() => (order.value?.items ?? []).reduce((sum, item) => sum + (item.quantity ?? 0), 0))

/**
 * Arabic counts things in more than two ways, and «1 قطعة» is not one of them. The app
 * carries the full plural set — واحدة / قطعتان / قطع / قطعة — so the same row does here,
 * with the number in the locale's own digits.
 */
const itemsLabel = computed(() => {
  const n = itemCount.value
  const digits = localeDigits(n, code.value)

  if (code.value !== 'ar') {
    return n === 1
      ? t('live_items_one', '1 piece', 'قطعة واحدة')
      : t('live_items_other', ':n pieces', ':n قطعة', { n: digits })
  }
  if (n === 1) return t('live_items_one', '1 piece', 'قطعة واحدة')
  if (n === 2) return t('live_items_two', '2 pieces', 'قطعتان')
  if (n % 100 >= 3 && n % 100 <= 10) return t('live_items_few', ':n pieces', ':n قطع', { n: digits })
  return t('live_items_other', ':n pieces', ':n قطعة', { n: digits })
})
</script>
