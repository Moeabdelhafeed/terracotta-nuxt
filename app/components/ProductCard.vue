<template>
  <NuxtLink
    :to="`${base}/${product.id}`"
    class="group block overflow-hidden rounded-card border bg-card"
    :class="{ 'opacity-55': soldOut }"
  >
    <div class="relative aspect-square overflow-hidden bg-brand-container">
      <AppImage
        v-if="product.image?.image_api"
        :src="product.image"
        :alt="product.title"
        class="size-full object-cover transition-transform duration-500 group-hover:scale-105"
      />

      <!-- The heart and the saving share the start corner, stacked; «مميز» keeps the
           end one. They are different facts — the price talking and the studio talking —
           so a piece can carry either, both or neither and nothing has to move. -->
      <div
        class="absolute top-3 flex flex-col items-start gap-1.5 ltr:left-3 rtl:right-3"
      >
        <ShopFavoriteButton :product="product" />

        <span
          v-if="discount"
          class="rounded-[6px] bg-success px-2 py-0.5 text-xs font-bold text-success-foreground"
          >{{ t("discount_percent", "-:n%", "-:n٪", { n: discount }) }}</span
        >
      </div>

      <span
        v-if="product.is_featured"
        class="absolute top-3 rounded-[6px] bg-primary px-2 py-0.5 text-xs font-semibold text-primary-foreground ltr:right-3 rtl:left-3"
        >{{ t("featured", "Featured", "مميز") }}</span
      >

      <span
        v-if="soldOut"
        class="absolute bottom-3 rounded-[6px] bg-brand-ink/85 px-2 py-0.5 text-xs font-medium text-white ltr:left-3 rtl:right-3"
        >{{
          t("sold_out", "Sold out", "نفدت الكمية", { subGroup: "shop" })
        }}</span
      >
    </div>

    <div class="p-3">
      <p class="truncate text-sm">{{ product.title }}</p>

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
