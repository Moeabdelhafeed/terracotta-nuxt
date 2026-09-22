/**
 * Read-only catalogue access for the public site: workshops, shop and gallery.
 *
 * This build is for exploring only — nothing here books, buys or signs anyone in, so no
 * endpoint that mutates state or needs a session is wrapped.
 */
const localeKeys = () => [useCookie("lang"), useCookie("i18n_locale")];

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
  });

  const { data, pending, error, status } = request;

  return { workshop: computed(() => data.value), pending, error, status };
};

const catalogCategories = (path, key) => {
  const { data, pending } = useApiFetch(path, {
    key,
    transform: (res) => asList(res?.data),
    default: () => [],
    watch: localeKeys(),
  });

  return { categories: computed(() => asList(data.value)), pending };
};

export const useShopCategories = () =>
  catalogCategories("/api/shop/categories", "shop-categories");

/**
 * The raw materials and tools shelf — clay, glazes, brushes. A separate catalogue with the
 * same shape, and deliberately the same basket: a bag of clay and a mug check out together
 * as one order with one delivery fee, so nothing here needs its own cart or checkout.
 */
export const useMaterialCategories = () =>
  catalogCategories("/api/materials/categories", "material-categories");

/**
 * The product list, paginated. Filtering and paging both happen on the server — the list
 * payload carries no category, so it cannot be filtered client-side.
 *
 * `query` may hold refs (`category_id`, `sub_category_id`, `page`, `per_page`, `search`,
 * `min_price`, `max_price`, `sort`); the list refetches as they change.
 *
 * Price filtering and the two price sorts run on what the customer would actually pay, so a
 * product on offer answers for its sale price. Sending no `sort` at all keeps the studio's
 * own catalogue order, which is the right default for a shop somebody arranged by hand —
 * `newest` is a choice, not the fallback.
 */
export const useProducts = (
  query = {},
  { path = "/api/shop/products", key = "shop-products" } = {},
) => {
  const { data, pending, error, refresh } = useApiFetch(path, {
    key,
    query,
    // With a numeric `per_page` the endpoint returns a paginator; with `all` a bare array.
    transform: (res) => {
      const payload = res?.data ?? {};
      const items = Array.isArray(payload) ? payload : (payload.data ?? []);

      return {
        items,
        page: payload.current_page ?? 1,
        lastPage: payload.last_page ?? 1,
        total: payload.total ?? items.length,
      };
    },
    default: () => ({ items: [], page: 1, lastPage: 1, total: 0 }),
    watch: localeKeys(),
  });

  return {
    products: computed(() => asList(data.value?.items)),
    page: computed(() => data.value?.page ?? 1),
    lastPage: computed(() => data.value?.lastPage ?? 1),
    total: computed(() => data.value?.total ?? 0),
    pending,
    // Without these a failed request is indistinguishable from an empty shelf: `default`
    // hands the page `items: []` and it prints "Nothing here yet."
    error,
    refresh,
  };
};

export const useProduct = (
  id,
  { base = "/api/shop/products", keyPrefix = "product" } = {},
) => {
  const request = useApiFetch(() => `${base}/${toValue(id)}`, {
    key: () => `${keyPrefix}-${toValue(id)}`,
    // Client-side only: a click navigates at once and the page shows its skeleton rather
    // than freezing on the previous screen. On the server it still blocks, so the render
    // knows whether the record exists — a lazy SSR fetch resolves after the component has
    // already rendered, and Vue does not flush watchers there to catch up.
    lazy: import.meta.client,
    transform: (res) => res?.data ?? null,
    default: () => null,
    watch: [() => toValue(id), ...localeKeys()],
  });

  const { data, pending, error, status } = request;

  return { product: computed(() => data.value), pending, error, status };
};

/** The materials list and one material, through the same plumbing as the shop's. */
export const useMaterials = (query = {}) =>
  useProducts(query, {
    path: "/api/materials/products",
    key: "material-products",
  });

export const useMaterial = (id) =>
  useProduct(id, { base: "/api/materials/products", keyPrefix: "material" });

/**
 * The same id, on the other shelf.
 *
 * The two storefronts share a products table but not an endpoint, and **nothing the API
 * returns says which shelf a product is on** — `toApiSummary` carries no `section`, so a
 * cart line or a favourite read back from the server cannot be linked correctly. Every
 * one of those links therefore guesses `/shop`, and a bag of clay 404s there.
 *
 * Rather than guessing better in each place that renders a product, the two detail pages
 * check the other shelf before giving up. One request, only on a miss, and every wrong
 * link in the site lands somewhere real.
 *
 * @returns {Promise<string|null>} the path to redirect to, or null when it is genuinely gone.
 */
export const findOnOtherShelf = async (id, shelf) => {
  const other =
    shelf === "/materials"
      ? { path: "/shop", base: "/api/shop/products" }
      : { path: "/materials", base: "/api/materials/products" };

  try {
    const res = await useApi()(`${other.base}/${toValue(id)}`);
    return res?.data ? `${other.path}/${toValue(id)}` : null;
  } catch {
    return null;
  }
};

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
  });

  const { data, pending, error, status } = request;

  return { category: computed(() => data.value), pending, error, status };
};
