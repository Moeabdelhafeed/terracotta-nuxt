export default defineAppConfig({
  echo: {
    interceptors: {
      onRequest: async (app, ctx) => {
        const { translationsMode } = useRuntimeConfig().public

        const { deviceId, platform, fcmToken } = useDevice()
        if (deviceId.value) ctx.options.headers.set('X-Device-Id', deviceId.value)
        if (platform.value) ctx.options.headers.set('X-Platform', platform.value)
        if (fcmToken.value && (platform.value === 'ios' || platform.value === 'android')) {
          ctx.options.headers.set('X-FCM-Token', fcmToken.value)
        }

        if (!ctx.options.headers.has('Accept-Language')) {
          const lang = useCookie('lang')
          const i18nLocale = useCookie('i18n_locale')
          const code = translationsMode === 'local'
            ? (i18nLocale.value ?? lang.value?.code ?? 'en')
            : (lang.value?.code ?? 'en')
          ctx.options.headers.set('Accept-Language', code)
        }

        const sanctum = useSanctumAppConfig()
        const token = await sanctum?.tokenStorage?.get?.(app)
        if (token) ctx.options.headers.set('Authorization', `Bearer ${token}`)
      },
    },
  },
})
