/**
 * Catch-all proxy to the Laravel API.
 *
 * Every client/SSR request to `/api/*` lands here and is forwarded to the real
 * Laravel host (`runtimeConfig.apiBaseUrl`). The secret `X-API-TOKEN` is
 * injected SERVER-SIDE here — it lives in private runtimeConfig and never ships
 * to the browser bundle.
 *
 * All other headers the client set (Authorization Bearer, Accept-Language,
 * X-Device-Id, X-Platform, X-FCM-Token, X-HTTP-Method-Override) pass through
 * untouched, so per-user auth and device context still reach Laravel.
 *
 * The real client IP is forwarded as `X-Forwarded-For`: without it every SSR
 * request reaches Laravel from this server's IP, so all visitors share a single
 * `throttle:api` bucket and rate-limit each other out. Laravel trusts proxies
 * (`trustProxies(at: '*')`) so `$request->ip()` resolves to this value.
 *
 * Literal routes (e.g. server/api/dev-translations.post.js) take priority over
 * this catch-all, so dev-only endpoints stay local.
 */

// Only what is identical for every visitor in every language, so one upstream call a
// minute keeps a page refresh from eating Laravel's throttle.
//
// Nothing the API translates is cached here. The cached function returned one locale's
// answer for every key it was given — in production only, the one place this cache was
// active — which served Arabic copy to English readers no matter how the locale was
// asked for. Correctness first; the translated endpoints are cheap and go straight
// through.
const CACHED_PATHS = [
  /^\/api\/media$/,
  // Cached per locale — see fetchPublic. Excluded in dev, where the client seeds missing
  // keys and refreshes: a stale entry would hide the new key and it would seed twice.
  ...(import.meta.dev ? [] : [/^\/api\/translations$/, /^\/api\/app-settings$/, /^\/api\/pages(\/[^/]+)?$/]),
]

/**
 * One cached upstream call per path *per locale*.
 *
 * The locale is an explicit argument rather than something read back out of the headers,
 * so the cache key is derived from the same value the request is made with — nothing can
 * drift between what is fetched and what it is filed under. That drift is what served
 * Arabic copy to English readers in production, where this cache is the only thing that
 * differed from local.
 */
const fetchPublic = defineCachedFunction(
  (url, locale, headers) => $fetch(url, { headers }),
  {
    name: 'public-api',
    maxAge: 60,
    // Nitro writes each entry as a file path, so a key holding a URL — `?`, `&`, `=` and
    // all — gets mangled, and two locales of the same endpoint collapse onto one entry.
    // That is what served English copy to Arabic readers. A plain slug cannot collide.
    getKey: (url, locale) => `${url.replace(/[^a-z0-9]+/gi, '-')}-${locale}`,
  },
)

/**
 * Laravel matches `Accept-Language` literally against a language code, so `en` resolves to
 * English while `en-US,en;q=0.9` — what a browser actually sends — matches nothing and
 * falls back to the default language. Everything upstream leaves here as a bare code.
 */
const primaryLanguage = (header) => String(header ?? '')
  .split(',')[0]
  .split(';')[0]
  .trim()
  .split('-')[0]
  .toLowerCase()

export default defineEventHandler(async (event) => {
  const { xApiToken, apiBaseUrl } = useRuntimeConfig(event)
  const clientIp = getRequestIP(event, { xForwardedFor: true })

  // Laravel trusts proxies for X-Forwarded-Host, so left alone the API builds its asset
  // URLs from *this* origin: `image_api` comes back as http://localhost:3000/... and every
  // image 404s against Nuxt. h3 derives that header from the incoming request, so it has
  // to be pinned on the request itself — an override in `headers` below is ignored.
  // The client IP still travels separately, so rate limiting is unaffected.
  const apiUrl = new URL(apiBaseUrl)
  const incomingHeaders = event.node.req.headers

  // Every hint about *this* origin has to go, not just the host: Laravel composes its
  // asset URLs from forwarded host + port + proto, so a stray `x-forwarded-port: 3000`
  // is enough to send `image_api` back pointing at Nuxt, where the file 404s.
  delete incomingHeaders['x-forwarded-port']
  delete incomingHeaders['x-forwarded-proto']
  incomingHeaders['x-forwarded-host'] = apiUrl.host
  incomingHeaders.host = apiUrl.host

  const headers = {
    'X-API-TOKEN': xApiToken,
    ...(clientIp ? { 'X-Forwarded-For': clientIp } : {}),
  }

  // Reads only: a write carries its locale on purpose — the translation seeder POSTs the
  // same key once per locale with a forced header.
  const language = primaryLanguage(incomingHeaders['accept-language'])
  if (language && event.method === 'GET') incomingHeaders['accept-language'] = language

  if (event.method === 'GET' && CACHED_PATHS.some((re) => re.test(event.path.split('?')[0]))) {
    const incoming = getRequestHeaders(event)
    return fetchPublic(apiBaseUrl + event.path, language, {
      ...headers,
      'Accept-Language': language,
      'X-Device-Id': incoming['x-device-id'] ?? '',
      'X-Platform': incoming['x-platform'] ?? '',
    })
  }

  return proxyRequest(event, apiBaseUrl + event.path, { headers })
})
