/**
 * The About page and the two things filed under it: the studio's projects for hotels and
 * restaurants ("مشاريعنا") and its news ("أخبار تيراكوتا"). All public, all read-only.
 *
 * Lists are fetched in full by default; pass `per_page` to take only the first few (the
 * About page's teasers do). Either way `items` is a plain array.
 */
const localeKeys = () => [useCookie("lang"), useCookie("i18n_locale")];

const listOf = (res) => {
  const payload = res?.data;
  return asList(Array.isArray(payload) ? payload : payload?.data);
};

/** The blocks below the About hero, in the studio's order (`GET /api/about/sections`). */
export const useAboutSections = () => {
  const { data, pending, error, refresh } = useApiFetch("/api/about/sections", {
    key: "about-sections",
    transform: (res) => asList(res?.data),
    default: () => [],
    watch: localeKeys(),
    // The server still renders the page whole; a click from inside the site paints the
    // hero at once and shimmers where the sections will land.
    lazy: import.meta.client,
  });

  return { sections: computed(() => asList(data.value)), pending, error, refresh };
};

const aboutList = (path, query, key) => {
  const { data, pending, error, refresh } = useApiFetch(path, {
    key,
    query,
    transform: listOf,
    default: () => [],
    watch: localeKeys(),
    // A move between the About pages paints at once; the list fills in behind it.
    lazy: import.meta.client,
  });

  return { items: computed(() => asList(data.value)), pending, error, refresh };
};

const aboutRecord = (base, id, keyPrefix) => {
  const { data, pending, error, status } = useApiFetch(() => `${base}/${toValue(id)}`, {
    key: () => `${keyPrefix}-${toValue(id)}`,
    // As every detail page: blocking on the server so a missing record is a real 404,
    // free on a client move so the tap answers at once.
    lazy: import.meta.client,
    transform: (res) => res?.data ?? null,
    default: () => null,
    watch: [() => toValue(id), ...localeKeys()],
  });

  return { record: computed(() => data.value), pending, error, status };
};

/** `query` may hold refs: `category_id`, `per_page`. */
export const useProjects = (query = {}, key = "projects") =>
  aboutList("/api/projects", query, key);

export const useProject = (id) => aboutRecord("/api/projects", id, "project");

/** `query` may hold refs: `category_id`, `per_page`. */
export const useNews = (query = {}, key = "news") =>
  aboutList("/api/news", query, key);

export const useNewsItem = (id) => aboutRecord("/api/news", id, "news-item");

/**
 * The categories a list actually uses, in the studio's order (the order they were created
 * in the CMS). Categories are the studio's own and already arrive named in the reader's
 * language, so a "Cafés" pill only appears once there is a café to show.
 */
export const categoriesOf = (items) => {
  const seen = new Map();
  for (const item of items ?? []) {
    if (item?.category && !seen.has(item.category.id)) seen.set(item.category.id, item.category);
  }
  return [...seen.values()].sort((a, b) => a.id - b.id);
};

export const useAboutLabels = () => {
  const { t, code } = useLang("web", "about");

  // The client's own name when the studio gave one; otherwise the kind of place and where.
  const clientLine = (project) =>
    [project?.client_name || project?.category?.name, project?.city]
      .filter(Boolean)
      .join(" · ");

  // A calendar date, read in no timezone: an event on the 12th is on the 12th for everyone.
  const day = (value, options = { day: "numeric", month: "long", year: "numeric" }) =>
    value
      ? new Date(`${value}T00:00:00`).toLocaleDateString(
          code.value === "ar" ? "ar" : "en-GB",
          options,
        )
      : "";

  const dateRange = (item) => {
    if (!item?.starts_on) return "";
    if (!item.ends_on || item.ends_on === item.starts_on) return day(item.starts_on);
    return `${day(item.starts_on)} – ${day(item.ends_on)}`;
  };

  return { t, clientLine, day, dateRange };
};
