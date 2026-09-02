<template>
  <main v-if="status !== 'success' && !category" class="mx-auto max-w-6xl px-5 py-12" aria-busy="true">
    <AppSkeleton class="h-9 w-56" />
    <AppSkeleton class="mt-3 h-4 w-40" />
    <ul class="mt-8 columns-2 gap-1.5 lg:columns-3 [&>li]:mb-1.5">
      <li v-for="n in 9" :key="n" class="break-inside-avoid">
        <AppSkeleton class="w-full !rounded-none" :class="ratio(n - 1)" />
      </li>
    </ul>
  </main>

  <main v-else-if="category">
    <!-- The album's own cover carries the hero, so the page opens on the work itself
         rather than on a picture chosen for the section as a whole. -->
    <PageHero
      :image="cover"
      :crumbs="crumbs"
      :title="category.title"
      :subtitle="t('gallery_counts', ':images photos · :videos videos', ':images صورة · :videos فيديو', {
        images: category.images_count,
        videos: category.videos_count,
      })"
    />

    <div class="mx-auto max-w-6xl px-5 py-12">
      <!-- Same wall as the album list: staggered heights, hairline gaps, square corners. -->
      <ul class="columns-2 gap-1.5 lg:columns-3 [&>li]:mb-1.5">
        <li v-for="(item, index) in category.items" :key="item.id" class="break-inside-avoid bg-brand-mist">
          <!-- AppMedia, so a video item plays in place instead of breaking the wall. -->
          <AppMedia :src="item" :alt="category.title" class="w-full object-cover" :class="ratio(index)" />
        </li>
      </ul>
    </div>
  </main>
</template>

<script setup>
const route = useRoute()
const { category, error, status } = useGalleryCategory(() => route.params.id)

// A record that does not exist, or a lookup that failed, hands over to the site's error
// page — the markup's `v-if` would otherwise match nothing and leave a blank screen.
//
// Keyed on `status`, not on `pending`: a client-side navigation arrives with the fetch not
// yet started, where `pending` is still false and the record still null — reading that as
// "not found" 404s a product that exists, until you refresh.
watchEffect(() => {
  if (status.value === 'error' || (status.value === 'success' && !category.value)) {
    showError({ statusCode: error.value?.statusCode ?? 404, statusMessage: 'Album not found' })
  }
})

const { t } = useLang('web', 'home')

// The album endpoint returns no cover of its own — only the list carries one — so the
// hero takes the album's first picture, which is the same asset the list shows.
const cover = computed(() => {
  const items = category.value?.items ?? []
  return items.find((item) => item.type === 'image')?.image
    ?? items.find((item) => item.type === 'video')?.video?.thumbnail
    ?? null
})

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/gallery', label: t('nav_gallery', 'Gallery', 'المعرض', { subGroup: 'general' }) },
  { label: category.value?.title ?? '' },
])

const RATIOS = ['aspect-square', 'aspect-[6/7]', 'aspect-[3/4]', 'aspect-[7/6]']
const ratio = (index) => RATIOS[index % RATIOS.length]

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`

useSeoMeta({
  title: () => category.value?.title ?? '',
  description: () => t('gallery_subtitle', 'Pieces our guests shaped, glazed and took home.', 'قطع صنعها ضيوفنا بأيديهم وأخذوها معهم.'),
  ogImage: () => cover.value?.image_api ?? fallbackCard,
})

useSchemaOrg([
  defineBreadcrumb({
    itemListElement: () => crumbs.value.map((crumb) => ({ name: crumb.label, item: crumb.to })),
  }),
])
</script>
