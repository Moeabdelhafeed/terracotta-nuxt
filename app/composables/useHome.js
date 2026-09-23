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
    // The server still blocks on it, so the HTML a visitor (or a crawler) lands on is
    // complete. A move to the home page from inside the site does not: the route paints
    // at once and the sections fill in, instead of the tap doing nothing until the
    // studio's whole front door has been fetched.
    lazy: import.meta.client,
  })

  const home = computed(() => data.value ?? {})

  return {
    home,
    banners: computed(() => asList(home.value.banners)),
    categories: computed(() => asList(home.value.categories)),
    featuredProducts: computed(() => asList(home.value.featured_products)),
    offers: computed(() => asList(home.value.offers)),
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
    transform: (res) => asList(res?.data?.data ?? res?.data),
    default: () => [],
    watch: [lang, i18nLocale],
    // As `useHome`: blocking on the server, free on a client move. The workshops page
    // draws skeletons while `pending`, and the home row renders nothing until it has
    // rows, so neither shows an empty frame.
    lazy: import.meta.client,
  })

  return { workshops: computed(() => asList(data.value)), pending, error, refresh }
}

/** Gallery categories with their cover image and item counts. */
export const useGallery = () => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  const { data, pending, error, refresh } = useApiFetch('/api/gallery', {
    key: 'gallery',
    transform: (res) => asList(res?.data),
    default: () => [],
    watch: [lang, i18nLocale],
  })

  return { categories: computed(() => asList(data.value)), pending, error, refresh }
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

/**
 * Where a home banner sends the visitor, from its `link_type` (Part IV §2):
 * a site path, an absolute URL for `external`, or `null` when it is decorative —
 * `none`, an unknown type, `external` without a URL, or a `page` whose id is not in
 * `pages` (the API hands back the numeric page id; the route wants the slug).
 */
export const bannerRoute = (banner, pages = []) => {
  const id = banner?.link_target_id
  switch (banner?.link_type) {
    case 'external': return banner.link || null
    case 'shop_home': return '/shop'
    case 'shop_category': return `/shop?category=${id}`
    case 'shop_product': return `/shop/${id}`
    case 'workshops': return '/workshops'
    case 'workshop': return `/workshops/${id}`
    case 'gallery_home': return '/gallery'
    case 'gallery_category': return `/gallery/${id}`
    case 'page': {
      const page = pages.find((p) => p.id === id)
      return page ? `/${page.slug}` : null
    }
    default: return null
  }
}

export const isExternalRoute = (route) => /^https?:\/\//.test(route ?? '')

/**
 * A banner that resolved to nothing is still shown — it is simply not tappable. The one
 * exception is a `page` banner whose page is gone: that is an orphaned promo, not a
 * decorative picture, so it drops out rather than teasing a destination that vanished.
 */
export const isBannerRenderable = (banner, route) => banner?.link_type !== 'page' || !!route

/** "10 photos · 11 videos" for an album, from whichever counts the API sent. */
export const galleryCounts = (category, t) => t(
  'gallery_counts',
  ':images photos · :videos videos',
  ':images صورة · :videos فيديو',
  { images: category?.images_count ?? 0, videos: category?.videos_count ?? 0 },
)
