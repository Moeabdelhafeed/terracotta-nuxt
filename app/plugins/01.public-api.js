export default defineNuxtPlugin(() => {
  const { baseUrl, translationsMode } = useRuntimeConfig().public
  const { deviceId, platform, fcmToken } = useDevice()
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  /** @type {import('ofetch').$Fetch} */
  const publicApi = $fetch.create({
    baseURL: baseUrl,
    onRequest({ options }) {
      const headers = new Headers(options.headers)
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

      // The production host blocks real PUT/PATCH/DELETE — send them as POST
      // with an X-HTTP-Method-Override header. Laravel's kernel resolves the
      // real verb from the header, so routes stay Route::put/delete.
      const method = String(options.method ?? 'GET').toUpperCase()
      if (method === 'PUT' || method === 'PATCH' || method === 'DELETE') {
        headers.set('X-HTTP-Method-Override', method)
        options.method = 'POST'
      }

      options.headers = headers
    },
  })

  return { provide: { publicApi } }
})
