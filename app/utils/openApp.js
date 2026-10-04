/**
 * Tries to open the app on a deep link and answers whether it opened.
 *
 * A web page cannot ask whether an app is installed. The only signal is the browser
 * losing the page to it, so this sends the link and listens:
 * - the page going hidden (or being left) means the app took over → `true`;
 * - nothing happening within `wait` means there is no app → `false`. Android Chrome
 *   ignores a scheme nothing handles, silently.
 *
 * iOS shows a dialog first: "Open in Terracotta?", or "address is invalid" when the app is
 * missing. That blurs the page without hiding it, so the clock stops while the dialog is
 * up. When she comes back to the page without having left it (she cancelled, or there is
 * no app), it answers `false` shortly after. `cap` stops a dialog left open from holding
 * the button for ever.
 *
 * @returns {Promise<boolean>}
 */
export const openApp = (
  url,
  { wait = 2500, settle = 600, cap = 15000, go = (link) => { window.location.href = link } } = {},
) =>
  new Promise((resolve) => {
    let settled = false
    let timer = null
    let hardStop = null

    const finish = (opened) => {
      if (settled) return
      settled = true
      clearTimeout(timer)
      clearTimeout(hardStop)
      document.removeEventListener('visibilitychange', onVisibility)
      window.removeEventListener('pagehide', onLeave)
      window.removeEventListener('blur', onBlur)
      window.removeEventListener('focus', onFocus)
      resolve(opened)
    }
    const onVisibility = () => {
      if (document.visibilityState === 'hidden') finish(true)
    }
    const onLeave = () => finish(true)
    const onBlur = () => clearTimeout(timer)
    const onFocus = () => {
      clearTimeout(timer)
      timer = setTimeout(() => finish(false), settle)
    }

    document.addEventListener('visibilitychange', onVisibility)
    window.addEventListener('pagehide', onLeave)
    window.addEventListener('blur', onBlur)
    window.addEventListener('focus', onFocus)
    timer = setTimeout(() => finish(false), wait)
    hardStop = setTimeout(() => finish(false), cap)
    go(url)
  })
