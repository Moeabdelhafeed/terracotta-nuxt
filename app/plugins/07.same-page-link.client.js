/**
 * A link to the page you are already on scrolls back to its top.
 *
 * The router ignores a navigation to the location it is already at, so the footer's
 * "Home" on the home page, "Terms" on the terms page or the nav's current tab did nothing
 * at all — the reader clicked and stayed half-way down. One listener for every link on the
 * site, rather than a handler on each, so a link added later behaves the same.
 *
 * Capture phase, because <NuxtLink> cancels the click in its own handler before a bubbling
 * listener would see it. A modified click (new tab), a link out, or one with a `#target`
 * is left alone.
 */
export default defineNuxtPlugin(() => {
  document.addEventListener(
    'click',
    (event) => {
      if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

      const link = event.target.closest?.('a[href]')
      if (!link || (link.target && link.target !== '_self') || link.hasAttribute('download')) return

      const url = new URL(link.href, location.href)
      if (url.origin !== location.origin || url.hash) return
      if (url.pathname.replace(/\/$/, '') !== location.pathname.replace(/\/$/, '')) return
      if (url.search !== location.search) return

      scrollToTop(true)
    },
    { capture: true },
  )
})
