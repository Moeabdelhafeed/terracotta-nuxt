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
    <HomeApp />
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
const { media } = useMedia('web', 'heroes')

// The front door had no meta of its own, so it inherited the bare site defaults.
// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`

useSeoMeta({
  title: () => t('home_meta_title', 'Handmade pottery, workshops and pieces', 'فخار مصنوع يدويًا، ورشات وقطع'),
  description: () => t('home_meta_description', 'A pottery studio in Amman: book a workshop, shape your own piece, and browse what our guests have made.', 'استوديو فخار في عمّان: احجز ورشة، اصنع قطعتك بيديك، وتصفح ما صنعه ضيوفنا.'),
  ogImage: () => media('hero_shop') ?? fallbackCard,
})
</script>
