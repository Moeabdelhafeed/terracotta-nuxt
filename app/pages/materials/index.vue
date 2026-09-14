<template>
  <main>
    <PageHero
      media-key="hero_materials"
      fallback="/seed/hero-materials.webp"
      :crumbs="[
        {
          to: '/',
          label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }),
        },
        {
          label: t(
            'nav_materials',
            'Raw materials & tools',
            'المواد الخام والأدوات',
            { subGroup: 'general' },
          ),
        },
      ]"
      :title="
        t('materials_title', 'Raw materials & tools', 'المواد الخام والأدوات')
      "
      :subtitle="
        t(
          'materials_subtitle',
          'Clay, glazes and tools from the studio’s own shelves.',
          'طين وطلاءات وأدوات من رفوف الاستوديو نفسه.',
        )
      "
    />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <!-- Cart / favourites / orders: one basket serves both shelves, so the same three
         shortcuts belong here. -->
      <ShopQuickTiles class="mb-10 sm:max-w-md" />

      <!--
      Browsing only: filters, no basket. The top level is picked by picture — a real photo
      per category, same as the home page — and the row scrolls sideways rather than
      wrapping into an uneven block.
    -->
      <div class="mb-6 -mx-6 overflow-x-auto px-6 pb-2 pt-2">
        <ul class="flex w-max gap-4 sm:gap-5">
          <li>
            <button
              type="button"
              class="group w-16 sm:w-20"
              @click="pick(null)"
            >
              <span
                class="flex aspect-square items-center justify-center rounded-2xl bg-brand-rust/10 ring-2 ring-offset-2 ring-offset-background transition group-hover:brightness-95"
                :class="categoryId ? 'ring-transparent' : 'ring-primary'"
              >
                <LucideShapes class="size-6 text-brand-rust" />
              </span>
              <span
                class="mt-2 block truncate text-xs font-medium transition-colors"
                :class="categoryId ? 'text-muted-foreground' : 'text-primary'"
                >{{ t("all", "All", "الكل") }}</span
              >
            </button>
          </li>

          <li v-for="category in categories" :key="category.id">
            <button
              type="button"
              class="group w-16 sm:w-20"
              @click="pick(category.id)"
            >
              <span
                class="flex aspect-square items-center justify-center overflow-hidden rounded-2xl bg-brand-mist ring-2 ring-offset-2 ring-offset-background transition"
                :class="
                  categoryId === category.id
                    ? 'ring-primary'
                    : 'ring-transparent opacity-80 group-hover:opacity-100'
                "
              >
                <AppImage
                  v-if="category.image?.image_api"
                  :src="category.image"
                  :alt="category.title"
                  class="size-full object-cover transition-transform duration-500 group-hover:scale-110"
                />
                <LucideShapes v-else class="size-6 text-brand-rust" />
              </span>
              <span
                class="mt-2 block truncate text-xs font-medium transition-colors"
                :class="
                  categoryId === category.id
                    ? 'text-primary'
                    : 'text-muted-foreground'
                "
                >{{ category.title }}</span
              >
            </button>
          </li>
        </ul>
      </div>

      <!-- Sub-categories, once a category narrows things down. -->
      <div v-if="subCategories.length" class="mb-10 flex flex-wrap gap-2">
        <Button
          size="sm"
          :variant="!subCategoryId ? 'secondary' : 'ghost'"
          class="rounded-xl"
          @click="pickSub(null)"
        >
          {{ t("all_in_category", "All of these", "كل هذه") }}
        </Button>

        <Button
          v-for="sub in subCategories"
          :key="sub.id"
          size="sm"
          :variant="subCategoryId === sub.id ? 'secondary' : 'ghost'"
          class="rounded-xl"
          @click="pickSub(sub.id)"
          >{{ sub.title }}</Button
        >
      </div>

      <ShopProductFilters
        :query="route.query"
        @apply="apply"
        @clear="clearAll"
      />

      <!-- Skeletons hold the grid's shape while a filter or a page change is in flight, so
         the layout does not collapse and jump back. -->
      <ul
        v-if="pending"
        class="grid grid-cols-2 gap-5 lg:grid-cols-4"
        aria-busy="true"
      >
        <li v-for="n in PRODUCTS_PER_PAGE" :key="n">
          <ProductCardSkeleton />
        </li>
      </ul>

      <ul
        v-else-if="products.length"
        class="grid grid-cols-2 gap-5 lg:grid-cols-4"
      >
        <li v-for="product in products" :key="product.id">
          <ProductCard :product="product" base="/materials" />
        </li>
      </ul>

      <p v-else class="text-muted-foreground">
        {{ t("nothing_here", "Nothing here yet.", "لا يوجد شيء هنا بعد") }}
      </p>

      <!-- Real links, so a page is shareable and crawlable rather than a click handler. -->
      <nav
        v-if="lastPage > 1"
        class="mt-12 flex flex-wrap items-center justify-center gap-2"
      >
        <Button
          v-if="currentPage > 1"
          as-child
          size="sm"
          variant="outline"
          class="rounded-xl"
        >
          <NuxtLink :to="linkTo(currentPage - 1)" rel="prev">{{
            t("previous", "Previous", "السابق")
          }}</NuxtLink>
        </Button>

        <Button
          v-for="number in pageNumbers"
          :key="number"
          as-child
          size="sm"
          :variant="number === currentPage ? 'default' : 'outline'"
          class="min-w-10 rounded-xl"
        >
          <NuxtLink
            :to="linkTo(number)"
            :aria-current="number === currentPage ? 'page' : undefined"
          >
            {{ number }}
          </NuxtLink>
        </Button>

        <Button
          v-if="currentPage < lastPage"
          as-child
          size="sm"
          variant="outline"
          class="rounded-xl"
        >
          <NuxtLink :to="linkTo(currentPage + 1)" rel="next">{{
            t("next", "Next", "التالي")
          }}</NuxtLink>
        </Button>
      </nav>

      <p v-if="total" class="mt-6 text-center text-sm text-muted-foreground">
        {{ t("showing_count", ":total pieces", ":total قطعة", { total }) }}
      </p>
    </div>
  </main>
</template>

<script setup>
import {
  productApiQuery,
  PRODUCTS_PER_PAGE,
} from "~/components/shop/ShopProductFilters.vue";

const route = useRoute();
const router = useRouter();
const { t } = useLang("web", "home");
const { categories } = useMaterialCategories();

// The URL is the source of truth: filters and page are shareable, and the back button
// walks through them like any other navigation.
const categoryId = computed(() =>
  route.query.category ? Number(route.query.category) : null,
);
const subCategoryId = computed(() =>
  route.query.sub ? Number(route.query.sub) : null,
);
const currentPage = computed(() => Math.max(1, Number(route.query.page ?? 1)));

const { products, lastPage, total, pending } = useMaterials(
  computed(() => productApiQuery(route.query)),
);

const subCategories = computed(
  () =>
    categories.value.find((category) => category.id === categoryId.value)
      ?.sub_categories ?? [],
);

/** Any filter change starts again at page one; an unset value drops out of the URL. */
const apply = (patch) => {
  const query = { ...route.query, ...patch };
  delete query.page;

  Object.keys(query).forEach((key) => {
    if (query[key] === null || query[key] === undefined) delete query[key];
  });

  router.push({ query });
};

const pick = (id) => apply({ category: id, sub: null });
const pickSub = (id) => apply({ sub: id });
const clearAll = () => router.push({ query: {} });

/** A short window of page numbers around the current one. */
const pageNumbers = computed(() => {
  const last = lastPage.value;
  const span = 2;
  const from = Math.max(1, currentPage.value - span);
  const to = Math.min(last, currentPage.value + span);

  return Array.from({ length: to - from + 1 }, (_, i) => from + i);
});

const linkTo = (page) => ({
  query: { ...route.query, page: page > 1 ? page : undefined },
});

// ScrollSmoother owns the scroll position, so paging has to send the visitor back up.
watch(currentPage, async () => {
  const { ScrollSmoother } = await import("gsap/all");
  ScrollSmoother.get?.()?.scrollTo(0, true);
});

const { media: heroMedia } = useMedia("web", "heroes");

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`;

useSeoMeta({
  title: () =>
    t("materials_title", "Raw materials & tools", "المواد الخام والأدوات"),
  description: () =>
    t(
      "materials_subtitle",
      "Clay, glazes and tools from the studio’s own shelves.",
      "طين وطلاءات وأدوات من رفوف الاستوديو نفسه.",
    ),
  ogImage: () => heroMedia("hero_materials") ?? fallbackCard,
});

useSchemaOrg([
  defineBreadcrumb({
    itemListElement: [
      {
        name: t("nav_home", "Home", "الرئيسية", { subGroup: "general" }),
        item: "/",
      },
      {
        name: t(
          "nav_materials",
          "Raw materials & tools",
          "المواد الخام والأدوات",
          { subGroup: "general" },
        ),
        item: "/materials",
      },
    ],
  }),
]);
</script>
