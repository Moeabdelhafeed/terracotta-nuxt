/**
 * Make a sideways rail behave under a pointer.
 *
 * Two jobs, and a rail may want either or both:
 *
 * **Grab to scroll.** A row of dates or seats is `overflow-x-auto`, which a finger drags
 * and a trackpad swipes — but a plain mouse has neither, so half the dates sit off-screen
 * with no way to reach them. The wheel is deliberately left alone: taking it over means
 * the page stops scrolling whenever the pointer happens to be over a rail.
 *
 * **Swallow the click a swipe leaves behind.** This is the one that bites on a phone. A
 * finger that starts on a banner and travels sideways is scrolling, not tapping — but the
 * browser still fires a click on the way up, so flicking the rail opened whatever card the
 * finger happened to land on. The gesture is watched for every pointer type, mouse or
 * finger, and once it has moved past a few pixels the click that follows is eaten.
 *
 * @param {import('vue').Ref<HTMLElement|null>} el
 * @param {{ drag?: boolean }} [options] `drag: false` keeps the click guard and leaves
 *   scrolling to the browser — for a rail that already has arrows to do the job.
 */
const DRAG_THRESHOLD = 6

export const useDragScroll = (el, { drag = true } = {}) => {
  if (import.meta.server) return

  let startX = 0
  let startLeft = 0
  let pointer = null
  let pulling = false
  let moved = false

  const scrolls = (node) => node && node.scrollWidth - node.clientWidth > 1

  useEventListener(el, 'pointerdown', (event) => {
    // Middle and right buttons have their own meanings.
    if (event.pointerType === 'mouse' && event.button !== 0) return
    if (!scrolls(el.value)) return

    pointer = event.pointerId
    startX = event.clientX
    startLeft = el.value.scrollLeft
    pulling = false
    moved = false
  })

  useEventListener(el, 'pointermove', (event) => {
    if (pointer === null || event.pointerId !== pointer) return

    const travelled = event.clientX - startX
    if (Math.abs(travelled) < DRAG_THRESHOLD) return
    moved = true

    // A finger scrolls the rail by itself; all that is wanted from it is the fact that it
    // moved, so the tap it turns into can be ignored.
    if (!drag || event.pointerType !== 'mouse') return

    if (!pulling) {
      pulling = true
      el.value.setPointerCapture(pointer)
      el.value.style.cursor = 'grabbing'
      el.value.style.userSelect = 'none'
    }

    el.value.scrollLeft = startLeft - travelled
    event.preventDefault()
  })

  const release = (event) => {
    if (pointer === null || (event.pointerId !== undefined && event.pointerId !== pointer)) return

    if (pulling) {
      el.value?.releasePointerCapture?.(pointer)
      el.value.style.cursor = ''
      el.value.style.userSelect = ''
      pulling = false
    }
    pointer = null
  }

  useEventListener(el, 'pointerup', release)
  useEventListener(el, 'pointercancel', release)

  // The click fires after `pointerup`, so the flag is still standing here and is cleared
  // on the way out. Capture phase, because the link is below and would otherwise have
  // navigated before this ran.
  useEventListener(el, 'click', (event) => {
    if (!moved) return
    event.stopPropagation()
    event.preventDefault()
    moved = false
  }, { capture: true })
}
