<template>
  <ProductDetailView
    :product="product"
    :status="status"
    section-to="/shop"
    :section-label="t('nav_shop', 'Shop', 'المتجر', { subGroup: 'general' })"
  />
</template>

<script setup>
const route = useRoute();
const { product, error, status } = useProduct(() => route.params.id);

// A record that does not exist, or a lookup that failed, hands over to the site's error
// page — the markup's `v-if` would otherwise match nothing and leave a blank screen.
//
// Keyed on `status`, not on `pending`: a client-side navigation arrives with the fetch not
// yet started, where `pending` is still false and the record still null — reading that as
// "not found" 404s a product that exists, until you refresh.
watchEffect(() => {
  if (
    status.value === "error" ||
    (status.value === "success" && !product.value)
  ) {
    showError({
      statusCode: error.value?.statusCode ?? 404,
      statusMessage: "Product not found",
    });
  }
});

const { t } = useLang("web", "home");

// The API's description is HTML; meta tags and schema both want plain text.
const stripTags = (html) =>
  String(html ?? "")
    .replace(/<[^>]*>/g, " ")
    .replace(/\s+/g, " ")
    .trim();

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`;

useSeoMeta({
  title: () => product.value?.title ?? "",
  description: () =>
    stripTags(product.value?.description) ||
    t(
      "shop_subtitle",
      "Every piece is thrown, glazed and fired in our studio.",
      "كل قطعة تُصنع وتُطلى وتُحرق في الاستوديو.",
    ),
  ogImage: () => product.value?.image?.image_api ?? fallbackCard,
  ogType: "product",
});

// The piece itself, as a shopping result: name, picture, price and whether it can be had.
const crumbs = computed(() =>
  productCrumbs({
    product: product.value,
    sectionTo: '/shop',
    sectionLabel: t('nav_shop', 'Shop', 'المتجر', { subGroup: 'general' }),
    t,
  }),
)

useSchemaOrg([
  defineProduct({
    name: () => product.value?.title ?? "",
    description: () => stripTags(product.value?.description),
    image: () => product.value?.image?.image_api,
    offers: () => [
      {
        price: Number(product.value?.sale_price ?? product.value?.price ?? 0),
        priceCurrency: "SAR",
        availability:
          product.value?.in_stock === false
            ? "https://schema.org/OutOfStock"
            : "https://schema.org/InStock",
      },
    ],
  }),
  defineBreadcrumb({
    itemListElement: () =>
      crumbs.value.map((crumb) => ({ name: crumb.label, item: crumb.to })),
  }),
]);
</script>
