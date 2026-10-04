/**
 * The coffee house menu (`GET /api/coffee-house`) and the items the studio featured for
 * the home page (`GET /api/coffee-house/featured`). Public and read-only: the menu is
 * read here, and the order is placed at the counter.
 */
const localeKeys = () => [useCookie("lang"), useCookie("i18n_locale")];

const listOf = (res) => {
  const payload = res?.data;
  return asList(Array.isArray(payload) ? payload : payload?.data);
};

/** Sections in the studio's order, each with its `items`. */
export const useCoffeeMenu = () => {
  const { data, pending, error, refresh } = useApiFetch("/api/coffee-house", {
    key: "coffee-menu",
    transform: listOf,
    default: () => [],
    watch: localeKeys(),
    // A move from inside the site paints the hero at once and shimmers below it.
    lazy: import.meta.client,
  });

  return { sections: computed(() => asList(data.value)), pending, error, refresh };
};

export const useCoffeeFeatured = (perPage = 4) => {
  const { data, pending } = useApiFetch("/api/coffee-house/featured", {
    key: "coffee-featured",
    query: { per_page: perPage },
    transform: listOf,
    default: () => [],
    watch: localeKeys(),
    lazy: import.meta.client,
  });

  return { items: computed(() => asList(data.value)), pending };
};
