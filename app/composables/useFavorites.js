/**
 * Hearts. `is_favorited` rides on every product summary, so a tap flips it locally first
 * and the server call follows (`POST`/`DELETE /api/shop/favorites/{product}`). Overrides
 * are keyed by product id in shared state, so a card in the grid, the detail page and
 * the favorites list all agree without a refetch.
 */
export const useFavorites = () => {
  const api = useApi()
  const route = useRoute()
  const toast = useToast()
  const { user } = useSanctumAuth()
  const isRegistered = computed(() => !!user.value && !(user.value?.data?.is_guest ?? user.value?.is_guest))

  const overrides = useState('favorite-overrides', () => ({}))

  const isFavorited = (product) => overrides.value[product?.id] ?? !!product?.is_favorited

  const { data, pending, error, refresh } = useApiFetch('/api/shop/favorites', {
    key: 'favorites',
    transform: (res) => unwrapList(res?.data).items,
    default: () => [],
    immediate: isRegistered.value,
    watch: [isRegistered],
  })

  const favorites = computed(() => (data.value ?? []).filter((product) => isFavorited(product)))

  const toggle = async (product) => {
    if (!isRegistered.value) {
      return navigateTo({ path: '/login', query: { redirect: route.fullPath } })
    }
    const next = !isFavorited(product)
    overrides.value = { ...overrides.value, [product.id]: next }
    try {
      await api(`/api/shop/favorites/${product.id}`, { method: next ? 'POST' : 'DELETE' })
    } catch (err) {
      const normalized = normalizeApiError(err)
      // Removing something already gone is the outcome we wanted.
      if (next || normalized.status !== 404) {
        overrides.value = { ...overrides.value, [product.id]: !next }
        toast.error(normalized.message)
      }
    }
    return next
  }

  return { favorites, isFavorited, toggle, isRegistered, pending, error, refresh }
}
