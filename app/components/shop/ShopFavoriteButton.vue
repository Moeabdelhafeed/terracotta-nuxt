<template>
  <button
    type="button"
    class="flex items-center justify-center text-brand-blush transition-transform hover:scale-110 active:scale-95"
    :class="[sizeClass, pill ? 'rounded-[6px] bg-card/35 backdrop-blur' : 'rounded-control hover:bg-brand-blush/10']"
    :aria-pressed="active"
    :aria-label="active ? t('unfavorite', 'Remove from favorites', 'إزالة من المفضلة') : t('favorite', 'Add to favorites', 'إضافة إلى المفضلة')"
    :disabled="busy"
    @click.prevent.stop="onToggle"
  >
    <LucideHeart class="size-[55%]" :class="active ? 'fill-current' : ''" />
  </button>
</template>

<script setup>
/**
 * The app draws this two ways: a translucent pill over a card's photograph, and a bare
 * heart beside the title on the detail page — where a pill on a card background is a
 * square of nothing. Filled vs outlined carries the state in both.
 */
const props = defineProps({
  product: { type: Object, required: true },
  size: { type: String, default: 'md' },
})

const emit = defineEmits(['toggled'])

const { t } = useLang('web', 'shop')
const { isFavorited, toggle } = useFavorites()

const active = computed(() => isFavorited(props.product))
const pill = computed(() => props.size !== 'lg')
const sizeClass = computed(() => (props.size === 'lg' ? 'size-12' : 'size-10'))
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
