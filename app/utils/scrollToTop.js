/**
 * Back to the top, whichever thing owns the scroll.
 *
 * ScrollSmoother transforms `#smooth-content` while the window stays where it is, so
 * where it runs it is the only thing that can move the page. It does not run on a phone
 * (see the default layout) or under `prefers-reduced-motion`, and there the window owns
 * the scroll and has to be told directly — otherwise paging or a route change leaves the
 * reader wherever the last page had them.
 */
export const scrollToTop = async (smooth = false) => {
  const { ScrollSmoother } = await import('gsap/all')
  const smoother = ScrollSmoother.get?.()

  if (smoother) return smoother.scrollTo(0, smooth)

  window.scrollTo({ top: 0, behavior: smooth ? 'smooth' : 'auto' })
}
