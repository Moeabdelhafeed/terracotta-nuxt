<template>
  <main v-if="status !== 'success' && !item" class="mx-auto max-w-4xl px-6 py-16" aria-busy="true">
    <AppSkeleton class="h-9 w-2/3" />
    <AppSkeleton class="mt-6 aspect-[16/9] w-full" />
    <AppSkeleton class="mt-6 h-24 w-full" />
  </main>

  <main v-else-if="item" class="bg-background">
    <PageHero :image="item.image" :crumbs="crumbs" :title="item.title" :subtitle="[dateRange(item), item.place].filter(Boolean).join(' · ')" />

    <div class="mx-auto max-w-4xl space-y-8 px-6 py-12">
      <span class="inline-block rounded-full bg-brand-terracotta/10 px-3 py-1 text-sm font-medium text-brand-terracotta">{{ newsType(item.type) }}</span>

      <p v-if="item.description" class="whitespace-pre-line text-lg leading-relaxed text-muted-foreground">{{ item.description }}</p>

      <AboutPhotoWall :photos="photos" :alt="item.title" />

      <div class="flex flex-wrap items-center gap-4">
        <!-- The event's own website, when the studio added one: it leaves the site. -->
        <a
          v-if="item.link"
          :href="item.link"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex h-11 items-center gap-2 rounded-control bg-brand-terracotta px-5 text-sm font-semibold text-white transition-colors hover:bg-brand-terracotta/90"
          data-test="news-link"
        >
          {{ t('event_page', 'Event website', 'صفحة الفعالية') }}
          <LucideExternalLink class="size-4" />
        </a>
        <NuxtLink to="/about/news" class="inline-flex items-center gap-1.5 text-sm font-medium text-primary underline-offset-4 hover:underline">
          <LucideArrowLeft class="size-4 rtl:-scale-x-100" />
          {{ t('all_news', 'All news', 'كل الأخبار') }}
        </NuxtLink>
      </div>
    </div>
  </main>
</template>

<script setup>
const route = useRoute()
const { record: item, error, status } = useNewsItem(() => route.params.id)

// Missing or switched off: the site's error page. Keyed on `status` — see the gallery album page.
watchEffect(() => {
  if (status.value === 'error' || (status.value === 'success' && !item.value)) {
    showError({ statusCode: error.value?.statusCode ?? 404, statusMessage: 'News item not found' })
  }
})

const { t, newsType, dateRange } = useAboutLabels()

const photos = computed(() => asList(item.value?.images))

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/about/news', label: t('news_title', 'Terracotta news', 'أخبار تيراكوتا') },
  { label: item.value?.title ?? '' },
])

useSeoMeta({
  title: () => item.value?.title ?? '',
  description: () => item.value?.description?.slice(0, 160) || dateRange(item.value),
})
</script>
