<template>
  <span class="inline-flex items-center rounded-md px-3 py-1 text-xs font-medium" :class="tone" :data-state="state">
    {{ label }}
  </span>
</template>

<script setup>
/** The seven booking statuses plus the four delivery stages, as one badge. */
const props = defineProps({
  booking: { type: Object, required: true },
})

const state = computed(() => bookingState(props.booking))

const labels = useBookingStatusLabels()

const tones = {
  pending_payment: 'bg-amber-100 text-amber-800',
  confirmed: 'bg-brand-green/15 text-brand-green',
  attending: 'bg-brand-green/15 text-brand-green',
  absent: 'bg-muted text-muted-foreground',
  preparing: 'bg-brand-terracotta/10 text-brand-terracotta',
  ready: 'bg-brand-blush/40 text-brand-terracotta',
  awaiting_pickup: 'bg-brand-blush/40 text-brand-terracotta',
  getting_ready: 'bg-brand-terracotta/10 text-brand-terracotta',
  on_the_way: 'bg-brand-terracotta/10 text-brand-terracotta',
  delivered: 'bg-brand-green/15 text-brand-green',
  cancelled: 'bg-destructive/10 text-destructive',
}

const label = computed(() => labels.value[state.value] ?? state.value)
const tone = computed(() => tones[state.value] ?? 'bg-muted text-muted-foreground')
</script>
