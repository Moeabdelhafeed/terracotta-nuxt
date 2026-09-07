<template>
  <main class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex items-center justify-between gap-4">
        <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('favorites_title', 'My favourites', 'منتجاتي المفضلة') }}</h1>
        <Button as-child variant="outline" size="sm" class="rounded-full">
          <NuxtLink to="/shop">{{ t('close', 'Close', 'اغلاق') }}</NuxtLink>
        </Button>
      </div>

      <ul v-if="pending && !favorites.length" class="mt-10 grid grid-cols-2 gap-5 lg:grid-cols-4" aria-busy="true">
        <li v-for="n in 4" :key="n">
          <ProductCardSkeleton />
        </li>
      </ul>

      <div v-else-if="!favorites.length" class="mt-10 rounded-3xl border bg-card p-8 text-center sm:p-12">
        <span class="mx-auto flex size-14 items-center justify-center rounded-2xl bg-brand-mist text-brand-rust">
          <LucideHeart class="size-6" />
        </span>
        <p class="mt-4 font-display text-xl font-semibold">{{ t('favorites_empty_title', 'Nothing saved yet', 'لا توجد مفضلات بعد') }}</p>
        <p class="mt-2 text-sm text-muted-foreground">{{ t('favorites_empty_body', 'Tap the heart on a piece to keep it here.', 'اضغط القلب على أي قطعة لتحفظها هنا.') }}</p>
        <Button as-child class="mt-6 h-12 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90">
          <NuxtLink to="/shop">{{ t('browse_shop', 'Browse the shop', 'تصفح المتجر') }}</NuxtLink>
        </Button>
      </div>

      <ul v-else class="mt-10 grid grid-cols-2 gap-5 lg:grid-cols-4">
        <li v-for="product in favorites" :key="product.id">
          <ProductCard :product="product" />
        </li>
      </ul>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered'],
  name: 'favorites',
})

/**
 * The saved pieces. The list is not filtered by active state server-side, so an entry can
 * 404 on its detail page or refuse a cart-add — the card links out and the failure is the
 * detail page's / the cart's to report, rather than something to pre-empt here.
 * Unhearting removes the card at once: `favorites` reads the same optimistic overrides
 * the button writes.
 */
const { t } = useLang('web', 'shop')
const { favorites, pending } = useFavorites()

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/shop', label: t('nav_shop', 'Shop', 'المتجر', { subGroup: 'general' }) },
  { label: t('favorites_title', 'My favourites', 'منتجاتي المفضلة') },
])

useSeoMeta({ title: () => t('favorites_title', 'My favourites', 'منتجاتي المفضلة'), robots: 'noindex' })
</script>
