/**
 * Read-only catalogue access for the public site: workshops, shop and gallery.
 *
 * This build is for exploring only — nothing here books, buys or signs anyone in, so no
 * endpoint that mutates state or needs a session is wrapped.
 */
const localeKeys = () => [useCookie('lang'), useCookie('i18n_locale')]

export const useWorkshop = (id) => {
  const request = useApiFetch(() => `/api/workshops/${toValue(id)}`, {
    key: () => `workshop-${toValue(id)}`,
    // Client-side only: a click navigates at once and the page shows its skeleton rather
    // than freezing on the previous screen. On the server it still blocks, so the render
    // knows whether the record exists — a lazy SSR fetch resolves after the component has
    // already rendered, and Vue does not flush watchers there to catch up.
    lazy: import.meta.client,
    transform: (res) => res?.data ?? null,
    default: () => null,
    watch: [() => toValue(id), ...localeKeys()],
  })

  const { data, pending, error } = request

  return { workshop: computed(() => data.value), pending, error }
}

export const useShopCategories = () => {
  const { data, pending } = useApiFetch('/api/shop/categories', {
    key: 'shop-categories',
    transform: (res) => res?.data ?? [],
    default: () => [],
    watch: localeKeys(),
  })

  return { categories: computed(() => data.value ?? []), pending }
}

/**
 * The product list, paginated. Filtering and paging both happen on the server — the list
 * payload carries no category, so it cannot be filtered client-side.
 *
 * `query` may hold refs (`category_id`, `sub_category_id`, `page`, `per_page`, `search`);
 * the list refetches as they change.
 */
export const useProducts = (query = {}) => {
  const { data, pending } = useApiFetch('/api/shop/products', {
    key: 'shop-products',
    query,
    // With a numeric `per_page` the endpoint returns a paginator; with `all` a bare array.
    transform: (res) => {
      const payload = res?.data ?? {}
      const items = Array.isArray(payload) ? payload : (payload.data ?? [])

      return {
        items,
        page: payload.current_page ?? 1,
        lastPage: payload.last_page ?? 1,
        total: payload.total ?? items.length,
      }
    },
    default: () => ({ items: [], page: 1, lastPage: 1, total: 0 }),
    watch: localeKeys(),
  })

  return {
    products: computed(() => data.value?.items ?? []),
    page: computed(() => data.value?.page ?? 1),
    lastPage: computed(() => data.value?.lastPage ?? 1),
    total: computed(() => data.value?.total ?? 0),
    pending,
  }
}

export const useProduct = (id) => {
  const request = useApiFetch(() => `/api/shop/products/${toValue(id)}`, {
    key: () => `product-${toValue(id)}`,
    // Client-side only: a click navigates at once and the page shows its skeleton rather
    // than freezing on the previous screen. On the server it still blocks, so the render
    // knows whether the record exists — a lazy SSR fetch resolves after the component has
    // already rendered, and Vue does not flush watchers there to catch up.
    lazy: import.meta.client,
    transform: (res) => res?.data ?? null,
    default: () => null,
    watch: [() => toValue(id), ...localeKeys()],
  })

  const { data, pending, error } = request

  return { product: computed(() => data.value), pending, error }
}

export const useGalleryCategory = (id) => {
  const request = useApiFetch(() => `/api/gallery/${toValue(id)}`, {
    key: () => `gallery-${toValue(id)}`,
    // Client-side only: a click navigates at once and the page shows its skeleton rather
    // than freezing on the previous screen. On the server it still blocks, so the render
    // knows whether the record exists — a lazy SSR fetch resolves after the component has
    // already rendered, and Vue does not flush watchers there to catch up.
    lazy: import.meta.client,
    transform: (res) => res?.data ?? null,
    default: () => null,
    watch: [() => toValue(id), ...localeKeys()],
  })

  const { data, pending, error } = request

  return { category: computed(() => data.value), pending, error }
}
