<template>
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-5">
        <div class="flex items-center justify-between">
          <NuxtLink
            to="/orders"
            class="flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground -ms-2 rtl:-scale-x-100"
            :aria-label="t('back_to_orders', 'Back to my orders', 'عودة للطلبات')"
          >
            <LucideArrowLeft class="size-5" />
          </NuxtLink>
          <h1 class="font-display text-lg font-semibold text-foreground">
            {{ t('order_number', 'Order #:id', 'الطلب رقم :id', { id: route.params.id }) }}
          </h1>
          <span class="size-10" />
        </div>

        <div v-if="!order" class="grid gap-4 lg:grid-cols-[1fr_20rem] lg:items-start" aria-busy="true">
          <AppSkeleton v-for="n in 4" :key="n" class="h-28 w-full rounded-2xl!" />
        </div>

        <template v-else>
          <div class="flex items-center justify-between gap-3 rounded-2xl border bg-card p-5">
            <div class="flex flex-col gap-1">
              <ShopOrderStatusBadge :status="order.status" />
              <span class="text-xs text-muted-foreground">{{ formatDate(order.created_at) }}</span>
            </div>
            <span class="font-display text-lg font-black text-primary sm:text-xl">{{ format(order.total_price) }}</span>
          </div>

          <div class="grid gap-5 lg:grid-cols-[1fr_20rem] lg:items-start">
            <div class="flex flex-col gap-5">
              <section class="rounded-2xl border bg-card p-5">
                <h2 class="font-display text-base font-semibold text-foreground">{{ t('order_progress', 'Progress', 'مسار الطلب') }}</h2>
                <ShopOrderTimeline class="mt-5" :order="order" />
              </section>

              <section class="rounded-2xl border bg-card p-5">
                <h2 class="font-display text-base font-semibold text-foreground">{{ t('your_items', 'Your pieces', 'قطعك', { subGroup: 'checkout' }) }}</h2>
                <ShopOrderItems class="mt-4" :items="order.items ?? []" />
              </section>

              <section v-if="hasDelivery" class="rounded-2xl border bg-card p-5">
                <h2 class="font-display text-base font-semibold text-foreground">{{ t('delivery_details', 'Delivery', 'التوصيل') }}</h2>
                <dl class="mt-4 flex flex-col gap-3 break-words text-sm">
                  <div v-if="order.delivery_address">
                    <dt class="text-xs text-muted-foreground">{{ t('delivery_address', 'Address', 'العنوان') }}</dt>
                    <dd class="mt-0.5 text-foreground">{{ order.delivery_address }}</dd>
                  </div>
                  <div v-if="order.delivery_short_address">
                    <dt class="text-xs text-muted-foreground">{{ t('delivery_short_address', 'Short address', 'العنوان المختصر') }}</dt>
                    <dd class="mt-0.5 font-medium tracking-wide text-foreground" dir="ltr">{{ order.delivery_short_address }}</dd>
                  </div>
                  <div v-if="order.delivery_zone">
                    <dt class="text-xs text-muted-foreground">{{ t('delivery_zone', 'Zone', 'المنطقة') }}</dt>
                    <dd class="mt-0.5 text-foreground">{{ order.delivery_zone }}</dd>
                  </div>
                  <div v-if="order.delivery_phone">
                    <dt class="text-xs text-muted-foreground">{{ t('delivery_phone', 'Phone', 'رقم الهاتف') }}</dt>
                    <dd class="mt-0.5 text-foreground" dir="ltr">{{ order.delivery_phone }}</dd>
                  </div>
                  <div v-if="order.delivery_notes">
                    <dt class="text-xs text-muted-foreground">{{ t('delivery_notes', 'Notes', 'ملاحظات') }}</dt>
                    <dd class="mt-0.5 text-foreground">{{ order.delivery_notes }}</dd>
                  </div>
                </dl>

                <a
                  v-if="mapUrl"
                  :href="mapUrl"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="mt-4 flex items-center gap-2 text-sm font-medium text-brand-rust underline-offset-4 hover:underline"
                >
                  <LucideMapPin class="size-4" />
                  {{ t('open_in_maps', 'Open in maps', 'فتح في الخرائط') }}
                </a>
              </section>
            </div>

            <aside class="flex flex-col gap-5 lg:sticky lg:top-6">
              <CheckoutPaymentHold
                v-if="order.status === 'awaiting_payment'"
                :amount-due="order.amount_due"
                :payment-status="order.payment_status"
                :expires-at="order.payment_expires_at"
                :pay="pay"
                restart-to="/cart"
                @paid="onPaid"
                @expired="refresh"
              />

              <CheckoutSummary :quote="order" :title="t('summary_title', 'Payment', 'الدفع', { subGroup: 'checkout' })" />

              <ShopOrderCancelButton :order="order" :cancel="cancel" @cancelled="onCancelled" />
            </aside>
          </div>
        </template>
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'order',
})

/**
 * One order end to end: the pay hold while it has one, the status timeline, the lines
 * (whose `product` is null once a piece is deleted), the money the server computed, and
 * the delivery snapshot it took at checkout.
 */
const route = useRoute()
const { t } = useLang('web', 'shop')
const { format } = usePrice()
const { formatDate } = useDateFormat()
const toast = useToast()

const { order, error, status, refresh, pay, cancel } = useOrder(() => route.params.id)

watchEffect(() => {
  if (status.value === 'error' || (status.value === 'success' && !order.value)) {
    showError({ statusCode: error.value?.statusCode ?? 404, statusMessage: 'Order not found' })
  }
})

const { refresh: refreshCart } = useCart()
const { refresh: refreshWallet } = useWallet()
const { refreshIdentity } = useSanctumAuth()

/**
 * The refund lands on the wallet the moment the cancel returns, so both places the site
 * reads a balance from — the ledger and the identity every other screen shows — have to
 * be refetched, or the customer is told their money is somewhere it no longer is.
 */
const onCancelled = async () => {
  await Promise.all([refresh(), refreshWallet(), refreshIdentity()])
}

const onPaid = async () => {
  toast.success(t('payment_done', 'Payment completed.', 'تم الدفع بنجاح.', { subGroup: 'checkout' }))
  // The cart is emptied at pay time, not at checkout.
  await refreshCart()
  await refresh()
}

const hasDelivery = computed(() => Boolean(
  order.value?.delivery_address || order.value?.delivery_zone || order.value?.delivery_phone || order.value?.delivery_short_address,
))

const mapUrl = computed(() => {
  const { delivery_lat: lat, delivery_lng: lng } = order.value ?? {}
  return lat && lng ? `https://maps.google.com/?q=${lat},${lng}` : ''
})

useSeoMeta({
  title: () => t('order_number', 'Order #:id', 'الطلب رقم :id', { id: route.params.id }),
  robots: 'noindex',
})
</script>
