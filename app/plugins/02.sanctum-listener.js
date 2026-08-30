export default defineNuxtPlugin((nuxtApp) => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')
  const { deviceId, platform, fcmToken } = useDevice()

  nuxtApp.hook('sanctum:request', (_app, ctx) => {
    const { translationsMode } = useRuntimeConfig().public
    const headers = new Headers(ctx.options.headers)

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
    ctx.options.headers = headers
  })
})
