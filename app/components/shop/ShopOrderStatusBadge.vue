<template>
  <span class="inline-flex items-center rounded-md px-2.5 py-1 text-xs font-medium" :class="tone">{{ label }}</span>
</template>

<script setup>
const props = defineProps({
  status: { type: String, required: true },
})

const { t } = useLang('web', 'shop')

const label = computed(() => ({
  awaiting_payment: t('status_awaiting_payment', 'Awaiting payment', 'بانتظار الدفع'),
  pending: t('status_pending', 'Confirmed', 'مؤكد'),
  preparing: t('status_preparing', 'Preparing', 'قيد التحضير'),
  out_for_delivery: t('status_out_for_delivery', 'Out for delivery', 'خرج للتوصيل'),
  completed: t('status_completed', 'Delivered', 'مسلّم'),
  cancelled: t('status_cancelled', 'Cancelled', 'ملغي'),
}[props.status] ?? props.status))

const tone = computed(() => ({
  awaiting_payment: 'bg-brand-blush/40 text-brand-rust',
  pending: 'bg-brand-green/10 text-brand-green',
  preparing: 'bg-brand-mist text-brand-ink',
  out_for_delivery: 'bg-brand-mist text-brand-ink',
  completed: 'bg-brand-green text-white',
  cancelled: 'bg-destructive/10 text-destructive',
}[props.status] ?? 'bg-brand-mist text-brand-ink'))
</script>
