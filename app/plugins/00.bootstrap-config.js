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

      // Prefer what the visitor's browser asks for, when the project actually has it.
      // `Accept-Language` is ranked — `ar,en;q=0.8` means Arabic first — so the list is
      // sorted by q and then walked in *that* order. Searching the project's languages
      // instead would hand an Arabic speaker whichever locale the backend happens to
      // list first, since their header mentions English too.
      const preferred = (import.meta.server ? useRequestHeaders(['accept-language'])['accept-language'] : navigator.language)
      const wanted = String(preferred ?? '')
        .split(',')
        .map((part) => {
          const [tag, ...params] = part.split(';')
          const q = params.map((p) => p.trim()).find((p) => p.startsWith('q='))
          return { code: tag.trim().split('-')[0].toLowerCase(), q: q ? Number(q.slice(2)) : 1 }
        })
        .filter((entry) => entry.code && !Number.isNaN(entry.q))
        .sort((a, b) => b.q - a.q)

      const fallback = wanted
        .map(({ code }) => languages.find((l) => String(l.code).toLowerCase() === code))
        .find(Boolean)
        ?? languages.find((l) => l.is_default)
        ?? languages[0]
        ?? null

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
