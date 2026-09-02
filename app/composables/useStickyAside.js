import { ScrollSmoother, ScrollTrigger } from 'gsap/all'

/**
 * Holds a side column in place while the long column beside it scrolls past.
 *
 * `position: sticky` cannot do this here: ScrollSmoother moves #smooth-content with a
 * transform, and a transformed ancestor makes a sticky child behave like a static one.
 * So the column is pinned by ScrollTrigger instead.
 *
 * The wait for the smoother is the crux. Vue runs a page's `onMounted` *before* its
 * layout's, and the layout is where ScrollSmoother is created — a pin built in that gap
 * measures itself against the window rather than the smoothed content, gets its
 * spacer, and then scrolls away anyway.
 *
 * @param {import('vue').Ref<HTMLElement|null>} aside   the column to hold
 * @param {import('vue').Ref<HTMLElement|null>} content the column whose end releases it
 * @param {import('vue').Ref<unknown>} ready            the fetched record the markup waits on
 */
export const useStickyAside = (aside, content, ready) => {
  let mm = null

  const smootherReady = () => new Promise((resolve) => {
    // Reduced motion means no smoother is ever created; pinning against the window is
    // correct in that case, so this gives up rather than waiting forever.
    let frames = 30
    const check = () => {
      if (ScrollSmoother.get() || frames-- <= 0) resolve()
      else requestAnimationFrame(check)
    }
    check()
  })

  const build = () => {
    if (mm || !aside.value || !content.value) return

    const gsap = useGSAP()
    gsap.registerPlugin(ScrollTrigger)
    mm = gsap.matchMedia()

    // Desktop only: in one column the aside sits under the content and has nothing to
    // hold against.
    mm.add('(min-width: 1024px)', () => {
      const trigger = ScrollTrigger.create({
        trigger: aside.value,
        start: 'top 32px',
        endTrigger: content.value,
        // Released when the content column's bottom reaches the foot of the held card,
        // which is what `position: sticky` does. Measuring against the viewport bottom
        // instead breaks on a short page: the end lands above the start and the pin
        // never engages at all.
        end: () => `bottom ${aside.value.offsetHeight + 32}px`,
        invalidateOnRefresh: true,
        pin: aside.value,
        pinSpacing: false,
      })

      return () => trigger.kill()
    })
  }

  onMounted(() => {
    // The markup is behind `v-if`, so on a client-side navigation the refs only exist
    // once the fetch resolves.
    watch(ready, async (value) => {
      if (!value) return
      await nextTick()
      await smootherReady()
      build()
      ScrollTrigger.refresh()
    }, { immediate: true })

    // Images decide where the content column ends, and they land after the pin is built.
    window.addEventListener('load', ScrollTrigger.refresh)
  })

  onBeforeUnmount(() => {
    window.removeEventListener('load', ScrollTrigger.refresh)
    mm?.revert()
    mm = null
  })
}
