<template>
  <main>
    <PageHero
      media-key="hero_gallery"
      fallback="/seed/hero-gallery.webp"
      :crumbs="[
        { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
        { label: t('nav_gallery', 'Gallery', 'المعرض', { subGroup: 'general' }) },
      ]"
      :title="t('gallery_title', 'From the studio', 'من الاستوديو')"
      :subtitle="t('gallery_subtitle', 'Pieces our guests shaped, glazed and took home.', 'قطع صنعها ضيوفنا بأيديهم وأخذوها معهم.')"
    />

    <div class="mx-auto max-w-6xl px-5 py-16">
      <!--
        Masonry, as the design draws it: tiles keep their own height and the columns fill
        unevenly, so the wall reads as a pile of photographs rather than a grid. CSS
        columns rather than a grid, since the row heights are meant not to line up.
      -->
      <ul v-if="pending" class="columns-2 gap-1.5 lg:columns-3 [&>li]:mb-1.5" aria-busy="true">
        <li v-for="n in 6" :key="n" class="break-inside-avoid">
          <AppSkeleton class="w-full !rounded-none" :class="ratio(n - 1)" />
        </li>
      </ul>

      <ul v-else class="columns-2 gap-1.5 lg:columns-3 [&>li]:mb-1.5">
        <li v-for="(category, index) in categories" :key="category.id" class="break-inside-avoid">
          <NuxtLink :to="`/gallery/${category.id}`" class="group relative block overflow-hidden bg-brand-mist">
            <AppImage
              v-if="category.cover?.image_api"
              :src="category.cover"
              :alt="category.title"
              class="w-full object-cover transition-transform duration-700 group-hover:scale-105"
              :class="ratio(index)"
            />

            <!-- One scrim over the whole tile, blurred, with the copy centred on it. -->
            <div
              class="absolute inset-0 flex flex-col items-center justify-center gap-1 bg-brand-ink/30 px-4 text-center text-white backdrop-blur-[3px] transition-colors group-hover:bg-brand-ink/20"
            >
              <h2 class="font-display text-xl font-semibold drop-shadow-sm sm:text-2xl">{{ category.title }}</h2>
              <p class="text-sm text-white/90 drop-shadow-sm">
                {{ t('gallery_counts', ':images photos · :videos videos', ':images صورة · :videos فيديو', {
                  images: category.images_count,
                  videos: category.videos_count,
                }) }}
              </p>
            </div>
          </NuxtLink>
        </li>
      </ul>
    </div>
  </main>
</template>

<script setup>
const { categories, pending } = useGallery()
const { t } = useLang('web', 'home')

// The four tile heights the design cycles through, as ratios of the tile width.
const RATIOS = ['aspect-square', 'aspect-[6/7]', 'aspect-[3/4]', 'aspect-[7/6]']
const ratio = (index) => RATIOS[index % RATIOS.length]

const { media: heroMedia } = useMedia('web', 'heroes')

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`

useSeoMeta({
  title: () => t('gallery_title', 'Gallery', 'المعرض'),
  description: () => t('gallery_subtitle', 'Pieces our guests shaped, glazed and took home.', 'قطع صنعها ضيوفنا بأيديهم وأخذوها معهم.'),
  ogImage: () => heroMedia('hero_gallery') ?? fallbackCard,
})

useSchemaOrg([
  defineBreadcrumb({
    itemListElement: [
      { name: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }), item: '/' },
      { name: t('nav_gallery', 'Gallery', 'المعرض', { subGroup: 'general' }), item: '/gallery' },
    ],
  }),
])
</script>
