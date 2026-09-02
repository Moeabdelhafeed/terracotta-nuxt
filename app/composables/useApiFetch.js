/**
 * Per-request cache lookup. Nuxt's default only reads the payload while
 * hydrating, so two components calling the same keyed fetch during one SSR
 * render each hit the API. `cause: 'initial'` covers exactly the duplicate-call
 * case — `watch` and `refresh()` still go to the network.
 */
const cachedForKey = (key, nuxtApp, ctx) =>
  ctx.cause === 'initial'
    ? (nuxtApp.payload.data[key] ?? nuxtApp.static.data[key])
    : undefined

/**
 * SSR-friendly data fetcher. Dispatches to `useSanctumFetch` when
 * `app_users=true`, else to `useFetch` configured against `$publicApi`'s
 * baseURL with the same header set.
 *
 * Shared-key calls are deduped: `dedupe: 'defer'` reuses an in-flight request
 * instead of firing (and cancelling) a second one, and `getCachedData` reuses
 * an already-resolved one. Without both, a composable used by N components
 * costs N API calls per render and burns through Laravel's `throttle:api`.
 *
 * Mirrors the `useFetch` signature so all native options
 * (key, watch, transform, default, lazy, server, etc.) work as expected.
 *
 * @type {typeof import('#app').useFetch}
 */
export const useApiFetch = (url, options = {}) => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')
  const { translationsMode } = useRuntimeConfig().public

  const locale = computed(() => (translationsMode === 'local'
    ? (i18nLocale.value ?? lang.value?.code ?? 'en')
    : (lang.value?.code ?? 'en')))

  /**
   * Every call carries its locale in the query string as well as in `Accept-Language`.
   * The header is the one the API actually reads, but a CDN in front of this app rewrites
   * it and drops cookies on /api/* requests — the query survives that, and the proxy
   * turns it back into a header. It also keys the proxy's cache, so one visitor's locale
   * can no longer be served to the next.
   */
  const shared = {
    dedupe: 'defer',
    getCachedData: cachedForKey,
    ...options,
    query: computed(() => ({ ...(toValue(options.query) ?? {}), locale: locale.value })),
  }

  const { appUsers } = useAuthConfig()
  if (appUsers.value) {
    return useSanctumFetch(url, shared)
  }
  const { baseUrl } = useRuntimeConfig().public
  const { deviceId, platform, fcmToken } = useDevice()
  return useFetch(url, {
    baseURL: baseUrl,
    onRequest({ options: opts }) {
      const headers = new Headers(opts.headers)
      if (deviceId.value) headers.set('X-Device-Id', deviceId.value)
      if (platform.value) headers.set('X-Platform', platform.value)
      if (fcmToken.value && (platform.value === 'ios' || platform.value === 'android')) {
        headers.set('X-FCM-Token', fcmToken.value)
      }
      if (!headers.has('Accept-Language')) headers.set('Accept-Language', locale.value)
      opts.headers = headers
    },
    ...shared,
  })
}
