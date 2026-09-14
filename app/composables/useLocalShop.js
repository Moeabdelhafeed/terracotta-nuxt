/**
 * The basket and the hearts for a visitor with no account. Every cart/favourite route on
 * the API 401s a guest, so both live in localStorage until a real session exists, then
 * `pushLocalShopToServer` replays them and the server copy takes over.
 *
 * Storage holds ids only — the products behind them are refetched from the public
 * catalogue, so a price change or a delisting is never served from a stale local copy.
 */
export const localCartIds = useLocalStorage("terracotta:cart", []);
export const localFavoriteIds = useLocalStorage("terracotta:favorites", []);

/**
 * The server cannot see localStorage, so it renders an empty basket; the browser fills
 * these refs at module-eval time, before Vue hydrates. Reads therefore stay empty until
 * hydration is done — `initOnMounted` does not cover this, since vueuse runs its callback
 * straight away when there is no component instance, which is the case for a module ref.
 */
const hydrated = ref(false);
const markHydrated = () => {
  if (hydrated.value || import.meta.server) return;
  const nuxtApp = useNuxtApp();
  // Not hydrating means a client-side navigation (or a test): storage is safe to read now.
  if (!nuxtApp.isHydrating) hydrated.value = true;
  else
    nuxtApp.hooks.hookOnce("app:suspense:resolve", () => {
      hydrated.value = true;
    });
};

const cartEntries = computed(() => (hydrated.value ? localCartIds.value : []));
const favoriteEntries = computed(() =>
  hydrated.value ? localFavoriteIds.value : [],
);

const products = ref({});
const pending = ref(false);
const error = ref(null);

const storedIds = () => [
  ...new Set([
    ...localCartIds.value.map((entry) => entry.id),
    ...localFavoriteIds.value,
  ]),
];

/** A product that no longer exists cannot come back — drop it from both stores for good. */
const prune = (id) => {
  localCartIds.value = localCartIds.value.filter((entry) => entry.id !== id);
  localFavoriteIds.value = localFavoriteIds.value.filter(
    (favorite) => favorite !== id,
  );
};

const hydrate = async (api, ids) => {
  if (!ids.length) return;
  pending.value = true;
  const results = await Promise.allSettled(
    ids.map((id) => api(`/api/shop/products/${id}`)),
  );
  const fetched = {};
  results.forEach((result, index) => {
    const id = ids[index];
    if (result.status === "fulfilled") {
      if (result.value?.data) fetched[id] = result.value.data;
      return;
    }
    const normalized = normalizeApiError(result.reason);
    // Anything but "gone" is this request's problem, not the id's: keep it and retry later.
    if (normalized.status === 404) prune(id);
    else error.value = normalized;
  });
  products.value = { ...products.value, ...fetched };
  pending.value = false;
};

let watching = false;
/**
 * The stores are module singletons, so hydration has to outlive whichever component asked
 * first — hence the detached scope rather than the caller's.
 */
const watchStoredIds = (api) => {
  markHydrated();
  if (watching || !import.meta.client) return;
  watching = true;
  effectScope(true).run(() => {
    watch(
      () => storedIds().join(","),
      () =>
        hydrate(
          api,
          storedIds().filter((id) => !products.value[id]),
        ),
      { immediate: true },
    );
  });
};

const refreshProducts = (api) => {
  products.value = {};
  return hydrate(api, storedIds());
};

export const useLocalCart = () => {
  const api = useApi();
  const { t } = useLang("web", "shop");
  watchStoredIds(api);

  const items = computed(() =>
    cartEntries.value.flatMap((entry) => {
      const product = products.value[entry.id];
      if (!product) return [];
      const unitPrice = product.sale_price ?? product.price;
      return [
        {
          id: entry.id,
          product,
          quantity: entry.quantity,
          unit_price: unitPrice,
          line_total: fromHalalas(toHalalas(unitPrice) * entry.quantity),
          in_stock:
            product.stock == null
              ? product.in_stock !== false
              : product.stock >= entry.quantity,
          available_stock: product.stock ?? null,
        },
      ];
    }),
  );

  const total = computed(() =>
    fromHalalas(
      items.value.reduce((sum, line) => sum + toHalalas(line.line_total), 0),
    ),
  );
  const count = computed(() =>
    cartEntries.value.reduce((sum, entry) => sum + (entry.quantity ?? 0), 0),
  );
  const hasOutOfStock = computed(() =>
    items.value.some((line) => line.in_stock === false),
  );
  const canCheckout = computed(
    () => items.value.length > 0 && !hasOutOfStock.value,
  );

  const maxFor = (productId) =>
    Math.min(
      products.value[productId]?.max_quantity ?? HARD_MAX_QUANTITY,
      HARD_MAX_QUANTITY,
    );

  const write = (productId, quantity) => {
    const capped = Math.max(1, Math.min(quantity, maxFor(productId)));
    const existing = localCartIds.value.find((entry) => entry.id === productId);
    localCartIds.value = existing
      ? localCartIds.value.map((entry) =>
          entry.id === productId ? { ...entry, quantity: capped } : entry,
        )
      : [...localCartIds.value, { id: productId, quantity: capped }];
    return capped;
  };

  /** Mirrors `POST /api/shop/cart`: an existing line is incremented, not replaced. */
  const add = async (productId, quantity = 1) => {
    const existing = localCartIds.value.find((entry) => entry.id === productId);
    const next = write(productId, (existing?.quantity ?? 0) + quantity);
    return {
      success: true,
      message: t(
        "added_to_cart",
        "Added to your cart.",
        "تمت الإضافة إلى عربيتك.",
      ),
      errors: null,
      data: { id: productId, quantity: next },
    };
  };

  const update = async (productId, quantity) => {
    const next = write(productId, quantity);
    return {
      success: true,
      message: t("cart_updated", "Cart updated.", "تم تحديث العربية."),
      errors: null,
      data: { id: productId, quantity: next },
    };
  };

  const remove = async (productId) => {
    localCartIds.value = localCartIds.value.filter(
      (entry) => entry.id !== productId,
    );
    return {
      success: true,
      message: t(
        "cart_line_removed",
        "Removed from your cart.",
        "تمت الإزالة من عربيتك.",
      ),
      errors: null,
      data: null,
    };
  };

  return {
    items,
    total,
    count,
    hasOutOfStock,
    canCheckout,
    pending,
    error,
    refresh: () => refreshProducts(api),
    add,
    update,
    remove,
  };
};

export const useLocalFavorites = () => {
  const api = useApi();
  watchStoredIds(api);

  const favorites = computed(() =>
    favoriteEntries.value.map((id) => products.value[id]).filter(Boolean),
  );

  const isFavorited = (product) => favoriteEntries.value.includes(product?.id);

  const toggle = async (product) => {
    const next = !isFavorited(product);
    localFavoriteIds.value = next
      ? [product.id, ...localFavoriteIds.value]
      : localFavoriteIds.value.filter((id) => id !== product.id);
    return next;
  };

  return {
    favorites,
    isFavorited,
    toggle,
    pending,
    error,
    refresh: () => refreshProducts(api),
  };
};

/**
 * Replay the local stores onto a freshly signed-in account. A line the server refuses
 * (gone, or no longer buyable) is dropped rather than blocking the rest — the visitor is
 * mid-login and cannot be asked about it.
 */
export const pushLocalShopToServer = async (api) => {
  const lines = [...localCartIds.value];
  const favorites = [...localFavoriteIds.value];
  if (!lines.length && !favorites.length)
    return { pushedLines: 0, pushedFavorites: 0, dropped: 0 };

  let pushedLines = 0;
  let pushedFavorites = 0;
  let dropped = 0;

  const attempt = async (call) => {
    try {
      await call();
      return true;
    } catch (err) {
      const { status } = normalizeApiError(err);
      if (status !== 404 && status !== 422) throw err;
      dropped += 1;
      return false;
    }
  };

  for (const line of lines) {
    if (
      await attempt(() =>
        api("/api/shop/cart", {
          method: "POST",
          body: { shop_product_id: line.id, quantity: line.quantity },
        }),
      )
    )
      pushedLines += 1;
  }
  for (const id of favorites) {
    if (
      await attempt(() => api(`/api/shop/favorites/${id}`, { method: "POST" }))
    )
      pushedFavorites += 1;
  }

  localCartIds.value = [];
  localFavoriteIds.value = [];
  products.value = {};
  await refreshNuxtData(["cart", "favorites"]);

  return { pushedLines, pushedFavorites, dropped };
};
