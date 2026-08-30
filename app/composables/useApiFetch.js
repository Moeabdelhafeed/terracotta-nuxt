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
  const shared = { dedupe: 'defer', getCachedData: cachedForKey, ...options }

  const { appUsers } = useAuthConfig()
  if (appUsers.value) {
    return useSanctumFetch(url, shared)
  }
  const { baseUrl, translationsMode } = useRuntimeConfig().public
  const { deviceId, platform, fcmToken } = useDevice()
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')
  return useFetch(url, {
    baseURL: baseUrl,
    onRequest({ options: opts }) {
      const headers = new Headers(opts.headers)
      if (deviceId.value) headers.set('X-Device-Id', deviceId.value)
      if (platform.value) headers.set('X-Platform', platform.value)
      if (fcmToken.value && (platform.value === 'ios' || platform.value === 'android')) {
        headers.set('X-FCM-Token', fcmToken.value)
      }
      if (!headers.has('Accept-Language')) {
        const code = translationsMode === 'local'
          ? (i18nLocale.value ?? lang.value?.code ?? 'en')
          : (lang.value?.code ?? 'en')
        headers.set('Accept-Language', code)
      }
      opts.headers = headers
    },
    ...shared,
  })
}
