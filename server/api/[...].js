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

// Public, read-only, locale-scoped content: identical for every visitor, so one
// upstream call per locale per minute is enough. Keeps a page refresh (7 API
// calls per render) from eating Laravel's 60/min throttle. `/api/translations`
// is cached in production only: in dev the client seeds missing keys and calls
// refreshTranslations(), which a stale cache would hide for up to a minute.
const CACHED_PATHS = [
  /^\/api\/app-settings$/,
  /^\/api\/languages$/,
  /^\/api\/media$/,
  /^\/api\/pages(\/[^/]+)?$/,
  ...(import.meta.dev ? [] : [/^\/api\/translations$/]),
]

const fetchPublic = defineCachedFunction(
  (url, headers) => $fetch(url, { headers }),
  {
    name: 'public-api',
    maxAge: 60,
    getKey: (url, headers) => `${url}|${headers['Accept-Language'] ?? ''}`,
  },
)

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

  if (event.method === 'GET' && CACHED_PATHS.some((re) => re.test(event.path.split('?')[0]))) {
    const incoming = getRequestHeaders(event)
    return fetchPublic(apiBaseUrl + event.path, {
      ...headers,
      'Accept-Language': incoming['accept-language'] ?? '',
      'X-Device-Id': incoming['x-device-id'] ?? '',
      'X-Platform': incoming['x-platform'] ?? '',
    })
  }

  return proxyRequest(event, apiBaseUrl + event.path, { headers })
})
