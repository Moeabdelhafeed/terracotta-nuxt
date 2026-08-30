/**
 * The home screen's own endpoint: everything above the fold in one call.
 * `GET /api/home` → { banners, categories, featured_products, offers, current_booking }.
 * SSR-friendly, deduped, and refetched when the language changes.
 */
export const useHome = () => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  const { data, pending, error, refresh } = useApiFetch('/api/home', {
    key: 'home',
    transform: (res) => res?.data ?? {},
    default: () => ({}),
    watch: [lang, i18nLocale],
  })

  const home = computed(() => data.value ?? {})

  return {
    home,
    banners: computed(() => home.value.banners ?? []),
    categories: computed(() => home.value.categories ?? []),
    featuredProducts: computed(() => home.value.featured_products ?? []),
    offers: computed(() => home.value.offers ?? []),
    currentBooking: computed(() => home.value.current_booking ?? null),
    pending,
    error,
    refresh,
  }
}

/** Active workshops (`GET /api/workshops`), the studio's core offer. */
export const useWorkshops = () => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  const { data, pending, error, refresh } = useApiFetch('/api/workshops', {
    key: 'workshops',
    // The endpoint paginates, so the list may arrive wrapped in a paginator.
    transform: (res) => res?.data?.data ?? res?.data ?? [],
    default: () => [],
    watch: [lang, i18nLocale],
  })

  return { workshops: computed(() => data.value ?? []), pending, error, refresh }
}

/** Gallery categories with their cover image and item counts. */
export const useGallery = () => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  const { data, pending, error, refresh } = useApiFetch('/api/gallery', {
    key: 'gallery',
    transform: (res) => res?.data ?? [],
    default: () => [],
    watch: [lang, i18nLocale],
  })

  return { categories: computed(() => data.value ?? []), pending, error, refresh }
}

/** Prices arrive as decimal strings ("45.00"); show them the way the app does. */
export const usePrice = () => {
  const { t } = useLang('web', 'home')
  const currency = computed(() => t('currency', 'SAR', 'ريال'))

  const format = (value) => {
    const amount = Number(value ?? 0)
    return `${amount % 1 === 0 ? amount.toFixed(0) : amount.toFixed(2)} ${currency.value}`
  }

  return { format, currency }
}
