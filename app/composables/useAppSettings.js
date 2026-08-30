/**
 * App settings link blocks from `GET /api/app-settings` (public, localized via
 * Accept-Language). SSR-friendly + deduped. Refetches when the language changes.
 *
 * Item shape: { id, text, url, image } where image is the backend Image object
 * ({ id, url, type, blurhash, image_api }) or null — render it with <AppImage>.
 */
export const useAppSettings = () => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  const { data, pending, error, refresh } = useApiFetch('/api/app-settings', {
    key: 'app-settings',
    transform: (res) => res?.data ?? {},
    default: () => ({}),
    watch: [lang, i18nLocale],
  })

  const blocks = computed(() => data.value ?? {})
  const social = computed(() => blocks.value.social ?? [])
  const contact = computed(() => blocks.value.contact ?? [])
  const appStore = computed(() => blocks.value.app_store ?? [])
  const googlePlay = computed(() => blocks.value.google_play ?? [])
  const appGallery = computed(() => blocks.value.app_gallery ?? [])

  return { blocks, social, contact, appStore, googlePlay, appGallery, pending, error, refresh }
}
