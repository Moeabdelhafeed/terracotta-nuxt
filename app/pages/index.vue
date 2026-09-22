<template>
  <main class="bg-background">
    <HomeSplash />

    <!-- A failed `GET /api/home` used to leave hero, banners, categories and both grids
         silently absent, which reads as a studio with nothing on. Say so, and offer the
         one thing that can fix it. -->
    <div v-if="error" class="mx-auto max-w-6xl px-6 py-16">
      <AppLoadError :error="error" :retry="refresh" />
    </div>

    <HomeHero />
    <HomeLiveStrip />
    <HomeBooking />
    <HomeWorkshops />
    <HomeCategories />
    <HomeBanners />
    <HomeProductGrid
      :products="featuredProducts"
      :title="t('featured_pieces', 'Featured pieces', 'القطع المميزة')"
      anchor="featured"
      to="/shop?featured=1"
      :count-query="{ featured: 1 }"
    />
    <HomeProductGrid
      :products="offers"
      :title="t('latest_offers', 'Latest offers', 'اخر العروض')"
      anchor="offers"
      to="/shop?sale=1"
      :count-query="{ on_sale: 1 }"
    />
    <HomeGallery />
    <HomeApp />
    <HomeGift />
  </main>
</template>

<script setup>
definePageMeta({
  // Public: the home page is the front door of the site. Identity (guest or registered)
  // is established by the auto-guest plugin, not by gating the page behind a login.
  name: 'home',
})

const { featuredProducts, offers, error, refresh } = useHome()
const { t } = useLang('web', 'home')

useSeoMeta({
  title: () => t('home_meta_title', 'Handmade pottery, workshops and pieces', 'فخار مصنوع يدويًا، ورشات وقطع'),
  description: () => t('home_meta_description', 'A pottery studio in Amman: book a workshop, shape your own piece, and browse what our guests have made.', 'استوديو فخار في عمّان: احجز ورشة، اصنع قطعتك بيديك، وتصفح ما صنعه ضيوفنا.'),
})
</script>
