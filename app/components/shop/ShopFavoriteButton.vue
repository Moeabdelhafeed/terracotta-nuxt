<template>
  <button
    type="button"
    class="flex items-center justify-center rounded-full border bg-background/90 text-brand-rust shadow-sm backdrop-blur transition-transform hover:scale-110 active:scale-95"
    :class="[sizeClass, active ? 'border-brand-rust/40' : 'border-border']"
    :aria-pressed="active"
    :aria-label="active ? t('unfavorite', 'Remove from favorites', 'إزالة من المفضلة') : t('favorite', 'Add to favorites', 'إضافة إلى المفضلة')"
    :disabled="busy"
    @click.prevent.stop="onToggle"
  >
    <LucideHeart class="size-[55%]" :class="active ? 'fill-brand-rust' : ''" />
  </button>
</template>

<script setup>
const props = defineProps({
  product: { type: Object, required: true },
  size: { type: String, default: 'md' },
})

const emit = defineEmits(['toggled'])

const { t } = useLang('web', 'shop')
const { isFavorited, toggle } = useFavorites()

const active = computed(() => isFavorited(props.product))
const sizeClass = computed(() => (props.size === 'lg' ? 'size-12' : 'size-9'))
const busy = ref(false)

const onToggle = async () => {
  busy.value = true
  try {
    emit('toggled', await toggle(props.product))
  } finally {
    busy.value = false
  }
}
</script>
