<template>
  <div class="inline-flex items-center gap-1 rounded-control border bg-card p-1" :class="{ 'opacity-50': disabled }">
    <button
      type="button"
      class="flex size-10 items-center justify-center rounded-field text-foreground transition-colors hover:bg-brand-mist disabled:cursor-not-allowed disabled:opacity-40"
      :aria-label="t('decrease', 'Decrease quantity', 'تقليل الكمية')"
      :disabled="disabled || quantity <= min"
      @click="set(quantity - 1)"
    >
      <LucideMinus class="size-4" />
    </button>

    <span class="min-w-8 text-center text-sm font-medium tabular-nums" aria-live="polite">
      {{ t('quantity_n', 'Qty :n', 'عدد :n', { n: quantity }) }}
    </span>

    <button
      type="button"
      class="flex size-10 items-center justify-center rounded-field text-foreground transition-colors hover:bg-brand-mist disabled:cursor-not-allowed disabled:opacity-40"
      :aria-label="t('increase', 'Increase quantity', 'زيادة الكمية')"
      :disabled="disabled || quantity >= max"
      @click="set(quantity + 1)"
    >
      <LucidePlus class="size-4" />
    </button>
  </div>
</template>

<script setup>
/** `max` is the product's `max_quantity` — `min(stock, 100)` when tracked, 100 otherwise. */
const props = defineProps({
  min: { type: Number, default: 1 },
  max: { type: Number, default: 100 },
  disabled: { type: Boolean, default: false },
})

const quantity = defineModel({ type: Number, default: 1 })
const { t } = useLang('web', 'shop')

const set = (value) => {
  quantity.value = Math.min(props.max, Math.max(props.min, value))
}
</script>
