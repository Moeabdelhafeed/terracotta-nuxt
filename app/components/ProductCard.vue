<template>
  <NuxtLink
    :to="`${base}/${product.id}`"
    class="group block overflow-hidden rounded-2xl border bg-card"
  >
    <div
      class="relative aspect-square overflow-hidden"
      :class="{ 'opacity-60': soldOut }"
    >
      <AppImage
        v-if="product.image?.image_api"
        :src="product.image"
        :alt="product.title"
        class="size-full object-cover transition-transform duration-500 group-hover:scale-105"
        :class="{ grayscale: soldOut }"
      />
      <span
        v-if="discount"
        class="absolute top-3 rounded-md bg-primary px-2.5 py-1 text-xs font-medium text-primary-foreground ltr:left-3 rtl:right-3"
        >{{ t("discount_percent", "-:n%", "-:n٪", { n: discount }) }}</span
      >

      <ShopFavoriteButton
        class="absolute top-3 ltr:right-3 rtl:left-3"
        :product="product"
      />

      <span
        v-if="product.is_featured"
        class="absolute bottom-3 rounded-md bg-primary px-2.5 py-1 text-xs font-medium text-primary-foreground ltr:left-3 rtl:right-3"
        >{{ t("featured", "Featured", "مميز") }}</span
      >

      <span
        v-if="soldOut"
        class="absolute inset-x-3 bottom-3 rounded-md bg-brand-ink/85 py-1 text-center text-xs font-medium text-white"
        >{{
          t("sold_out", "Sold out", "نفدت الكمية", { subGroup: "shop" })
        }}</span
      >
    </div>

    <div class="p-3">
      <p class="truncate text-sm font-medium">{{ product.title }}</p>

      <p class="mt-1 flex flex-wrap items-baseline gap-x-2">
        <span
          v-if="product.sale_price"
          class="text-sm text-muted-foreground line-through"
          >{{ format(product.price) }}</span
        >
        <span class="font-display text-lg font-black text-primary">
          {{ format(product.sale_price ?? product.price) }}
        </span>
      </p>
    </div>
  </NuxtLink>
</template>

<script setup>
/**
 * One piece, as it appears in every list: the home grids, the shop listing and the
 * related strip on a product page. The list payload is the same shape everywhere
 * (`id`, `title`, `image`, `price`, `sale_price`), so they all render identically.
 */
const props = defineProps({
  /** The shelf this card links into — the shop, or raw materials and tools. */
  base: { type: String, default: "/shop" },
  product: { type: Object, required: true },
});

const { t } = useLang("web", "home");
const { format } = usePrice();

// Sold out stays in the list, greyed — hiding it hides the reason it cannot be bought.
const soldOut = computed(() => props.product.in_stock === false);

const discount = computed(() => {
  const price = Number(props.product.price ?? 0);
  const sale = Number(props.product.sale_price ?? 0);
  if (!price || !sale || sale >= price) return 0;
  return Math.round(((price - sale) / price) * 100);
});
</script>
