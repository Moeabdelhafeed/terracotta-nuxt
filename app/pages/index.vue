<template>
  <main>
    <HomeSplash />
    <HomeHero />
    <HomeWorkshops />
    <HomeCategories />
    <HomeProductGrid
      :products="featuredProducts"
      :title="t('featured_pieces', 'Featured pieces', 'القطع المميزة')"
      anchor="featured"
    />
    <HomeProductGrid
      :products="offers"
      :title="t('latest_offers', 'Latest offers', 'اخر العروض')"
      anchor="offers"
    />
    <HomeGallery />
    <HomeVisit />
  </main>
</template>

<script setup>
definePageMeta({
  // Public: the home page is the front door of the site. Identity (guest or registered)
  // is established by the auto-guest plugin, not by gating the page behind a login.
  name: 'home',
})

const { featuredProducts, offers } = useHome()
const { t } = useLang('web', 'home')
</script>
