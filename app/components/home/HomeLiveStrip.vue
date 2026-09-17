<template>
  <section v-if="attending || order" class="mx-auto flex max-w-3xl flex-col gap-3 px-6 pt-14">
    <!-- The session the desk has already scanned them into. `attending` is the only
         status that means now — a booking three days out is not happening. -->
    <NuxtLink
      v-if="attending"
      :to="`/bookings/${attending.id}`"
      data-test="live-workshop"
      class="flex items-center gap-4 rounded-card border border-success/40 bg-success/10 p-4 transition-colors hover:bg-success/15"
    >
      <span class="flex size-11 shrink-0 items-center justify-center rounded-control bg-success text-success-foreground">
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
          <span dir="ltr">{{ t('live_workshop_until', 'Until :time', 'حتى :time', { time: attending.end_time?.slice(0, 5) ?? '' }) }}</span>
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
      <span class="flex size-11 shrink-0 items-center justify-center rounded-control bg-brand-rust/10 text-brand-rust">
        <LucideTruck class="size-5" />
      </span>
      <span class="min-w-0 flex-1">
        <span class="flex items-center gap-2">
          <span class="truncate font-display text-base font-semibold text-foreground">
            {{ t('order_number', 'Order #:id', 'الطلب رقم :id', { id: order.id, subGroup: 'shop' }) }}
          </span>
          <ShopOrderStatusBadge :status="order.status" />
        </span>
        <span class="mt-0.5 block text-xs text-muted-foreground">
          {{ t('live_items', ':n pieces', ':n قطعة', { n: itemCount }) }}
        </span>
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

const { t } = useLang('web', 'home')
const { format } = usePrice()
const { isRegistered } = useIsRegistered()

const { items: bookings } = useApiList('/api/workshops/bookings', {
  key: 'home-live-booking',
  query: { status: 'attending', per_page: 1 },
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
const order = computed(() => orders.value.find((o) => !TERMINAL_ORDER_STATUSES.includes(o.status)) ?? null)

const itemCount = computed(() => (order.value?.items ?? []).reduce((sum, item) => sum + (item.quantity ?? 0), 0))
</script>
