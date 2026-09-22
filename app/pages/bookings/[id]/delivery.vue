<template>
  <main v-if="status !== 'success' && !booking" class="mx-auto max-w-6xl px-6 py-16" aria-busy="true">
    <AppSkeleton class="h-9 w-2/3" />
    <AppSkeleton class="mt-6 h-64 w-full !rounded-3xl" />
  </main>

  <main v-else-if="booking" class="bg-background">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('delivery_title', 'Your finished piece', 'استلام قطعتك') }}</h1>

      <!-- The step exists only after the piece is finished, and never for a workshop that
           has no delivery at all (the candle goes home the same day). -->
      <p v-if="!available" class="mx-auto mt-8 max-w-xl rounded-3xl border border-dashed p-10 text-center text-muted-foreground">
        {{ t('delivery_unavailable', 'This piece has no pickup or delivery step — you take it home the same day.', 'هذه القطعة ليس لها خطوة استلام أو توصيل — تأخذها معك في اليوم نفسه.') }}
      </p>

      <template v-else>
        <p class="mt-3 text-muted-foreground">{{ t('delivery_intro', 'Pick it up from the studio, or have it delivered to your address.', 'استلمها من الاستوديو، أو اطلب توصيلها إلى عنوانك.') }}</p>

        <div class="mt-8 grid gap-8 lg:grid-cols-[1.2fr_1fr] lg:items-start">
          <div>
            <div class="flex flex-wrap gap-3">
              <Button
                type="button"
                class="h-12 flex-1 rounded-xl text-base"
                :variant="method === 'pickup' ? 'default' : 'outline'"
                :class="method === 'pickup' ? 'bg-brand-green hover:bg-brand-green/90' : ''"
                @click="method = 'pickup'"
              >{{ t('choose_pickup', 'Pick it up', 'استلام') }}</Button>
              <Button
                type="button"
                class="h-12 flex-1 rounded-xl text-base"
                :variant="method === 'delivery' ? 'default' : 'outline'"
                :class="method === 'delivery' ? 'bg-brand-terracotta hover:bg-brand-terracotta/90' : ''"
                @click="method = 'delivery'"
              >{{ t('choose_delivery', 'Have it delivered', 'توصيل') }}</Button>
            </div>
            <span v-if="fieldError(errors, 'method')" class="mt-2 block text-xs text-destructive">{{ fieldError(errors, 'method') }}</span>

            <p v-if="method === 'pickup'" class="mt-6 rounded-2xl border bg-card p-6 text-sm text-muted-foreground">
              {{ t('pickup_note', 'Come by the studio with your booking code and we will hand your piece over.', 'مر على الاستوديو ومعك رمز الحجز وسنسلمك قطعتك.') }}
            </p>

            <p v-if="method === 'pickup' && refundable" class="mt-3 rounded-2xl bg-brand-green/10 p-4 text-sm text-brand-green" data-test="pickup-refund">
              {{ t('pickup_refunds_fee', 'The :amount delivery fee goes back to your Terracotta balance. Asking for delivery again later is charged at the rate on the day.', 'ستعاد رسوم التوصيل :amount إلى رصيدك في تيراكوتا. وإذا طلبت التوصيل لاحقًا فستُحتسب الرسوم من جديد بسعر اليوم.', { amount: format(booking.delivery_fee_wallet_applied) }) }}
            </p>

            <div v-else class="mt-6">
              <AddressPicker v-model="addressId" />
              <span v-if="fieldError(errors, 'address_id')" class="mt-2 block text-xs text-destructive">{{ fieldError(errors, 'address_id') }}</span>
              <span v-if="fieldError(errors, 'phone')" class="mt-2 block text-xs text-destructive">{{ fieldError(errors, 'phone') }}</span>
            </div>
          </div>

          <aside class="flex flex-col gap-4">
            <CheckoutWalletToggle v-if="method === 'delivery'" v-model="payWithWallet" :disabled="saving" />

            <CheckoutSummary v-if="method === 'delivery'" :quote="quote" :title="t('delivery_summary', 'Delivery', 'التوصيل')" />

            <!-- Re-choosing delivery never charges twice. -->
            <p v-if="quote?.already_paid" class="rounded-xl bg-brand-green/10 px-3 py-2 text-xs font-medium text-brand-green">
              {{ t('delivery_already_paid', 'The delivery fee was already charged — nothing more to pay.', 'تم احتساب رسوم التوصيل سابقًا — لا يوجد مبلغ إضافي.') }}
            </p>

            <!-- There is no `/pay` route for this fee: the wallet covers what it can and any
                 remainder is simply owed. -->
            <p v-if="method === 'delivery' && quote && !isZeroMoney(quote.amount_due)" class="rounded-xl bg-brand-mist/60 px-3 py-2 text-xs text-muted-foreground">
              {{ t('delivery_due_note', ':amount stays owing and is settled at handover — there is no online payment for the delivery fee.', 'يبقى مبلغ :amount مستحقًا يُسدَّد عند التسليم — لا يوجد دفع إلكتروني لرسوم التوصيل.', { amount: format(quote.amount_due) }) }}
            </p>

            <span v-if="submitError" class="text-xs text-destructive">{{ submitError }}</span>

            <Button
              type="button"
              class="h-12 rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
              :disabled="saving || (method === 'delivery' && !addressId)"
              @click="choose"
            >
              {{ saving
                ? t('saving', 'Saving…', 'جارٍ الحفظ...')
                : method === 'pickup'
                  ? t('confirm_pickup', 'Confirm pickup', 'تاكيد الاستلام')
                  : t('confirm_delivery', 'Confirm the delivery', 'تاكيد التوصيل') }}
            </Button>
          </aside>
        </div>
      </template>
    </div>
  </main>
</template>

<script setup>
/**
 * Pickup or delivery for the finished piece. The fee is charged to the wallet at the moment
 * the choice is made — there is no hold and no `/pay` route, so whatever the wallet does not
 * cover comes back on the booking as `delivery_fee_amount_due`.
 */
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'booking-delivery',
})

const route = useRoute()
const { t } = useLang('web', 'bookings')
const { format } = usePrice()
const toast = useToast()

const { booking, status, error } = useBooking(() => route.params.id)

/**
 * Without this a failed fetch leaves `status === 'error'` with no booking, which is the
 * same shape the loading branch tests for — so the page sat on an `aria-busy` skeleton
 * for ever, with nothing said and nothing to retry. Same handling as the booking page
 * this one is opened from.
 */
watchEffect(() => {
  if (status.value === 'error' || (status.value === 'success' && !booking.value)) {
    showError({ statusCode: error.value?.statusCode ?? 404, statusMessage: 'Booking not found' })
  }
})
const actions = useBookingActions(() => route.params.id)

// Both surfaces of the balance go stale on every choice: pickup credits the fee back, and
// delivery spends whatever the wallet covers.
const { refreshIdentity } = useSanctumAuth()
const { refresh: refreshWallet } = useWallet()

const available = computed(() => hasDeliveryStep(booking.value))

/** A fee is only given back if one was actually charged — see `chooseDelivery(…, pickup)`. */
// Only the wallet slice is ever taken when delivery is chosen — the rest stays owed, with
// nothing collecting it — so that slice is the whole of what comes back. Promising the
// full fee would be promising money the customer never paid.
const refundable = computed(
  () => !!booking.value?.delivery_fee_wallet_applied && !isZeroMoney(booking.value.delivery_fee_wallet_applied),
)

const method = ref(route.query.method === 'delivery' ? 'delivery' : 'pickup')
const addressId = ref(null)
const payWithWallet = ref(false)
const quote = ref(null)
const saving = ref(false)
const errors = ref({})
const submitError = ref('')

const loadQuote = async () => {
  if (!available.value || method.value !== 'delivery') { quote.value = null; return }
  try {
    const res = await actions.deliveryQuote({ use_wallet: payWithWallet.value ? 1 : 0, address_id: addressId.value ?? undefined })
    quote.value = res?.data ?? null
  } catch (err) {
    const normalized = normalizeApiError(err)
    errors.value = normalized.errors
    quote.value = null
  }
}

watch([method, addressId, payWithWallet, available], loadQuote, { immediate: true })

const choose = async () => {
  saving.value = true
  errors.value = {}
  submitError.value = ''
  try {
    const res = await actions.chooseDelivery({
      method: method.value,
      ...(method.value === 'delivery' ? { address_id: addressId.value, use_wallet: payWithWallet.value } : {}),
    })
    toast.success(res?.message ?? '')
    await Promise.all([refreshIdentity(), refreshWallet()])
    await navigateTo(`/bookings/${route.params.id}`)
  } catch (err) {
    const normalized = normalizeApiError(err)
    errors.value = normalized.errors
    if (!Object.keys(normalized.errors).length) submitError.value = normalized.message
  } finally {
    saving.value = false
  }
}

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/bookings', label: t('bookings_title', 'My bookings', 'ورشاتي') },
  { to: `/bookings/${route.params.id}`, label: booking.value?.workshop_title ?? '' },
  { label: t('delivery_title', 'Your finished piece', 'استلام قطعتك') },
])

useSeoMeta({ title: () => t('delivery_title', 'Your finished piece', 'استلام قطعتك'), robots: 'noindex' })
</script>
