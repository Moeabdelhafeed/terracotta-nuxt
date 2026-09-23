<template>
  <div class="relative overflow-hidden rounded-card border bg-brand-container" :class="frame">
    <AppImage v-if="current" :src="current" :alt="alt" class="size-full object-cover" />

    <!-- The site's carousel arrows, to the letter — the same ones the home banners use.
         They mirror with the language: in Arabic "onward" is to the left. -->
    <template v-if="items.length > 1">
      <button
        type="button"
        class="absolute top-1/2 z-10 flex size-11 -translate-y-1/2 items-center justify-center rounded-xl border bg-background/90 text-primary shadow-sm backdrop-blur transition-colors hover:bg-background ltr:left-3 rtl:right-3"
        :aria-label="t('previous', 'Previous', 'السابق', { subGroup: 'general' })"
        data-test="shot-prev"
        @click="step(-1)"
      >
        <LucideChevronLeft class="size-5 rtl:rotate-180" />
      </button>

      <button
        type="button"
        class="absolute top-1/2 z-10 flex size-11 -translate-y-1/2 items-center justify-center rounded-xl border bg-background/90 text-primary shadow-sm backdrop-blur transition-colors hover:bg-background ltr:right-3 rtl:left-3"
        :aria-label="t('next', 'Next', 'التالي', { subGroup: 'general' })"
        data-test="shot-next"
        @click="step(1)"
      >
        <LucideChevronRight class="size-5 rtl:rotate-180" />
      </button>
    </template>

    <!--
      Where you are in the set, ON the photograph and drawn as the studio's own mark
      rather than a row of dots. The current one is the only solid one.
    -->
    <ul
      v-if="items.length > 1"
      class="pointer-events-none absolute inset-x-0 bottom-4 z-10 flex items-center justify-center"
      data-test="shot-indicator"
    >
      <li v-for="(shot, index) in items" :key="index" class="pointer-events-auto">
        <button
          type="button"
          class="flex items-center justify-center px-1 py-2 text-white transition active:scale-90"
          :aria-label="t('view_photo_n', 'Photo :n', 'الصورة :n', { n: index + 1 })"
          :aria-current="index === activeIndex ? 'true' : undefined"
          :data-shot="index"
          @click="activeIndex = index"
        >
          <BrandMark
            class="h-8 w-auto transition-opacity duration-200"
            :class="index === activeIndex ? 'opacity-100' : 'opacity-45'"
          />
        </button>
      </li>
    </ul>
  </div>
</template>

<script setup>
/**
 * A set of photographs of one thing: the shop's pieces, the studio's materials, a
 * workshop. Arrows, the studio's mark for where you are, and every shot fetched before
 * it is asked for.
 *
 * WHICH shot, not which object. This started life inside the product page holding the
 * chosen image itself and asking `items.includes(it)` — an identity test that fails the
 * moment the record is refetched, so the view fell back to the first photograph and the
 * picker looked like it did nothing at all. An index cannot go stale that way.
 */
const props = defineProps({
  items: { type: Array, default: () => [] },
  alt: { type: String, default: '' },
  /** The shape of the frame. A piece is square; a workshop is a room, so it is wide. */
  frame: { type: String, default: 'aspect-square' },
})

const { t } = useLang('web', 'shop')

const activeIndex = ref(0)
const current = computed(() => props.items[activeIndex.value] ?? props.items[0] ?? null)

/** Wraps, so an arrow never dead-ends on the first or last photograph. */
const step = (delta) => {
  const count = props.items.length
  if (count > 1) activeIndex.value = (activeIndex.value + delta + count) % count
}

const urlOf = (item) => (typeof item === 'string' ? item : (item?.image_api ?? null))

/**
 * Every shot fetched up front, not just the one on screen.
 *
 * Without this the second photograph only starts downloading when it is asked for, so the
 * one you were looking at stays put while it arrives — the change reads as a dead button.
 * The browser cache is what actually holds them; these `Image` objects exist only to put
 * them there, which is why nothing keeps a reference.
 */
watch(
  () => props.items.map(urlOf).join(','),
  () => {
    if (!import.meta.client) return
    props.items.map(urlOf).filter(Boolean).forEach((url) => { new Image().src = url })
  },
  { immediate: true },
)

// A different subject is a different set of photographs; start it at its first.
watch(() => props.items.length && urlOf(props.items[0]), () => { activeIndex.value = 0 })
</script>
