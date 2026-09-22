/**
 * Re-measure every pinned section when the page grows underneath it.
 *
 * ScrollTrigger records a pin's start/end once, when the component mounts. Several home
 * sections above the pinned ones only appear *after* that: `HomeLiveStrip` fetches with
 * `lazy: true` and is `v-if`'d on having a live booking or order, and `HomeBooking` sets
 * its greeting in `onMounted`. When one of them drops in, everything below it moves down
 * by that section's height — but the pins are still holding the offsets measured before
 * it existed, so a pinned panel sits fixed at the wrong place. On the gallery that reads
 * as the wall pinning near the bottom of the screen with a band of empty page above it.
 *
 * ScrollTrigger refreshes itself on resize and on load; neither covers a section that
 * renders later, which is why this watches the document's own height.
 */
export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.hook('app:mounted', async () => {
    const { ScrollTrigger } = await import('gsap/all')

    let height = document.documentElement.scrollHeight
    let timer = null
    // `refresh()` rewrites the pin spacers, which changes the height again — without this
    // the observer would answer its own write and loop.
    let refreshing = false

    ScrollTrigger.addEventListener('refreshInit', () => { refreshing = true })
    ScrollTrigger.addEventListener('refresh', () => {
      height = document.documentElement.scrollHeight
      refreshing = false
    })

    const observer = new ResizeObserver(() => {
      if (refreshing) return
      const next = document.documentElement.scrollHeight
      if (next === height) return
      height = next

      clearTimeout(timer)
      // Coalesced: a section arriving brings its images with it, each landing separately.
      timer = setTimeout(() => {
        if (ScrollTrigger.getAll().length) ScrollTrigger.refresh()
      }, 150)
    })

    observer.observe(document.body)
  })
})
