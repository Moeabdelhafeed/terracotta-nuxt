<template>
  <ProductDetailView
    :product="product"
    :status="status"
    section-to="/materials"
    :section-label="
      t('nav_materials', 'Raw materials & tools', 'المواد الخام والأدوات', {
        subGroup: 'general',
      })
    "
  />
</template>

<script setup>
// A piece speaks for itself, and the bar above carries the way back to its shelf — the
// site's whole navigation under it is noise.

const route = useRoute();
const { product, error, status } = useMaterial(() => route.params.id);

// A record that does not exist, or a lookup that failed, hands over to the site's error
// page — the markup's `v-if` would otherwise match nothing and leave a blank screen.
//
// Keyed on `status`, not on `pending`: a client-side navigation arrives with the fetch not
// yet started, where `pending` is still false and the record still null — reading that as
// "not found" 404s a product that exists, until you refresh.
watchEffect(async () => {
  if (
    status.value !== "error" &&
    !(status.value === "success" && !product.value)
  )
    return;

  // Nothing the API returns says which shelf a product is on, so every link built from a
  // cart line or a favourite has to guess — and the guess is `/shop`. Before calling it
  // gone, look for it on the other one.
  const elsewhere = await findOnOtherShelf(route.params.id, "/materials");
  if (elsewhere) return navigateTo(elsewhere, { replace: true });

  showError({
    statusCode: error.value?.statusCode ?? 404,
    statusMessage: "Product not found",
  });
});

const { t } = useLang("web", "home");

// The API's description is HTML; meta tags and schema both want plain text.
const stripTags = (html) =>
  String(html ?? "")
    .replace(/<[^>]*>/g, " ")
    .replace(/\s+/g, " ")
    .trim();


useSeoMeta({
  title: () => product.value?.title ?? "",
  description: () =>
    stripTags(product.value?.description) ||
    t(
      "materials_subtitle",
      "Clay, glazes and tools from the studio’s own shelves.",
      "طين وطلاءات وأدوات من رفوف الاستوديو نفسه.",
    ),
  ogType: "product",
});

// The piece itself, as a shopping result: name, picture, price and whether it can be had.
const crumbs = computed(() =>
  productCrumbs({
    product: product.value,
    sectionTo: '/materials',
    sectionLabel: t('nav_materials', 'Materials', 'المواد', { subGroup: 'general' }),
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
