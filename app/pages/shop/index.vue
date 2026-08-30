<template>
  <main>
    <PageHero
      media-key="hero_shop"
      :title="t('shop_title', 'The shop', 'المتجر')"
      :subtitle="t('shop_subtitle', 'Every piece is thrown, glazed and fired in our studio.', 'كل قطعة تُصنع وتُطلى وتُحرق في الاستوديو.')"
    />

    <div class="mx-auto max-w-6xl px-6 py-16">

    <!--
      Browsing only: filters, no basket. The top level is picked by picture — the cut-outs
      are transparent PNGs, so each sits on a terracotta disc as it does on the home page,
      and the row scrolls sideways rather than wrapping into an uneven block.
    -->
    <div class="mb-6 -mx-6 overflow-x-auto px-6 pb-2 pt-2">
      <ul class="flex w-max gap-4 sm:gap-5">
        <li>
          <button type="button" class="group w-16 sm:w-20" @click="pick(null)">
            <span
              class="flex aspect-square items-center justify-center rounded-full bg-brand-mist ring-2 ring-offset-2 ring-offset-background transition group-hover:brightness-95"
              :class="categoryId ? 'ring-transparent' : 'ring-primary'"
            >
              <LucideShapes class="size-6 text-brand-rust" />
            </span>
            <span
              class="mt-2 block truncate text-xs font-medium transition-colors"
              :class="categoryId ? 'text-muted-foreground' : 'text-primary'"
            >{{ t('all', 'All', 'الكل') }}</span>
          </button>
        </li>

        <li v-for="category in categories" :key="category.id">
          <button type="button" class="group w-16 sm:w-20" @click="pick(category.id)">
            <span
              class="flex aspect-square items-center justify-center overflow-hidden rounded-full bg-brand-terracotta p-3 ring-2 ring-offset-2 ring-offset-background transition"
              :class="categoryId === category.id ? 'ring-primary' : 'ring-transparent opacity-80 group-hover:opacity-100'"
            >
              <AppImage
                v-if="category.image?.image_api"
                :src="category.image"
                :alt="category.title"
                class="size-full object-contain transition-transform duration-500 group-hover:scale-110"
              />
              <LucideShapes v-else class="size-6 text-white/80" />
            </span>
            <span
              class="mt-2 block truncate text-xs font-medium transition-colors"
              :class="categoryId === category.id ? 'text-primary' : 'text-muted-foreground'"
            >{{ category.title }}</span>
          </button>
        </li>
      </ul>
    </div>

    <!-- Sub-categories, once a category narrows things down. -->
    <div v-if="subCategories.length" class="mb-10 flex flex-wrap gap-2">
      <Button size="sm" :variant="!subCategoryId ? 'secondary' : 'ghost'" class="rounded-full" @click="pickSub(null)">
        {{ t('all_in_category', 'All of these', 'كل هذه') }}
      </Button>

      <Button
        v-for="sub in subCategories"
        :key="sub.id"
        size="sm"
        :variant="subCategoryId === sub.id ? 'secondary' : 'ghost'"
        class="rounded-full"
        @click="pickSub(sub.id)"
      >{{ sub.title }}</Button>
    </div>

    <!-- Search and the two flags the API filters on. Sorting and price ranges are not
         offered because the endpoint ignores them — the list is paged server-side, so
         reordering here would only reorder the page in view. -->
    <div class="mb-10 flex flex-wrap items-center gap-3">
      <div class="relative min-w-[14rem] flex-1">
        <LucideSearch class="pointer-events-none absolute top-1/2 size-4.5 -translate-y-1/2 text-muted-foreground ltr:left-3 rtl:right-3" />
        <Input
          v-model="term"
          type="search"
          class="h-12 rounded-full text-base ltr:pl-10 rtl:pr-10"
          :placeholder="t('search_pieces', 'Search pieces…', 'ابحث عن قطعة…')"
        />
      </div>

      <Button
        :variant="featured ? 'default' : 'outline'"
        class="h-12 rounded-full px-6"
        @click="apply({ featured: featured ? null : 1 })"
      >{{ t('featured', 'Featured', 'مميز') }}</Button>

      <Button
        :variant="onSale ? 'default' : 'outline'"
        class="h-12 rounded-full px-6"
        @click="apply({ sale: onSale ? null : 1 })"
      >{{ t('on_sale', 'On sale', 'خصم') }}</Button>

      <Button
        v-if="hasFilters"
        variant="ghost"
        class="h-12 rounded-full px-5 text-muted-foreground"
        @click="clearAll"
      >{{ t('clear_filters', 'Clear', 'مسح') }}</Button>
    </div>

    <ul v-if="products.length" class="grid grid-cols-2 gap-5 lg:grid-cols-4">
      <li v-for="product in products" :key="product.id">
        <ProductCard :product="product" />
      </li>
    </ul>

    <p v-else-if="pending" class="text-muted-foreground">{{ t('loading', 'Loading…', 'جارٍ التحميل…') }}</p>
    <p v-else class="text-muted-foreground">{{ t('nothing_here', 'Nothing here yet.', 'لا يوجد شيء بعد.') }}</p>

    <!-- Real links, so a page is shareable and crawlable rather than a click handler. -->
    <nav v-if="lastPage > 1" class="mt-12 flex flex-wrap items-center justify-center gap-2">
      <Button
        v-if="currentPage > 1"
        as-child
        size="sm"
        variant="outline"
        class="rounded-full"
      >
        <NuxtLink :to="linkTo(currentPage - 1)" rel="prev">{{ t('previous', 'Previous', 'السابق') }}</NuxtLink>
      </Button>

      <Button
        v-for="number in pageNumbers"
        :key="number"
        as-child
        size="sm"
        :variant="number === currentPage ? 'default' : 'outline'"
        class="min-w-10 rounded-full"
      >
        <NuxtLink :to="linkTo(number)" :aria-current="number === currentPage ? 'page' : undefined">
          {{ number }}
        </NuxtLink>
      </Button>

      <Button
        v-if="currentPage < lastPage"
        as-child
        size="sm"
        variant="outline"
        class="rounded-full"
      >
        <NuxtLink :to="linkTo(currentPage + 1)" rel="next">{{ t('next', 'Next', 'التالي') }}</NuxtLink>
      </Button>
    </nav>

      <p v-if="total" class="mt-6 text-center text-sm text-muted-foreground">
        {{ t('showing_count', ':total pieces', ':total قطعة', { total }) }}
      </p>
    </div>
  </main>
</template>

<script setup>
const route = useRoute()
const router = useRouter()
const { t } = useLang('web', 'home')
const { categories } = useShopCategories()

const PER_PAGE = 12

// The URL is the source of truth: filters and page are shareable, and the back button
// walks through them like any other navigation.
const categoryId = computed(() => (route.query.category ? Number(route.query.category) : null))
const subCategoryId = computed(() => (route.query.sub ? Number(route.query.sub) : null))
const currentPage = computed(() => Math.max(1, Number(route.query.page ?? 1)))
const search = computed(() => route.query.search ?? '')
const featured = computed(() => route.query.featured === '1')
const onSale = computed(() => route.query.sale === '1')

const { products, lastPage, total, pending } = useProducts({
  category_id: categoryId,
  sub_category_id: subCategoryId,
  search: computed(() => search.value || undefined),
  featured: computed(() => (featured.value ? 1 : undefined)),
  on_sale: computed(() => (onSale.value ? 1 : undefined)),
  page: currentPage,
  per_page: PER_PAGE,
})

const hasFilters = computed(() => Boolean(categoryId.value || search.value || featured.value || onSale.value))

const subCategories = computed(() =>
  categories.value.find((category) => category.id === categoryId.value)?.sub_categories ?? [],
)

/** Any filter change starts again at page one; an unset value drops out of the URL. */
const apply = (patch) => {
  const query = { ...route.query, ...patch }
  delete query.page

  Object.keys(query).forEach((key) => {
    if (query[key] === null || query[key] === undefined) delete query[key]
  })

  router.push({ query })
}

const pick = (id) => apply({ category: id, sub: null })
const pickSub = (id) => apply({ sub: id })
const clearAll = () => router.push({ query: {} })

// The box is free to type in; the URL only catches up once typing settles, so the back
// button walks whole searches rather than every keystroke.
const term = ref(search.value)
watch(search, (value) => { if (value !== term.value) term.value = value })
watchDebounced(term, (value) => apply({ search: value || null }), { debounce: 400 })

/** A short window of page numbers around the current one. */
const pageNumbers = computed(() => {
  const last = lastPage.value
  const span = 2
  const from = Math.max(1, currentPage.value - span)
  const to = Math.min(last, currentPage.value + span)

  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

const linkTo = (page) => ({ query: { ...route.query, page: page > 1 ? page : undefined } })

// ScrollSmoother owns the scroll position, so paging has to send the visitor back up.
watch(currentPage, async () => {
  const { ScrollSmoother } = await import('gsap/all')
  ScrollSmoother.get?.()?.scrollTo(0, true)
})

useSeoMeta({ title: () => t('shop_title', 'The shop', 'المتجر') })
</script>
