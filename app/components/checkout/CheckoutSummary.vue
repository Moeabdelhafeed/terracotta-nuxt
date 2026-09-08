<template>
  <div class="rounded-2xl border bg-brand-mist/40 p-5">
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

      <div v-if="hasWallet" class="flex items-center justify-between gap-4 text-brand-rust">
        <dt>{{ t('summary_wallet_applied', 'Paid from wallet', 'مدفوع من المحفظة') }}</dt>
        <dd class="font-medium">−{{ format(quote.wallet_applied) }}</dd>
      </div>

      <div class="flex items-center justify-between gap-4 border-t pt-2">
        <dt class="font-semibold text-foreground">{{ t('summary_amount_due', 'Amount due', 'المبلغ المستحق') }}</dt>
        <dd class="font-display text-xl font-black text-primary sm:text-2xl">{{ format(quote.amount_due) }}</dd>
      </div>

      <p v-if="settled" class="rounded-xl bg-brand-green/10 px-3 py-2 text-xs font-medium text-brand-green">
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
 * `quote` is the `data` of any quote/create/pay response:
 * `{ subtotal, discount_amount, discount_code, delivery_fee, delivery_zone?, total_price,
 *    vat_rate?, vat_amount?, wallet_applied, amount_due }`.
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
const settled = computed(() => props.quote && isZeroMoney(props.quote.amount_due))
</script>
