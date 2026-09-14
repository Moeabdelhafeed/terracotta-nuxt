/**
 * Hearts. `is_favorited` rides on every product summary, so a tap flips it locally first
 * and the server call follows (`POST`/`DELETE /api/shop/favorites/{product}`). Overrides
 * are keyed by product id in shared state, so a card in the grid, the detail page and
 * the favorites list all agree without a refetch.
 *
 * A visitor with no account hearts into localStorage instead (`useLocalFavorites`); the
 * pile is pushed to the server when they sign in.
 */
export const useFavorites = () => {
  const api = useApi();
  const toast = useToast();
  const { isRegistered } = useIsRegistered();
  const local = useLocalFavorites();

  const overrides = useState("favorite-overrides", () => ({}));

  const isFavorited = (product) =>
    isRegistered.value
      ? (overrides.value[product?.id] ?? !!product?.is_favorited)
      : local.isFavorited(product);

  const { data, pending, error, refresh } = useApiFetch("/api/shop/favorites", {
    key: "favorites",
    transform: (res) => unwrapList(res?.data).items,
    default: () => [],
    immediate: isRegistered.value,
    watch: [isRegistered],
  });

  const favorites = computed(() =>
    isRegistered.value
      ? asList(data.value).filter((product) => isFavorited(product))
      : local.favorites.value,
  );

  const toggle = async (product) => {
    if (!isRegistered.value) return local.toggle(product);
    const next = !isFavorited(product);
    overrides.value = { ...overrides.value, [product.id]: next };
    try {
      await api(`/api/shop/favorites/${product.id}`, {
        method: next ? "POST" : "DELETE",
      });
    } catch (err) {
      const normalized = normalizeApiError(err);
      // Removing something already gone is the outcome we wanted.
      if (next || normalized.status !== 404) {
        overrides.value = { ...overrides.value, [product.id]: !next };
        toast.error(normalized.message);
      }
    }
    return next;
  };

  return {
    favorites,
    isFavorited,
    toggle,
    isRegistered,
    pending: computed(() =>
      isRegistered.value ? pending.value : local.pending.value,
    ),
    error: computed(() =>
      isRegistered.value ? error.value : local.error.value,
    ),
    refresh: () => (isRegistered.value ? refresh() : local.refresh()),
  };
};
