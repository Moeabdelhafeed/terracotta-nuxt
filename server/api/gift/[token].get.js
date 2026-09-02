/**
 * The gift link's one API call, made from here rather than the browser.
 *
 * `X-API-TOKEN` is a shared secret: a gift link is a public marketing page opened by
 * people with no account, so the token must never reach the bundle or the network tab.
 * This literal route takes priority over the `/api/*` catch-all proxy, which would
 * forward the visitor's own headers — and those are wrong for this endpoint twice over:
 *
 *  - `X-Platform` is derived from the user agent, so a phone sends `ios`, and the API
 *    then demands an `X-FCM-Token` a website does not have. Verified: `ios` → 422.
 *  - `X-Device-Id` would be the visitor's device cookie, registering a device for
 *    somebody who has no account. A constant stands in instead.
 */
const LOCALES = ['ar', 'en']


export default defineEventHandler(async (event) => {
  const { xApiToken, apiBaseUrl } = useRuntimeConfig(event)
  const token = getRouterParam(event, 'token')

  // The API's own messages are localized; everything else in the payload is text the
  // buyer typed and comes back as written.
  const cookieLocale = getCookie(event, 'i18n_locale') ?? ''
  const headerLocale = String(getRequestHeader(event, 'accept-language') ?? '').slice(0, 2)
  const locale = LOCALES.find((code) => code === cookieLocale) ?? LOCALES.find((code) => code === headerLocale) ?? 'ar'

  try {
    const res = await $fetch(`${apiBaseUrl}/api/gifts/${encodeURIComponent(token)}`, {
      headers: {
        'X-API-TOKEN': xApiToken,
        'X-Device-Id': 'web-gift-page',
        'X-Platform': 'web',
        'Accept-Language': locale,
      },
    })

    return res?.data ?? null
  } catch (err) {
    const status = err?.response?.status ?? err?.statusCode

    // Unknown token, or a gift the buyer never paid for — the API does not distinguish
    // between the two on purpose, and neither does the page.
    if (status === 404) {
      throw createError({ statusCode: 404, statusMessage: 'Gift not found' })
    }

    throw createError({ statusCode: 502, statusMessage: 'Gift lookup failed' })
  }
})
