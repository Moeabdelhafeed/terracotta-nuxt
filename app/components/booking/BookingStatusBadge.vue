<template>
  <span class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium" :class="tone" :data-state="state">
    {{ label }}
  </span>
</template>

<script setup>
/** The seven booking statuses plus the four delivery stages, as one badge. */
const props = defineProps({
  booking: { type: Object, required: true },
})

const { t } = useLang('web', 'bookings')

const state = computed(() => bookingState(props.booking))

const labels = computed(() => ({
  pending_payment: t('status_pending_payment', 'Awaiting payment', 'بانتظار الدفع'),
  confirmed: t('status_confirmed', 'Confirmed', 'مؤكد'),
  attending: t('status_attending', 'Checked in', 'حاضرة'),
  absent: t('status_absent', 'No-show', 'لم تحضر'),
  preparing: t('status_preparing', 'Being prepared', 'قيد التحضير'),
  ready: t('status_ready', 'Piece ready', 'القطعة جاهزة'),
  awaiting_pickup: t('status_awaiting_pickup', 'Ready for pickup', 'جاهزة للاستلام'),
  getting_ready: t('status_getting_ready', 'Being packed', 'قيد التغليف'),
  on_the_way: t('status_on_the_way', 'Out for delivery', 'خرجت للتوصيل'),
  delivered: t('status_delivered', 'Delivered', 'مسلمة'),
  cancelled: t('status_cancelled', 'Cancelled', 'ملغاة'),
}))

const tones = {
  pending_payment: 'bg-amber-100 text-amber-800',
  confirmed: 'bg-brand-green/15 text-brand-green',
  attending: 'bg-brand-green/15 text-brand-green',
  absent: 'bg-muted text-muted-foreground',
  preparing: 'bg-brand-mist text-brand-rust',
  ready: 'bg-brand-blush/40 text-brand-rust',
  awaiting_pickup: 'bg-brand-blush/40 text-brand-rust',
  getting_ready: 'bg-brand-mist text-brand-rust',
  on_the_way: 'bg-brand-mist text-brand-rust',
  delivered: 'bg-brand-green/15 text-brand-green',
  cancelled: 'bg-destructive/10 text-destructive',
}

const label = computed(() => labels.value[state.value] ?? state.value)
const tone = computed(() => tones[state.value] ?? 'bg-muted text-muted-foreground')
</script>
