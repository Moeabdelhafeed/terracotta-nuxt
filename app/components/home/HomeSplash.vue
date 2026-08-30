<template>
  <Teleport to="body">
    <div v-if="visible" ref="root" class="fixed inset-0 z-[100]" aria-hidden="true">
      <!--
        One SVG does the whole splash. The terracotta ground is an oversized rect masked by
        the vase, so the shape is punched straight out of it; that hole is then scaled up
        until it swallows the panel and the site is simply there behind it.

        The coordinate space is a 1000-unit square (`slice`, so it always covers), with the
        mark placed small at its centre — the mark's own 106x148 box as the viewBox would
        blow it up to fill the screen. Each shape sits in a plain wrapper `<g>` so GSAP can
        own that element's transform without fighting the placement transform beneath it.
      -->
      <svg
        class="h-full w-full text-brand-terracotta"
        viewBox="0 0 1000 1000"
        preserveAspectRatio="xMidYMid slice"
      >
        <defs>
          <mask id="splash-vase" maskUnits="userSpaceOnUse" x="-2000" y="-2000" width="5000" height="5000">
            <rect x="-2000" y="-2000" width="5000" height="5000" fill="white" />
            <!-- Black paints the hole. Hidden until the outline has finished drawing. -->
            <g ref="hole" opacity="0">
              <g :transform="PLACE">
                <path d="M30.1201 0.5H75.041C76.1164 0.50032 76.7051 1.72902 76.0498 2.55762C68.0026 12.6192 63.7101 24.5259 70.5039 36.7139V36.7129C73.0236 41.2443 76.5923 45.042 80.6279 48.2705C82.6547 49.8919 84.8721 51.2448 87.0176 52.6084C89.1739 53.9789 91.267 55.3652 93.1104 57.0762V57.0771C98.4353 62.0101 102.297 68.5265 103.985 75.5908L104.142 76.2764C106.421 86.7653 100.74 96.4015 93.0449 103.32L92.2939 103.981C89.1142 106.725 85.6242 109.106 81.9609 111.171C81.8967 111.206 81.8004 111.264 81.6797 111.339L81.2559 111.605C79.2994 112.827 79.898 115.855 82.1973 116.194C86.2394 116.792 90.3976 115.827 93.4053 114.797L93.9912 114.59C95.1367 114.174 96.2592 115.215 95.9688 116.36L95.9365 116.472C91.8044 128.833 84.7425 136.515 76.8418 141.114C68.9305 145.719 60.1482 147.25 52.5703 147.25H51.5791C44.2359 147.119 35.8746 145.528 28.3096 141.124C20.4088 136.525 13.3469 128.843 9.21484 116.481L9.21387 116.479L9.18066 116.368C8.88489 115.228 10.0009 114.182 11.1602 114.6V114.601C14.1983 115.701 18.651 116.842 22.9521 116.204L22.9531 116.205C25.2515 115.866 25.8511 112.841 23.8984 111.618H23.8994C23.5641 111.405 23.3095 111.252 23.208 111.191L23.1963 111.185L22.5107 110.793C19.0953 108.819 15.8399 106.565 12.8574 103.991C4.78672 97.0323 -1.34355 87.1141 1.00879 76.2871C2.60648 68.9693 6.54348 62.179 12.04 57.0869H12.041C13.8099 55.4454 15.8087 54.1127 17.8711 52.8057C19.666 51.6681 21.5175 50.5441 23.2646 49.2637L24.0068 48.7051C27.7262 45.828 31.0758 42.4183 33.6133 38.4229L34.1104 37.6162C37.3863 32.1267 39.0246 25.4379 37.9531 19.042L37.8408 18.4238C36.8039 13.1431 33.0871 7.6314 29.7686 3.38867L29.1113 2.55762C28.4578 1.73114 29.0521 0.500357 30.1201 0.5Z" fill="black" />
              </g>
            </g>
          </mask>
        </defs>

        <rect
          x="-2000"
          y="-2000"
          width="5000"
          height="5000"
          fill="currentColor"
          mask="url(#splash-vase)"
        />

        <!-- The visible mark, drawn then filled, before it hands over to the mask. -->
        <g ref="markGroup">
          <g :transform="PLACE">
            <path ref="mark" d="M30.1201 0.5H75.041C76.1164 0.50032 76.7051 1.72902 76.0498 2.55762C68.0026 12.6192 63.7101 24.5259 70.5039 36.7139V36.7129C73.0236 41.2443 76.5923 45.042 80.6279 48.2705C82.6547 49.8919 84.8721 51.2448 87.0176 52.6084C89.1739 53.9789 91.267 55.3652 93.1104 57.0762V57.0771C98.4353 62.0101 102.297 68.5265 103.985 75.5908L104.142 76.2764C106.421 86.7653 100.74 96.4015 93.0449 103.32L92.2939 103.981C89.1142 106.725 85.6242 109.106 81.9609 111.171C81.8967 111.206 81.8004 111.264 81.6797 111.339L81.2559 111.605C79.2994 112.827 79.898 115.855 82.1973 116.194C86.2394 116.792 90.3976 115.827 93.4053 114.797L93.9912 114.59C95.1367 114.174 96.2592 115.215 95.9688 116.36L95.9365 116.472C91.8044 128.833 84.7425 136.515 76.8418 141.114C68.9305 145.719 60.1482 147.25 52.5703 147.25H51.5791C44.2359 147.119 35.8746 145.528 28.3096 141.124C20.4088 136.525 13.3469 128.843 9.21484 116.481L9.21387 116.479L9.18066 116.368C8.88489 115.228 10.0009 114.182 11.1602 114.6V114.601C14.1983 115.701 18.651 116.842 22.9521 116.204L22.9531 116.205C25.2515 115.866 25.8511 112.841 23.8984 111.618H23.8994C23.5641 111.405 23.3095 111.252 23.208 111.191L23.1963 111.185L22.5107 110.793C19.0953 108.819 15.8399 106.565 12.8574 103.991C4.78672 97.0323 -1.34355 87.1141 1.00879 76.2871C2.60648 68.9693 6.54348 62.179 12.04 57.0869H12.041C13.8099 55.4454 15.8087 54.1127 17.8711 52.8057C19.666 51.6681 21.5175 50.5441 23.2646 49.2637L24.0068 48.7051C27.7262 45.828 31.0758 42.4183 33.6133 38.4229L34.1104 37.6162C37.3863 32.1267 39.0246 25.4379 37.9531 19.042L37.8408 18.4238C36.8039 13.1431 33.0871 7.6314 29.7686 3.38867L29.1113 2.55762C28.4578 1.73114 29.0521 0.500357 30.1201 0.5Z" stroke="#fff" stroke-width="1.5" fill="#fff" fill-opacity="0" />
          </g>
        </g>
      </svg>
    </div>
  </Teleport>
</template>

<script setup>
/**
 * The launch screen: the mark draws itself on the terracotta ground, fills, then becomes a
 * hole in that ground and opens outward until the site is revealed through it.
 *
 * Shown once per page load, home page only. The guard is a module-level flag rather than
 * component state: a full refresh re-evaluates the module and the splash returns, while
 * navigating away and back within the session leaves it alone.
 *
 * It renders during SSR too, so the first paint is the splash rather than a flash of the
 * page underneath. Every exit path clears `visible` — a failed animation must never leave
 * the site sealed behind an overlay, hence the timeout fallback as well.
 */
const SAFETY_MS = 5500

// Centre the 106x148 mark in the 1000-unit space, at a size that reads as a logo.
const PLACE = 'translate(500 500) scale(0.7) translate(-53 -74)'
// The hole grows from the centre of that placement, in the SVG's user units.
const ORIGIN = '500 500'

// Reset on every fresh page load, kept across client-side navigation.
let alreadyShown = false

const visible = ref(!alreadyShown)
const root = ref()
const mark = ref()
const markGroup = ref()
const hole = ref()

let safety = null

const dismiss = () => { visible.value = false }

onMounted(async () => {
  if (alreadyShown) {
    // Arrived by client-side navigation: nothing to show.
    visible.value = false
    return
  }

  alreadyShown = true

  // Someone who asked for less motion still gets the page, just without the wait.
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    visible.value = false
    return
  }

  // Whatever happens to the animation, the overlay leaves.
  safety = setTimeout(dismiss, SAFETY_MS)

  const gsap = useGSAP()
  const { DrawSVGPlugin } = await import('gsap/all')
  gsap.registerPlugin(DrawSVGPlugin)

  await nextTick()
  if (!mark.value || !hole.value) return dismiss()

  gsap.timeline({ onComplete: dismiss })
    .from(mark.value, { drawSVG: '0%', duration: 1.2, ease: 'power1.inOut' })
    // `fill: none` -> a colour cannot interpolate, so the fill is carried from the start
    // and only its opacity is animated.
    .to(mark.value, { fillOpacity: 1, duration: 0.5, ease: 'power2.out' }, '-=0.2')
    // Hand the shape over to the mask. Crossfaded rather than swapped in one frame — a
    // hard cut from filled mark to window is what read as a jump.
    .to(hole.value, { opacity: 1, duration: 0.25, ease: 'none' }, '+=0.1')
    .to(markGroup.value, { opacity: 0, duration: 0.25, ease: 'none' }, '<')
    // Open it up from the middle of the vase. `power2.inOut` over a longer beat: area
    // grows with the square of the scale, so a sharper ease reads as a snap.
    .to(hole.value, { scale: 34, svgOrigin: ORIGIN, duration: 1.6, ease: 'power2.inOut' }, '-=0.05')
    // The last of the terracotta goes with a fade, so removing the overlay is never a cut.
    .to(root.value, { opacity: 0, duration: 0.45, ease: 'power1.out' }, '-=0.45')
})

onBeforeUnmount(() => clearTimeout(safety))
</script>
