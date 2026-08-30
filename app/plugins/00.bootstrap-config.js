const buildHeaders = (deviceId, platform, fcmToken, langCode, bearer) => {
  const h = {}
  if (deviceId) h['X-Device-Id'] = deviceId
  if (platform) h['X-Platform'] = platform
  if (fcmToken && (platform === 'ios' || platform === 'android')) h['X-FCM-Token'] = fcmToken
  if (langCode) h['Accept-Language'] = langCode
  if (bearer) h['Authorization'] = `Bearer ${bearer}`
  return h
}

export default defineNuxtPlugin(async (nuxtApp) => {
  // SSR already fetched both and shipped them in the payload — refetching on
  // hydration doubles every page load against Laravel's throttle:api bucket.
  if (import.meta.client && nuxtApp.payload.serverRendered) return

  const cfgState = useState('config', () => ({}))
  const user = useSanctumUser()
  const { baseUrl, translationsMode } = useRuntimeConfig().public
  const { deviceId, platform, fcmToken } = useDevice()
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  // First visit has no `lang` cookie, so without this every request in the same render
  // would go out as `en` while the layout takes its dir/lang from the backend's default
  // language — an Arabic-first site rendering rtl with English copy. Resolving the
  // language here, before any other fetch, means one consistent locale from the start.
  if (!lang.value) {
    try {
      // The API rejects a request with no Accept-Language, so the discovery call sends
      // one; the list it returns is the same whichever locale asks for it.
      const res = await $fetch('/api/languages', {
        baseURL: baseUrl,
        headers: buildHeaders(deviceId.value, platform.value, fcmToken.value, 'en', null),
      })
      const languages = res?.data ?? res ?? []

      // The backend's default language wins a first visit, and the browser's
      // `Accept-Language` is deliberately not consulted: phones here are routinely set to
      // English by people who read Arabic, so the header is a poor guess at what a visitor
      // wants, and guessing wrong hands a local the wrong site. The switcher in the bottom
      // bar is one tap away and its choice persists in the `lang` cookie, which this whole
      // block is skipped for on every later visit.
      const fallback = languages.find((l) => l.is_default) ?? languages[0] ?? null

      if (fallback) {
        lang.value = fallback
        i18nLocale.value = fallback.code

        // Nuxt's useCookie re-parses the *incoming* request header on every call, so a
        // value written here is invisible to the composables that read it later in this
        // same render (they would still see no language). Writing it back onto the
        // request makes the rest of the pass behave as if the browser had sent it.
        if (import.meta.server) {
          const event = useRequestEvent()
          const jar = event?.node?.req?.headers
          if (jar) {
            const encoded = `lang=${encodeURIComponent(JSON.stringify(fallback))}; i18n_locale=${fallback.code}`
            jar.cookie = jar.cookie ? `${jar.cookie}; ${encoded}` : encoded
          }
        }
      }

      // useLang() reads the same key through useApiFetch — hand it this response so the
      // list is not fetched twice per render.
      nuxtApp.payload.data.languages = res
    } catch (err) {
      console.warn('[bootstrap-config] failed to resolve default language', err?.message ?? err)
    }
  }

  const code = translationsMode === 'local'
    ? (i18nLocale.value ?? lang.value?.code ?? 'en')
    : (lang.value?.code ?? 'en')

  const sanctumAppCfg = useSanctumAppConfig()
  const bearer = await sanctumAppCfg?.tokenStorage?.get?.(nuxtApp).catch(() => null)

  const headers = buildHeaders(deviceId.value, platform.value, fcmToken.value, code, bearer)

  const [cfgRes, userRes] = await Promise.allSettled([
    $fetch('/api/config', { baseURL: baseUrl, headers }),
    $fetch('/api/user', { baseURL: baseUrl, headers }),
  ])

  if (cfgRes.status === 'fulfilled') {
    cfgState.value = cfgRes.value?.data ?? cfgRes.value ?? {}
  } else {
    console.warn('[bootstrap-config] failed to load /api/config', cfgRes.reason?.message ?? cfgRes.reason)
    cfgState.value = {}
  }

  if (userRes.status === 'fulfilled') {
    user.value = userRes.value ?? null
  } else {
    console.warn('[bootstrap-config] failed to load /api/user', userRes.reason?.message ?? userRes.reason)
  }
})
