<template>
  <Teleport to="body">
    <div
      v-if="open"
      ref="panel"
      data-animated
      class="fixed inset-0 z-[60] flex flex-col bg-black/50 duration-200 animate-in fade-in"
      role="dialog"
      aria-modal="true"
      :aria-label="alt"
      tabindex="-1"
      data-test="lightbox"
      @keydown="onKey"
    >
      <header class="flex shrink-0 items-center justify-between gap-4 p-4 text-white">
        <button
          type="button"
          class="flex size-10 items-center justify-center rounded-control bg-white/10 transition-colors hover:bg-white/20"
          :aria-label="t('close', 'Close', 'إغلاق', { subGroup: 'general' })"
          data-test="lightbox-close"
          @click="close"
        >
          <LucideX class="size-5" />
        </button>

        <span v-if="items.length > 1" class="text-sm font-medium tabular-nums" dir="ltr" data-test="lightbox-counter">
          {{ index + 1 }} / {{ items.length }}
        </span>
      </header>

      <!-- The backdrop around the picture closes; the picture itself does not. -->
      <div
        class="flex min-h-0 flex-1 items-center justify-center p-4 pb-10"
        @click.self="close"
        @touchstart.passive="onTouchStart"
        @touchend.passive="onTouchEnd"
      >
        <AppMedia
          :key="index"
          :src="items[index]"
          :alt="alt"
          class="max-h-full max-w-full object-contain"
        />
      </div>

      <template v-if="items.length > 1">
        <button
          type="button"
          class="absolute top-1/2 flex size-11 -translate-y-1/2 items-center justify-center rounded-control bg-white/10 text-white transition-colors start-3 hover:bg-white/20"
          :aria-label="t('previous', 'Previous', 'السابق', { subGroup: 'general' })"
          data-test="lightbox-prev"
          @click="step(-1)"
        >
          <LucideChevronLeft class="size-6 rtl:-scale-x-100" />
        </button>
        <button
          type="button"
          class="absolute top-1/2 flex size-11 -translate-y-1/2 items-center justify-center rounded-control bg-white/10 text-white transition-colors end-3 hover:bg-white/20"
          :aria-label="t('next', 'Next', 'التالي', { subGroup: 'general' })"
          data-test="lightbox-next"
          @click="step(1)"
        >
          <LucideChevronRight class="size-6 rtl:-scale-x-100" />
        </button>
      </template>
    </div>
  </Teleport>
</template>

<script setup>
/**
 * Full-screen viewer for a run of backend media — gallery album items, a product's
 * photographs, a piece's angles. One component for all of them, the way the app has one
 * `showPickerLightbox`.
 *
 * `v-model` is the index being viewed, or `null` for closed:
 *
 *   <AppLightbox v-model="viewing" :items="album.items" :alt="album.title" />
 *   <button @click="viewing = i">…</button>
 *
 * Items are anything `<AppMedia>` takes: a `{ type, image|video|file }` wrapper, a bare
 * Image object, or a URL string — so a video album page plays in place rather than
 * showing its poster.
 */
const props = defineProps({
  modelValue: { type: Number, default: null },
  items: { type: Array, default: () => [] },
  alt: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])

const { t, dir } = useLang('web', 'general')

const open = computed(() => props.modelValue !== null && props.items.length > 0)
const index = computed(() => Math.min(Math.max(props.modelValue ?? 0, 0), props.items.length - 1))

const close = () => emit('update:modelValue', null)
const step = (delta) => {
  const count = props.items.length
  emit('update:modelValue', (index.value + delta + count) % count)
}

// Arrow keys follow the reading direction: in RTL the next picture is to the left.
const onKey = (event) => {
  const forward = dir.value === 'rtl' ? 'ArrowLeft' : 'ArrowRight'
  const back = dir.value === 'rtl' ? 'ArrowRight' : 'ArrowLeft'
  if (event.key === 'Escape') close()
  else if (event.key === forward) step(1)
  else if (event.key === back) step(-1)
  else return
  event.preventDefault()
}

const startX = ref(0)
const onTouchStart = (event) => { startX.value = event.changedTouches[0].clientX }
const onTouchEnd = (event) => {
  const dx = event.changedTouches[0].clientX - startX.value
  if (Math.abs(dx) < 50) return
  // A swipe towards the start edge advances, whichever edge that is.
  step(dir.value === 'rtl' ? (dx > 0 ? 1 : -1) : (dx < 0 ? 1 : -1))
}

// The dialog owns the keyboard while it is up, and the page behind it must not scroll.
const panel = ref(null)
const locked = useScrollLock(import.meta.client ? document.body : null)
watch(open, async (isOpen) => {
  locked.value = isOpen
  if (!isOpen) return
  await nextTick()
  panel.value?.focus()
}, { immediate: true })
onScopeDispose(() => { locked.value = false })
</script>
