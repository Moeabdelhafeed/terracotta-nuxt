export default defineNuxtPlugin(() => {
  const { baseUrl, translationsMode } = useRuntimeConfig().public
  const { deviceId, platform } = useDevice()
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  /** @type {import('ofetch').$Fetch} */
  const publicApi = $fetch.create({
    baseURL: baseUrl,
    onRequest({ options }) {
      const headers = new Headers(options.headers)
      if (deviceId.value) headers.set('X-Device-Id', deviceId.value)
      if (platform.value) headers.set('X-Platform', platform.value)
      if (!headers.has('Accept-Language')) {
        const code = translationsMode === 'local'
          ? (i18nLocale.value ?? lang.value?.code ?? 'en')
          : (lang.value?.code ?? 'en')
        headers.set('Accept-Language', code)
      }

      // The production host blocks real PUT/PATCH/DELETE — send them as POST
      // with an X-HTTP-Method-Override header. Laravel's kernel resolves the
      // real verb from the header, so routes stay Route::put/delete.
      //
      // `_method` goes in the query as well: a hop that strips unknown X- headers
      // would otherwise turn a DELETE into a bare POST to the same URI, i.e. a
      // delete that reads as a create. The query string survives that.
      const method = String(options.method ?? 'GET').toUpperCase()
      if (method === 'PUT' || method === 'PATCH' || method === 'DELETE') {
        headers.set('X-HTTP-Method-Override', method)
        options.query = { ...options.query, _method: method }
        options.method = 'POST'
      }

      options.headers = headers
    },
  })

  return { provide: { publicApi } }
})
