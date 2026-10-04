<template>
  <div v-if="show" class="fixed inset-0 z-[100] overflow-hidden">
    <!-- Physical left/right, not logical start/end: the halves are a seam down the middle
         of the screen, and in RTL a logical grid would swap them under the mark. -->
    <!-- A soft shadow on each half's seam edge while they part, in the brand ink: the halves
         are the same colour as the page they uncover, and without it they melt into it.
         Not while closed — the right half paints over the left's shadow, so a closed
         curtain would show it on one side of the seam only. -->
    <div
      ref="left"
      class="absolute inset-y-0 left-0 w-1/2"
      :class="{ 'shadow-[12px_0_32px_-4px_rgba(41,8,2,0.25)]': parting }"
      :style="{ backgroundColor: color }"
    />
    <div
      ref="right"
      class="absolute inset-y-0 right-0 w-1/2"
      :class="{ 'shadow-[-12px_0_32px_-4px_rgba(41,8,2,0.25)]': parting }"
      :style="{ backgroundColor: color }"
    />

    <div class="absolute inset-0 grid place-items-center">
      <button
        ref="knob"
        type="button"
        class="cursor-pointer p-6 transition-transform duration-300 hover:scale-110 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/70"
        :aria-label="label"
        @click="open"
      >
        <AppMedia v-if="logo" :src="logo" alt="" class="h-28 w-auto object-contain sm:h-40" />
      </button>
    </div>

    <p ref="hint" class="pointer-events-none absolute inset-x-0 bottom-16 text-center text-sm text-white/80">
      {{ label }}
    </p>
  </div>
</template>

<script setup>
/**
 * A curtain over the page that the visitor opens themselves: two halves with the mark on
 * the seam, which slide apart on a tap.
 *
 * Rendered during SSR too, so the first paint is the curtain rather than a flash of the
 * page behind it. Nothing here fetches or blocks — the page underneath has already
 * rendered by the time anyone taps.
 */
const props = defineProps({
  /** Read out to screen readers and shown under the mark. */
  label: { type: String, required: true },
  color: { type: String, default: '#FC8B8B' },
})

const emit = defineEmits(['opened'])

const { mediaAsset } = useMedia('web', 'branding')

// The light mark: both halves are a colour, never white.
const logo = computed(() => mediaAsset('logo_light', '/logo-light.png'))

const show = ref(true)
const left = ref(null)
const right = ref(null)
const knob = ref(null)
const hint = ref(null)

// The page behind must not scroll under the curtain.
onMounted(() => document.body.classList.add('overflow-hidden'))
const release = () => document.body.classList.remove('overflow-hidden')
onBeforeUnmount(release)

let opening = false
const parting = ref(false)

const open = () => {
  if (opening) return
  opening = true

  const done = () => {
    show.value = false
    release()
    emit('opened')
  }

  // Somebody who asked for less motion gets the page, not a performance.
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    done()
    return
  }

  parting.value = true
  const tl = useGSAP().timeline()

  // The mark goes first — it is the thing being pressed, and it would otherwise hang in
  // the gap the halves leave behind.
  tl.to([knob.value, hint.value], { opacity: 0, scale: 0.9, duration: 0.35, ease: 'power2.in' })
    .to(left.value, { xPercent: -120, duration: 1, ease: 'power2.inOut' }, 0.15)
    .to(right.value, { xPercent: 120, duration: 1, ease: 'power2.inOut', onComplete: done }, '<')
}
</script>
