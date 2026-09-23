/**
 * Hold the page still while a modal is open.
 *
 * Without it a scroll inside the panel chains to the page underneath once the panel hits
 * its own end, so the list behind the dialog creeps away and is somewhere else when the
 * dialog closes. Locking the body stops that; the panel keeps its own scroll.
 *
 * **ScrollSmoother has to be paused as well.** It is the thing that actually scrolls this
 * site — it transforms `#smooth-content` while the window scrolls behind it — so
 * `overflow: hidden` on the body stops nothing at all: a flick during the splash still
 * carried the reader a thousand pixels down a page they had not seen the top of. The body
 * lock is kept for the pages the smoother is not running on.
 *
 * @param {import('vue').Ref<boolean>} isOpen
 */
export const useModalScrollLock = (isOpen) => {
  if (import.meta.server) return

  const lockedBody = useScrollLock(document.body)
  const lockedRoot = useScrollLock(document.documentElement)

  const pauseSmoother = async (paused) => {
    const { ScrollSmoother } = await import('gsap/all')
    ScrollSmoother.get?.()?.paused(paused)
  }

  /**
   * Whether THIS caller is the one holding the page.
   *
   * The lock is a property of the document, and several of these live at once — the
   * sign-in prompt sits in the layout beside whatever the page itself opens. Without this
   * an instance that had never been open would release a lock somebody else was holding:
   * the splash locked on mount, the prompt mounted a tick later, reported "closed", and
   * handed the page straight back.
   */
  let holding = false

  const set = (open) => {
    if (!open && !holding) return
    holding = !!open

    // BOTH elements. ScrollSmoother gives the BODY the whole document's height and lets
    // the window scroll behind it, so `overflow: hidden` on the body alone stops nothing
    // — the viewport is scrolling the root element.
    lockedBody.value = !!open
    lockedRoot.value = !!open
    pauseSmoother(!!open)
  }

  // `immediate`, because a panel can be open on its very first render — the splash is up
  // before anything else exists — and a watcher that only fires on CHANGE would let the
  // page scroll underneath it until it closed.
  watch(isOpen, set, { immediate: true })

  // A route change can unmount the page with the dialog still open, which would leave the
  // body locked and the whole site unscrollable.
  onBeforeUnmount(() => set(false))
}
