/**
 * What a back arrow should actually do.
 *
 * Every inner page declares one fixed destination for its arrow, but most of them are
 * reached from more than one place: /orders is linked from the profile AND the shop, a
 * workshop is opened from the home page, the workshops list and now «قطعي». A hardcoded
 * target sends half the visitors somewhere they have never been — opening /orders from
 * the profile and pressing back threw the customer out into the catalogue.
 *
 * So the declared route becomes a FALLBACK, for when there is genuinely nowhere to go
 * back to: a fresh tab, a shared link, a reload, or an arrival from another site. When
 * the previous entry is a page on this site, step back to it instead.
 *
 * The arrow stays an `<a>` with the fallback as its `href` — middle-click and "open in
 * new tab" keep working, and the markup is the same on the server and after hydration,
 * where `history.state` does not exist yet. It is deliberately NOT a `<NuxtLink>`: that
 * runs its own click handler and navigates to `to` before a listener bound from outside
 * can call `preventDefault`, so the fallback always won.
 */

/**
 * Whether this click should step back through history rather than follow the href.
 *
 * `previous` is the history entry behind this one (`history.state.back`) and `current`
 * the path being viewed. Pure, so the rules are testable without a router.
 */
export const shouldStepBack = (previous, current, event = {}) => {
  // Leave anything that is not a plain left-click in this tab to the browser, so
  // ctrl-click and middle-click still open a tab on the fallback.
  if (event.defaultPrevented) return false
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return false
  if (event.button !== undefined && event.button !== 0) return false

  // Only a path on this site, and never the page we are already on — a `replace` can
  // leave the current route sitting in the back slot.
  if (typeof previous !== 'string') return false
  return previous.startsWith('/') && previous !== current
}

export const useBackNavigation = (fallback) => {
  const router = useRouter()
  const route = useRoute()

  const onBackClick = (event) => {
    const previous = router.options.history.state?.back

    if (!shouldStepBack(previous, route.fullPath, event)) {
      // A modified click is the browser's; anything else follows the fallback, through
      // the router rather than as a document load.
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
      if (event.button !== undefined && event.button !== 0) return
      event.preventDefault()
      return navigateTo(toValue(fallback))
    }

    event.preventDefault()
    router.back()
  }

  return { onBackClick }
}
