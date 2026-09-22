<template>
  <div class="mb-10 flex flex-col gap-4">
    <div class="flex flex-wrap items-center gap-3">
      <div class="relative min-w-[14rem] flex-1">
        <LucideSearch
          class="pointer-events-none absolute top-1/2 size-4.5 -translate-y-1/2 text-muted-foreground ltr:left-3 rtl:right-3"
        />
        <Input
          v-model="term"
          type="search"
          class="h-12 rounded-xl text-base ltr:pl-10 rtl:pr-10"
          :placeholder="t('search_pieces', 'Search pieces…', 'ابحث عن قطعة…')"
        />
      </div>

      <Select v-model="sort">
        <SelectTrigger
          data-test="product-sort"
          :aria-label="t('sort_by', 'Sort by', 'ترتيب حسب')"
          class="h-12 rounded-xl text-base"
        >
          {{ sortLabel(sort) }}
        </SelectTrigger>
        <SelectContent>
          <SelectItem :value="CURATED">
            {{ t("sort_curated", "Studio order", "ترتيب الاستوديو") }}
          </SelectItem>
          <SelectItem v-for="option in SORTS" :key="option" :value="option">
            {{ sortLabel(option) }}
          </SelectItem>
        </SelectContent>
      </Select>

      <Button
        :variant="featured ? 'default' : 'outline'"
        class="h-12 rounded-xl px-6"
        @click="emit('apply', { featured: featured ? null : 1 })"
        >{{ t("featured", "Featured", "مميز") }}</Button
      >

      <Button
        :variant="onSale ? 'default' : 'outline'"
        class="h-12 rounded-xl px-6"
        @click="emit('apply', { sale: onSale ? null : 1 })"
        >{{ t("on_sale", "On sale", "العروض") }}</Button
      >
    </div>

    <!-- Two bounds rather than a slider: the catalogue has no published ceiling to draw
         one against, and a shopper who knows their budget types it. -->
    <div class="flex flex-wrap items-center gap-3">
      <div
        class="flex h-12 items-center gap-2 rounded-xl border border-input px-3"
      >
        <LucideTag class="size-4 shrink-0 text-muted-foreground" />
        <span class="text-sm text-muted-foreground">{{
          t("price_range", "Price", "السعر")
        }}</span>
        <Input
          v-model="minInput"
          data-test="price-min"
          type="number"
          inputmode="decimal"
          min="0"
          :max="PRICE_CEILING"
          class="h-10 w-20 rounded-lg border-0 px-2 text-sm shadow-none focus-visible:ring-0 sm:h-8"
          :placeholder="t('price_min', 'Min', 'من')"
          :aria-label="t('price_min', 'Min', 'من')"
        />
        <span aria-hidden="true" class="text-muted-foreground">–</span>
        <Input
          v-model="maxInput"
          data-test="price-max"
          type="number"
          inputmode="decimal"
          min="0"
          :max="PRICE_CEILING"
          class="h-10 w-20 rounded-lg border-0 px-2 text-sm shadow-none focus-visible:ring-0 sm:h-8"
          :placeholder="t('price_max', 'Max', 'إلى')"
          :aria-label="t('price_max', 'Max', 'إلى')"
        />
        <button
          v-if="minInput !== '' || maxInput !== ''"
          type="button"
          data-test="price-clear"
          class="text-muted-foreground transition-colors hover:text-foreground"
          :aria-label="t('clear_price', 'Clear price', 'مسح السعر')"
          @click="clearPrice"
        >
          <LucideX class="size-4" />
        </button>
      </div>

      <span
        v-if="priceInverted"
        data-test="price-hint"
        class="text-xs text-destructive"
      >
        {{
          t(
            "price_range_invalid",
            "The highest price has to be above the lowest.",
            "يجب أن يكون السعر الأعلى أكبر من الأدنى.",
          )
        }}
      </span>
    </div>

    <div
      v-if="chips.length"
      class="flex flex-wrap items-center gap-2"
      data-test="active-filters"
    >
      <span class="text-xs text-muted-foreground">{{
        t("active_filters", "Filtering by", "التصفية حسب")
      }}</span>

      <button
        v-for="chip in chips"
        :key="chip.key"
        type="button"
        class="flex items-center gap-1.5 rounded-full bg-brand-mist px-3 py-1.5 text-xs font-medium text-foreground transition hover:brightness-95"
        @click="emit('apply', chip.patch)"
      >
        {{ chip.label }}
        <LucideX class="size-3.5 text-muted-foreground" />
      </button>

      <Button
        variant="ghost"
        size="sm"
        class="rounded-full text-muted-foreground"
        @click="emit('clear')"
      >
        {{ t("clear_filters", "Clear", "مسح") }}
      </Button>
    </div>
  </div>
</template>

<script>
export const PRODUCTS_PER_PAGE = 12;

export const SORTS = ["newest", "price_asc", "price_desc"];

/** Nothing above this is a pottery price; it only stops a stray keystroke reaching the API. */
export const PRICE_CEILING = 99999;

const positiveNumber = (value) => {
  if (value === null || value === undefined || String(value).trim() === "")
    return undefined;
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount < 0) return undefined;
  return Math.min(amount, PRICE_CEILING);
};

/**
 * The URL's query is the filter state; this is the API query it means.
 *
 * Keys that mean nothing are dropped rather than sent empty — in particular `sort`, whose
 * absence is what keeps the studio's own catalogue order. A `max_price` under `min_price`
 * is dropped too: the endpoint answers 422 on it, and a shopper mid-typing is not an error.
 */
export const productApiQuery = (query = {}, perPage = PRODUCTS_PER_PAGE) => {
  const min = positiveNumber(query.min_price);
  const max = positiveNumber(query.max_price);

  const all = {
    category_id: query.category ? Number(query.category) : undefined,
    sub_category_id: query.sub ? Number(query.sub) : undefined,
    search: query.search || undefined,
    featured: query.featured === "1" ? 1 : undefined,
    on_sale: query.sale === "1" ? 1 : undefined,
    min_price: min,
    max_price:
      max !== undefined && (min === undefined || max >= min) ? max : undefined,
    sort: SORTS.includes(query.sort) ? query.sort : undefined,
    page: Math.max(1, Number(query.page ?? 1) || 1),
    per_page: perPage,
  };

  return Object.fromEntries(
    Object.entries(all).filter(([, value]) => value !== undefined),
  );
};
</script>

<script setup>
/**
 * Search, sort, price and the two flags, all of it mirrored in the URL by the page: the
 * component never navigates, it only says which query keys changed.
 */
const props = defineProps({
  query: { type: Object, default: () => ({}) },
});

const emit = defineEmits(["apply", "clear"]);

const { t } = useLang("web", "home");
const { format } = usePrice();
const { categories } = useShopCategories();

const featured = computed(() => props.query.featured === "1");
const onSale = computed(() => props.query.sale === "1");

/**
 * The studio's own catalogue order is "no sort" on the wire, but a Select item cannot
 * carry an empty value — reka rejects one — so it travels under a name and is turned
 * back into `null` on the way out.
 */
const CURATED = "curated";

const sortLabel = (value) =>
  ({
    [CURATED]: t("sort_curated", "Studio order", "ترتيب الاستوديو"),
    newest: t("sort_newest", "Newest first", "الأحدث أولاً"),
    price_asc: t("sort_price_asc", "Price: low to high", "السعر: من الأقل"),
    price_desc: t("sort_price_desc", "Price: high to low", "السعر: من الأعلى"),
  })[value] ?? value;

const sort = computed({
  get: () => (SORTS.includes(props.query.sort) ? props.query.sort : CURATED),
  set: (value) => emit("apply", { sort: value === CURATED ? null : value }),
});

// Typed values stay local until they settle, so a three-digit budget is one request and
// one history entry rather than three of each.
const term = ref(props.query.search ?? "");
const minInput = ref(props.query.min_price ?? "");
const maxInput = ref(props.query.max_price ?? "");

watch(
  () => props.query,
  (query) => {
    if ((query.search ?? "") !== term.value) term.value = query.search ?? "";
    if ((query.min_price ?? "") !== minInput.value)
      minInput.value = query.min_price ?? "";
    if ((query.max_price ?? "") !== maxInput.value)
      maxInput.value = query.max_price ?? "";
  },
);

const priceInverted = computed(() => {
  const min = positiveNumber(minInput.value);
  const max = positiveNumber(maxInput.value);
  return min !== undefined && max !== undefined && max < min;
});

watchDebounced(term, (value) => emit("apply", { search: value || null }), {
  debounce: 400,
});

watchDebounced(
  [minInput, maxInput],
  () => {
    if (priceInverted.value) return;
    emit("apply", {
      min_price: positiveNumber(minInput.value) ?? null,
      max_price: positiveNumber(maxInput.value) ?? null,
    });
  },
  { debounce: 500 },
);

const clearPrice = () => {
  minInput.value = "";
  maxInput.value = "";
};

const categoryTitle = (id) =>
  categories.value.find((category) => category.id === id)?.title ?? "";

const subCategoryTitle = (id) =>
  categories.value
    .flatMap((category) => category.sub_categories ?? [])
    .find((sub) => sub.id === id)?.title ?? "";

const priceChipLabel = () => {
  const { min_price: min, max_price: max } = productApiQuery(props.query);
  if (min !== undefined && max !== undefined)
    return `${format(min)} – ${format(max)}`;
  if (min !== undefined)
    return t("price_from", "From :amount", "من :amount", {
      amount: format(min),
    });
  return t("price_up_to", "Up to :amount", "حتى :amount", {
    amount: format(max),
  });
};

const chips = computed(() => {
  const query = props.query;
  const applied = productApiQuery(query);
  const list = [];

  if (applied.category_id) {
    list.push({
      key: "category",
      label: categoryTitle(applied.category_id),
      patch: { category: null, sub: null },
    });
  }
  if (applied.sub_category_id) {
    list.push({
      key: "sub",
      label: subCategoryTitle(applied.sub_category_id),
      patch: { sub: null },
    });
  }
  if (applied.search) {
    list.push({
      key: "search",
      label: `“${applied.search}”`,
      patch: { search: null },
    });
  }
  if (applied.featured) {
    list.push({
      key: "featured",
      label: t("featured", "Featured", "مميز"),
      patch: { featured: null },
    });
  }
  if (applied.on_sale) {
    list.push({
      key: "sale",
      label: t("on_sale", "On sale", "العروض"),
      patch: { sale: null },
    });
  }
  if (applied.min_price !== undefined || applied.max_price !== undefined) {
    list.push({
      key: "price",
      label: priceChipLabel(),
      patch: { min_price: null, max_price: null },
    });
  }
  if (applied.sort) {
    list.push({
      key: "sort",
      label: sortLabel(applied.sort),
      patch: { sort: null },
    });
  }

  return list.filter((chip) => chip.label);
});
</script>
