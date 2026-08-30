<template>
  <NuxtLink :to="`/shop/${product.id}`" class="group block">
    <div class="relative aspect-square overflow-hidden rounded-2xl border bg-card">
      <AppImage
        v-if="product.image?.image_api"
        :src="product.image"
        :alt="product.title"
        class="size-full object-cover transition-transform duration-500 group-hover:scale-105"
      />
      <span
        v-if="discount"
        class="absolute top-3 rounded-full bg-primary px-2.5 py-1 text-xs font-medium text-primary-foreground ltr:left-3 rtl:right-3"
      >{{ t('discount_percent', '-:n%', '-:n٪', { n: discount }) }}</span>

      <span
        v-if="product.is_featured"
        class="absolute top-3 rounded-full bg-brand-forest/90 px-2.5 py-1 text-xs font-medium text-white ltr:right-3 rtl:left-3"
      >{{ t('featured', 'Featured', 'مميز') }}</span>
    </div>

    <p class="mt-3 truncate text-sm font-medium">{{ product.title }}</p>

    <p class="mt-1 flex items-baseline gap-2">
      <span class="font-display text-lg font-black text-primary">
        {{ format(product.sale_price ?? product.price) }}
      </span>
      <span
        v-if="product.sale_price"
        class="text-sm text-muted-foreground line-through"
      >{{ format(product.price) }}</span>
    </p>
  </NuxtLink>
</template>

<script setup>
/**
 * One piece, as it appears in every list: the home grids, the shop listing and the
 * related strip on a product page. The list payload is the same shape everywhere
 * (`id`, `title`, `image`, `price`, `sale_price`), so they all render identically.
 */
const props = defineProps({
  product: { type: Object, required: true },
})

const { t } = useLang('web', 'home')
const { format } = usePrice()

const discount = computed(() => {
  const price = Number(props.product.price ?? 0)
  const sale = Number(props.product.sale_price ?? 0)
  if (!price || !sale || sale >= price) return 0
  return Math.round(((price - sale) / price) * 100)
})
</script>
