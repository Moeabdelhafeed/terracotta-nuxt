<template>
  <div class="rounded-2xl border bg-card p-5">
    <h3 v-if="title" class="font-display text-base font-semibold text-foreground">{{ title }}</h3>

    <dl v-if="quote" class="mt-3 flex flex-col gap-2 text-sm" :class="{ 'mt-0': !title }">
      <div class="flex items-center justify-between gap-4">
        <dt class="text-muted-foreground">{{ t('summary_subtotal', 'Subtotal', 'المجموع الفرعي') }}</dt>
        <dd class="font-medium">{{ format(quote.subtotal) }}</dd>
      </div>

      <div v-if="hasDiscount" class="flex items-center justify-between gap-4 text-brand-green">
        <dt>
          {{ t('summary_discount', 'Discount', 'الخصم') }}
          <span v-if="quote.discount_code" class="ms-1 rounded-md bg-brand-green/10 px-2 py-0.5 text-xs font-medium uppercase">{{ quote.discount_code }}</span>
        </dt>
        <dd class="font-medium">−{{ format(quote.discount_amount) }}</dd>
      </div>

      <div v-if="showsDelivery" class="flex items-center justify-between gap-4">
        <dt class="text-muted-foreground">
          {{ t('summary_delivery', 'Delivery', 'التوصيل') }}
          <span v-if="quote.delivery_zone" class="text-xs">({{ quote.delivery_zone }})</span>
        </dt>
        <dd class="font-medium">
          <span v-if="isZeroMoney(quote.delivery_fee)" class="text-brand-green">{{ t('summary_free', 'Free', 'مجاني') }}</span>
          <span v-else>{{ format(quote.delivery_fee) }}</span>
        </dd>
      </div>

      <div class="flex items-center justify-between gap-4 border-t pt-2">
        <dt class="font-medium text-foreground">{{ t('summary_total', 'Total', 'الإجمالي') }}</dt>
        <dd class="font-display text-lg font-semibold text-foreground">{{ format(quote.total_price) }}</dd>
      </div>

      <p v-if="showsVat" class="text-xs text-muted-foreground">
        {{ t('summary_includes_vat', 'Includes VAT :amount (:rate%)', 'شامل ضريبة القيمة المضافة :amount (:rate%)', { amount: format(quote.vat_amount), rate: vatRate }) }}
      </p>

      <div v-if="hasWallet" class="flex items-center justify-between gap-4 text-primary">
        <dt>{{ t('summary_wallet_applied', 'Paid from wallet', 'مدفوع من المحفظة') }}</dt>
        <dd class="font-medium">−{{ format(quote.wallet_applied) }}</dd>
      </div>

      <!-- A placed purchase: what it cost beyond the wallet, or what came back. -->
      <div v-if="refunded" class="flex items-center justify-between gap-4 border-t pt-2" data-test="summary-refunded">
        <dt class="font-semibold text-foreground">{{ t('summary_refunded', 'Refunded to your wallet', 'مسترد إلى محفظتك') }}</dt>
        <dd class="font-display text-xl font-black text-brand-green sm:text-2xl">{{ format(quote.refunded_amount) }}</dd>
      </div>

      <div v-else-if="paid" class="flex items-center justify-between gap-4 border-t pt-2" data-test="summary-paid">
        <dt class="font-semibold text-foreground">{{ t('summary_paid', 'Paid', 'المبلغ المدفوع') }}</dt>
        <dd class="font-display text-xl font-black text-primary sm:text-2xl">{{ format(paidOutsideWallet) }}</dd>
      </div>

      <!-- A quote, or an old unpaid purchase: what is still to pay. -->
      <div v-else class="flex items-center justify-between gap-4 border-t pt-2">
        <dt class="font-semibold text-foreground">{{ t('summary_amount_due', 'Amount due', 'المبلغ المستحق') }}</dt>
        <dd class="font-display text-xl font-black text-primary sm:text-2xl">{{ format(quote.amount_due) }}</dd>
      </div>

      <p v-if="coveredByWallet" class="rounded-xl bg-brand-green/10 px-3 py-2 text-xs font-medium text-brand-green">
        {{ t('summary_settled', 'Nothing left to pay — this is covered in full.', 'لا يوجد مبلغ متبقٍ — تمت التغطية بالكامل.') }}
      </p>
    </dl>

    <div v-else class="mt-3 flex flex-col gap-2" aria-busy="true">
      <AppSkeleton v-for="n in 4" :key="n" class="h-4 w-full" />
    </div>
  </div>
</template>

<script setup>
/**
 * The one money box every payable flow shows — workshop booking, shop order, gift,
 * finished-piece delivery. Renders the seven quote fields exactly as the API returns
 * them; it never recomputes a total (the free-delivery threshold is post-discount, so a
 * coupon can re-add a fee — only the server knows).
 *
 * `quote` is the `data` of any quote or of a placed purchase:
 * `{ subtotal, discount_amount, discount_code, delivery_fee, delivery_zone?, total_price,
 *    vat_rate?, vat_amount?, wallet_applied, amount_due, payment_status?, refunded_amount? }`.
 *
 * A quote carries no `payment_status`; its last line is `amount_due`, the charge placing
 * will collect. A placed purchase does, and there `amount_due` is `"0.00"` because nothing
 * is still owed — so reading it would call a 10,000 SAR delivery "covered in full" when the
 * wallet paid 424. A paid purchase shows what it cost beyond the wallet instead
 * (`total_price − wallet_applied`, exact in halalas); a refunded one, what came back.
 */
const props = defineProps({
  quote: { type: Object, default: null },
  title: { type: String, default: '' },
})

const { t } = useLang('web', 'checkout')
const { format } = usePrice()

const hasDiscount = computed(() => !isZeroMoney(props.quote?.discount_amount))
const hasWallet = computed(() => !isZeroMoney(props.quote?.wallet_applied))
// Workshop bookings have no delivery (`null`); a `"0.00"` fee is a real "free delivery".
const showsDelivery = computed(() => props.quote?.delivery_fee !== null && props.quote?.delivery_fee !== undefined)
const vatRate = computed(() => String(props.quote?.vat_rate ?? '0').replace(/\.00$/, ''))
const showsVat = computed(() => props.quote?.vat_rate && !isZeroMoney(props.quote.vat_rate) && !isZeroMoney(props.quote.vat_amount))
const paid = computed(() => props.quote?.payment_status === 'paid')
const refunded = computed(() => props.quote?.payment_status === 'refunded' && !!props.quote.refunded_amount)
const paidOutsideWallet = computed(() =>
  fromHalalas(toHalalas(props.quote?.total_price) - toHalalas(props.quote?.wallet_applied)),
)
// "Covered in full" is only true when there really was nothing left for anything else
// to pay: a quote with nothing due, or a purchase the wallet paid for outright.
const coveredByWallet = computed(() => {
  if (!props.quote || refunded.value) return false
  return paid.value ? isZeroMoney(paidOutsideWallet.value) : isZeroMoney(props.quote.amount_due)
})
</script>
