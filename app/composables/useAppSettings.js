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

  /**
   * The legal identifiers a Saudi storefront has to display: `{ cr_number, vat_number,
   * business_center_url, vat_rate }`. The API returns only the fields that are filled in,
   * so an empty object means the business is not registered and nothing should render.
   */
  const business = computed(() => blocks.value.business ?? {})

  return { blocks, social, contact, appStore, googlePlay, appGallery, business, pending, error, refresh }
}
