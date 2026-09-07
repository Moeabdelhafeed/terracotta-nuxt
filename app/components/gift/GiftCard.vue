<template>
  <NuxtLink
    :to="`/gifts/${gift.id}`"
    class="flex flex-col gap-4 rounded-3xl border bg-card p-6 transition-colors hover:border-brand-rust/40 sm:p-8"
  >
    <div class="flex items-start justify-between gap-4">
      <div class="min-w-0">
        <p class="text-xs uppercase tracking-[0.2em] text-muted-foreground">
          {{ t('gift_recipient', 'For', 'المهدى له') }}
        </p>
        <p class="mt-1 truncate font-display text-xl font-semibold">{{ gift.recipient_name }}</p>
        <p v-if="gift.recipient_phone" class="mt-0.5 truncate text-sm text-muted-foreground" dir="ltr">{{ gift.recipient_phone }}</p>
      </div>
      <p class="shrink-0 font-display text-2xl font-black text-primary">{{ format(gift.amount) }}</p>
    </div>

    <p v-if="gift.message" class="line-clamp-2 text-sm text-muted-foreground">“{{ gift.message }}”</p>

    <div class="flex flex-wrap items-center gap-2">
      <span class="rounded-full px-3 py-1 text-xs font-medium" :class="statusClass">{{ statusLabel }}</span>

      <span
        v-if="gift.payment_status === 'refunded'"
        class="rounded-full bg-brand-mist px-3 py-1 text-xs font-medium text-muted-foreground"
      >{{ t('gift_refunded', 'Refunded', 'مسترد') }}</span>

      <span
        v-if="gift.is_redeemed"
        class="rounded-full bg-brand-green/10 px-3 py-1 text-xs font-medium text-brand-green"
      >{{ t('gift_redeemed', 'Redeemed', 'تم الاستخدام') }}</span>

      <span class="ms-auto text-xs text-muted-foreground">{{ formatDateOnly(gift.created_at) }}</span>
    </div>
  </NuxtLink>
</template>

<script setup>
/**
 * One row of the buyer's gift list. Redemption is not a status — it is `is_redeemed` on
 * top of a `paid` gift — so the two are separate badges rather than one.
 */
const props = defineProps({
  gift: { type: Object, required: true },
})

const { t } = useLang('web', 'gifts')
const { format } = usePrice()
const { formatDateOnly } = useDateFormat()

const statusLabel = computed(() => ({
  awaiting_payment: t('gift_status_awaiting', 'Awaiting payment', 'بانتظار الدفع'),
  paid: t('gift_status_paid', 'Paid', 'مدفوعة'),
  cancelled: t('gift_status_cancelled', 'Cancelled', 'ملغاة'),
}[props.gift.status] ?? props.gift.status))

const statusClass = computed(() => ({
  awaiting_payment: 'bg-brand-blush/40 text-brand-rust',
  paid: 'bg-brand-green/10 text-brand-green',
  cancelled: 'bg-brand-mist text-muted-foreground',
}[props.gift.status] ?? 'bg-brand-mist text-muted-foreground'))
</script>
