<template>
  <ul class="grid grid-cols-3 gap-3 sm:gap-4">
    <li v-for="tile in tiles" :key="tile.key">
      <NuxtLink
        :to="tile.to"
        class="flex h-full flex-col items-center justify-center gap-2 rounded-2xl border bg-card p-4 text-center transition-colors hover:bg-brand-mist/40"
      >
        <span class="relative flex size-11 items-center justify-center rounded-xl bg-brand-mist text-brand-rust">
          <LucideShoppingBag v-if="tile.key === 'cart'" class="size-5" />
          <LucideHeart v-else-if="tile.key === 'favorites'" class="size-5" />
          <LucidePackage v-else class="size-5" />
          <span
            v-if="tile.badge"
            class="absolute -top-1.5 flex min-w-5 items-center justify-center rounded-full bg-brand-rust px-1.5 text-[10px] font-semibold text-white ltr:-right-1.5 rtl:-left-1.5"
          >{{ tile.badge }}</span>
        </span>
        <span class="text-sm font-medium text-foreground">{{ tile.label }}</span>
      </NuxtLink>
    </li>
  </ul>
</template>

<script setup>
/** The three shortcuts the store home carries: cart, favourites, orders. */
const { t } = useLang('web', 'shop')
const { count } = useCart()
const { favorites } = useFavorites()

const tiles = computed(() => [
  { key: 'cart', to: '/cart', label: t('cart_title', 'My cart', 'عربيتي'), badge: count.value },
  { key: 'favorites', to: '/favorites', label: t('favorites_title', 'My favourites', 'منتجاتي المفضلة'), badge: favorites.value.length },
  { key: 'orders', to: '/orders', label: t('orders_title', 'My orders', 'طلباتي'), badge: 0 },
])
</script>
