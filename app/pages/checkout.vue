<template>
  <main class="bg-background">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('checkout_title', 'Checkout', 'الدفع') }}</h1>

      <!-- The open hold the server refused a second checkout for: pay it or cancel it. -->
      <section v-if="resumed && order" class="mt-8 rounded-3xl border border-brand-terracotta/40 bg-brand-mist/40 p-6 sm:p-8">
        <h2 class="font-display text-xl font-semibold">{{ t('open_hold_title', 'An order is already waiting for payment', 'لديك طلب بانتظار الدفع') }}</h2>
        <p class="mt-2 text-sm text-muted-foreground">{{ error || t('open_hold_body', 'Pay or cancel it before placing a new one.', 'ادفعه أو ألغِه قبل إنشاء طلب جديد.') }}</p>

        <div class="mt-5 flex flex-wrap items-center gap-3">
          <NuxtLink :to="`/orders/${order.id}`" class="text-sm font-medium text-brand-terracotta underline-offset-4 hover:underline">
            {{ t('open_hold_link', 'Order #:id', 'الطلب رقم :id', { id: order.id }) }}
          </NuxtLink>
          <ShopOrderStatusBadge :status="order.status" />
        </div>

        <CheckoutPaymentHold
          class="mt-5"
          :amount-due="order.amount_due"
          :payment-status="order.payment_status"
          :expires-at="order.payment_expires_at"
          :pay="pay"
          restart-to="/cart"
          @paid="onPaid"
          @expired="reset"
        />

        <ShopOrderCancelButton class="mt-4" :order="order" :cancel="cancelOpen" @cancelled="reset" />
      </section>

      <!-- The order this session created, held and waiting for the pay call. -->
      <section v-else-if="order" class="mt-8 flex flex-col gap-6">
        <div v-if="settled" class="rounded-3xl border bg-card p-8 text-center">
          <span class="mx-auto flex size-14 items-center justify-center rounded-2xl bg-brand-green/10 text-brand-green">
            <LucideCheckCircle2 class="size-6" />
          </span>
          <p class="mt-4 font-display text-2xl font-semibold">{{ t('order_placed_title', 'Your order is placed', 'تم تأكيد طلبك') }}</p>
          <p class="mt-2 text-sm text-muted-foreground">{{ t('order_placed_body', 'We will start preparing it right away.', 'سنبدأ بتجهيزه فورًا.') }}</p>
          <Button as-child class="mt-6 h-12 rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90">
            <NuxtLink :to="`/orders/${order.id}`">{{ t('view_order', 'View the order', 'عرض الطلب') }}</NuxtLink>
          </Button>
        </div>

        <template v-else>
          <CheckoutSummary :quote="order" :title="t('summary_title', 'Your order', 'طلبك', { subGroup: 'checkout' })" />
          <CheckoutPaymentHold
            :amount-due="order.amount_due"
            :payment-status="order.payment_status"
            :expires-at="order.payment_expires_at"
            :pay="pay"
            restart-to="/cart"
            @paid="onPaid"
            @expired="reset"
          />

          <!-- The hold is sitting on stock, on the wallet slice it took and on a use of
               the discount code for the whole window. A customer who decides not to pay
               could only walk away and leave all three locked until it expired. -->
          <ShopOrderCancelButton :order="order" :cancel="cancelOpen" @cancelled="reset" />
        </template>
      </section>

      <!-- Empty cart: nothing to quote, nothing to place. -->
      <div v-else-if="!lines.length && !cartLoading" class="mx-auto mt-8 max-w-xl rounded-3xl border bg-card p-8 text-center sm:p-12">
        <span class="mx-auto flex size-14 items-center justify-center rounded-2xl bg-brand-terracotta/10 text-brand-terracotta">
          <LucideShoppingBag class="size-6" />
        </span>
        <p class="mt-4 font-display text-xl font-semibold">{{ t('cart_empty_title', 'Your cart is empty', 'عربيتك فاضية', { subGroup: 'shop' }) }}</p>
        <p class="mt-2 text-sm text-muted-foreground">{{ t('checkout_empty_body', 'There is nothing to pay for yet.', 'لا يوجد ما يُدفع بعد.') }}</p>
        <Button as-child class="mt-6 h-12 rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90">
          <NuxtLink to="/shop">{{ t('browse_shop', 'Browse the shop', 'تصفح المتجر', { subGroup: 'shop' }) }}</NuxtLink>
        </Button>
      </div>

      <div v-else class="mt-8 grid gap-6 lg:grid-cols-[1fr_20rem] lg:items-start">
        <div class="flex flex-col gap-6">
          <section class="rounded-3xl border bg-card p-6 sm:p-8">
            <h2 class="font-display text-xl font-semibold">{{ t('delivery_to', 'Deliver to', 'التوصيل إلى') }}</h2>
            <p class="mt-1 text-sm text-muted-foreground">{{ t('delivery_to_note', 'The address sets your delivery zone and fee.', 'العنوان يحدد منطقة التوصيل ورسومه.') }}</p>
            <AddressPicker v-model="addressId" class="mt-5" />
            <span v-if="addressError" class="mt-2 block text-xs text-destructive">{{ addressError }}</span>
          </section>

          <section class="rounded-3xl border bg-card p-6 sm:p-8">
            <h2 class="font-display text-xl font-semibold">{{ t('payment_title', 'Payment', 'الدفع') }}</h2>
            <div class="mt-5 flex flex-col gap-5">
              <CheckoutDiscountCodeInput v-model="discountCode" :errors="errors" :disabled="quoting || placing" />
              <CheckoutWalletToggle v-model="payFromWallet" :disabled="quoting || placing" />
            </div>
          </section>

          <section class="rounded-3xl border bg-card p-6 sm:p-8">
            <h2 class="font-display text-xl font-semibold">{{ t('your_items', 'Your pieces', 'قطعك') }}</h2>
            <ShopOrderItems class="mt-5" :items="lines" />
          </section>
        </div>

        <aside class="flex flex-col gap-4 lg:sticky lg:top-6">
          <CheckoutSummary v-if="!quoteFailed" :quote="quote" :title="t('summary_title', 'Your order', 'طلبك', { subGroup: 'checkout' })" />

          <!-- The quote is the whole of what this page knows about money. With none, and
               none on the way, the summary's grey bars would wait for ever. -->
          <div v-else class="rounded-card border bg-brand-mist/40 p-5 text-center" data-test="quote-failed">
            <p class="text-sm text-muted-foreground">
              {{ error || t('quote_failed', 'We could not price your order just now.', 'تعذّر تسعير طلبك الآن.') }}
            </p>
            <Button type="button" variant="outline" class="mt-4 h-11 w-full rounded-control" @click="requote()">
              {{ t('try_again', 'Try again', 'حاول مرة أخرى') }}
            </Button>
          </div>

          <p v-if="cartError" class="flex items-start gap-2 rounded-2xl bg-destructive/10 px-4 py-3 text-sm text-destructive">
            <LucideAlertCircle class="mt-0.5 size-4 shrink-0" />
            <span>{{ cartError }}</span>
          </p>
          <span v-else-if="error && !quoteFailed" class="text-xs text-destructive">{{ error }}</span>

          <Button
            type="button"
            class="h-12 w-full rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
            :disabled="!canPlace"
            @click="place"
          >
            {{ placing ? t('placing', 'Placing…', 'جارٍ التأكيد…') : t('confirm_payment', 'Confirm payment', 'تاكيد الدفع') }}
          </Button>
        </aside>
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'checkout',
})

/**
 * Quote → checkout → pay. The three inputs (address, coupon, wallet) drive a fresh quote
 * on every change, and the create call sends the identical three — so what the customer
 * confirms is what the server charges. The frame's inline map + phone pair is replaced by
 * the saved-address book, which is what supplies the delivery zone.
 */
const { t } = useLang('web', 'checkout')
const toast = useToast()

const {
  cart, addressId, discountCode, useWallet: payFromWallet,
  quote, quoting, errors, error, order, resumed, settled,
  checkout, pay, requote, reset,
} = useCheckout()

const { refreshIdentity } = useSanctumAuth()
const { refresh: refreshWallet } = useWallet()

/**
 * Paying moves the balance, and the site reads one from two places — the ledger and the
 * identity every other screen shows the number off. Both go stale at that same moment.
 *
 * Hung off `settled` rather than off the pay button: an order the wallet covers in full
 * settles at create with no pay step at all, and on the pay step the hold component is
 * unmounted by this very flip — taking its `paid` event with it.
 */
watch(settled, (is) => {
  // Best-effort: a stale balance is not worth failing a payment that already landed.
  if (is) Promise.all([refreshIdentity(), refreshWallet()]).catch(() => {})
})

const api = useApi()
const placing = ref(false)

// `cart` is a plain object of refs, and templates only unwrap top-level ones.
const lines = cart.items
const cartLoading = cart.pending

// The server takes either an `address_id` or a lat/lng/phone triple, so with no address
// chosen it answers 422 keyed on `lat`/`lng`/`phone` — nowhere near the address section,
// and worded as raw Laravel ("The lat field is required when address id is not present.").
// The quote succeeds regardless, since it falls back to the app-wide delivery fee, so the
// summary rendered and the button looked ready. Say it here instead, and hold the button.
const missingAddress = computed(() => !addressId.value)

const addressError = computed(
  () =>
    fieldError(errors.value, 'address_id') ||
    fieldError(errors.value, 'lat') ||
    fieldError(errors.value, 'phone') ||
    // Only once there is something to buy, so it does not flash while the cart loads.
    (missingAddress.value && !!quote.value
      ? t('address_required', 'Choose a delivery address to continue.', 'اختر عنوان التوصيل للمتابعة.')
      : ''),
)
const cartError = computed(() => fieldError(errors.value, 'cart'))
const canPlace = computed(() =>
  !placing.value && !quoting.value && !!quote.value && cart.canCheckout.value && !missingAddress.value,
)
const quoteFailed = computed(() => !quote.value && !quoting.value && !!error.value)

const place = async () => {
  if (placing.value) return
  placing.value = true
  try {
    await checkout()
    if (settled.value) toast.success(t('order_placed_title', 'Your order is placed', 'تم تأكيد طلبك'))
  } catch {
    // errors.cart / errors.discount_code / errors.address_id are already on screen
  } finally {
    placing.value = false
  }
}

const onPaid = () => {
  toast.success(t('payment_done', 'Payment completed.', 'تم الدفع بنجاح.'))
  return navigateTo(`/orders/${order.value.id}`)
}

/** The recovery panel's cancel — `useCheckout` only knows how to pay. */
const cancelOpen = (id) => api(`/api/shop/orders/${id}`, { method: 'DELETE' })

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/cart', label: t('cart_title', 'My cart', 'عربيتي', { subGroup: 'shop' }) },
  { label: t('checkout_title', 'Checkout', 'الدفع') },
])

useSeoMeta({ title: () => t('checkout_title', 'Checkout', 'الدفع'), robots: 'noindex' })
</script>
