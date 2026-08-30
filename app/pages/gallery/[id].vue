<template>
  <main v-if="category">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-5 py-12">
      <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ category.title }}</h1>
      <p class="mt-2 text-muted-foreground">
        {{ t('gallery_counts', ':images photos · :videos videos', ':images صورة · :videos فيديو', {
          images: category.images_count,
          videos: category.videos_count,
        }) }}
      </p>

      <!-- Same wall as the album list: staggered heights, hairline gaps, square corners. -->
      <ul class="mt-8 columns-2 gap-1.5 lg:columns-3 [&>li]:mb-1.5">
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
const { category } = useGalleryCategory(() => route.params.id)
const { t } = useLang('web', 'home')

const crumbs = computed(() => [
  { to: '/gallery', label: t('nav_gallery', 'Gallery', 'المعرض') },
  { label: category.value?.title ?? '' },
])

const RATIOS = ['aspect-square', 'aspect-[6/7]', 'aspect-[3/4]', 'aspect-[7/6]']
const ratio = (index) => RATIOS[index % RATIOS.length]

useSeoMeta({ title: () => category.value?.title ?? '' })
</script>
