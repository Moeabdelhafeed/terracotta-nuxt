<template>
  <NuxtLink
    :to="`${shelf}/${product.id}`"
    class="group block overflow-hidden rounded-card border bg-card transition-[transform,box-shadow] duration-200 hover:-translate-y-0.5 hover:shadow-md active:translate-y-0"
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

/**
 * Where this card links. `base` is right whenever the list itself knows which shelf it
 * came from, but the favourites list does not — the two storefronts share one table, so a
 * hearted bag of clay arrives in the same payload as a hearted mug. `section` on the
 * product settles it when the API sends one; until it does, a favourited material still
 * links into /shop and 404s there, because `show()` filters by section.
 */
const shelf = computed(() =>
  props.product?.section === "materials" ? "/materials" : props.base,
);

// Sold out stays in the list, greyed — hiding it hides the reason it cannot be bought.
const soldOut = computed(() => props.product.in_stock === false);

// Truncated, not rounded, and in halalas: rounding up printed "-24%" beside 65.00 and
// 49.50, which is 23.8% — a number the customer cannot verify against the two prices
// sitting next to it.
const discount = computed(() => {
  const price = toHalalas(props.product.price);
  const sale = toHalalas(props.product.sale_price);
  if (!price || !sale || sale >= price) return 0;
  return Math.floor(((price - sale) * 100) / price);
});
</script>
