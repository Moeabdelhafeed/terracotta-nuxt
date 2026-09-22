<template>
  <main class="bg-background">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('favorites_title', 'My favourites', 'منتجاتي المفضلة') }}</h1>

      <AppLoadError v-if="error" :error="error" :retry="refresh" class="mt-10" />

      <ul v-else-if="(pending || !mounted) && !favorites.length" class="mt-10 grid grid-cols-2 gap-5 lg:grid-cols-4" aria-busy="true">
        <li v-for="n in 4" :key="n">
          <ProductCardSkeleton />
        </li>
      </ul>

      <div v-else-if="!favorites.length" class="mx-auto mt-10 max-w-xl rounded-card border bg-card p-8 text-center sm:p-12">
        <span class="mx-auto flex size-14 items-center justify-center rounded-card bg-brand-terracotta/10 text-brand-terracotta">
          <LucideHeart class="size-6" />
        </span>
        <p class="mt-4 font-display text-xl font-semibold">{{ t('favorites_empty_title', 'Nothing saved yet', 'لا توجد مفضلات بعد') }}</p>
        <p class="mt-2 text-sm text-muted-foreground">{{ t('favorites_empty_body', 'Tap the heart on a piece to keep it here.', 'اضغط القلب على أي قطعة لتحفظها هنا.') }}</p>
        <Button as-child class="mt-6 h-12 rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90">
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
  middleware: ['auth-mode'],
  name: 'favorites',
})

/**
 * The saved pieces. The list is not filtered by active state server-side, so an entry can
 * 404 on its detail page or refuse a cart-add — the card links out and the failure is the
 * detail page's / the cart's to report, rather than something to pre-empt here.
 * Unhearting removes the card at once: `favorites` reads the same optimistic overrides
 * the button writes.
 *
 * A visitor without an account gets the same list out of localStorage.
 */
const { t } = useLang('web', 'shop')
const { favorites, pending, error, refresh } = useFavorites()

// The local list only exists after hydration; without this the empty panel flashes.
const mounted = useMounted()

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/shop', label: t('nav_shop', 'Shop', 'المتجر', { subGroup: 'general' }) },
  { label: t('favorites_title', 'My favourites', 'منتجاتي المفضلة') },
])

useSeoMeta({ title: () => t('favorites_title', 'My favourites', 'منتجاتي المفضلة'), robots: 'noindex' })
</script>
