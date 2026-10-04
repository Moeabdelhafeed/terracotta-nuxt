<template>
  <main class="bg-background">
    <PageHero
      media-key="hero_news"
      fallback="/seed/about-1.webp"
      :crumbs="crumbs"
      :title="t('news_title', 'Terracotta news', 'أخبار تيراكوتا')"
      :subtitle="t('news_subtitle', 'Events and conferences we took part in.', 'فعاليات ومؤتمرات شاركنا فيها.')"
    />

    <div class="mx-auto max-w-6xl px-6 py-12">
      <div v-if="kinds.length > 1" class="mb-8 flex flex-wrap gap-2" role="group" :aria-label="t('filter_by_type', 'Filter by type', 'تصفية حسب النوع')">
        <button
          v-for="kind in [null, ...kinds]"
          :key="kind?.id ?? 'all'"
          type="button"
          class="rounded-full border px-4 py-2 text-sm transition-colors"
          :class="(kind?.id ?? null) === active ? 'border-brand-ink bg-brand-ink text-white' : 'bg-card hover:bg-brand-mist'"
          :aria-pressed="(kind?.id ?? null) === active"
          data-test="news-filter"
          @click="active = kind?.id ?? null"
        >
          {{ kind ? kind.name : t('all', 'All', 'الكل') }}
        </button>
      </div>

      <div v-if="pending && !news.length" class="grid gap-4 md:grid-cols-2 lg:grid-cols-3" aria-busy="true">
        <AppSkeleton v-for="n in 6" :key="n" class="h-32 w-full" />
      </div>

      <AppLoadError v-else-if="error && !news.length" :error="error" :retry="refresh" />

      <div v-else-if="!news.length" class="mx-auto flex max-w-xl flex-col items-center gap-3 rounded-card border bg-card p-10 text-center">
        <span class="flex size-12 items-center justify-center rounded-control bg-brand-terracotta/10 text-brand-terracotta">
          <LucideNewspaper class="size-5" />
        </span>
        <h2 class="font-display text-lg font-semibold">{{ t('news_empty_title', 'No news yet', 'لا توجد أخبار بعد') }}</h2>
        <p class="text-sm text-muted-foreground">{{ t('news_empty_body', 'Events and conferences we take part in will appear here.', 'ستظهر هنا الفعاليات والمؤتمرات التي نشارك فيها.') }}</p>
      </div>

      <!-- A timeline, newest first, one heading per year: the event's own year, so a
           conference written up late still sits where it happened. -->
      <div v-else class="space-y-10">
        <section v-for="group in byYear" :key="group.year" data-test="news-year">
          <h2 class="mb-4 border-b pb-2 font-display text-xl font-bold text-brand-terracotta">{{ group.label }}</h2>
          <ul class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <li v-for="item in group.items" :key="item.id"><AboutNewsCard :item="item" /></li>
          </ul>
        </section>
      </div>
    </div>
  </main>
</template>

<script setup>
/** Every event and conference, newest first, grouped by year. Fetched whole; the category pills filter on the page. */
const { t, day } = useAboutLabels()
const { items: news, pending, error, refresh } = useNews()

const kinds = computed(() => categoriesOf(news.value))
const active = ref(null)

// The API already orders newest event first, so grouping keeps that order.
const byYear = computed(() => {
  const groups = []
  for (const item of news.value) {
    if (active.value && item.category?.id !== active.value) continue
    const year = item.starts_on?.slice(0, 4) ?? ''
    let group = groups.at(-1)
    if (group?.year !== year) {
      group = { year, label: day(item.starts_on, { year: 'numeric' }), items: [] }
      groups.push(group)
    }
    group.items.push(item)
  }
  return groups
})

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/about', label: t('nav_about', 'About', 'عن تيراكوتا', { subGroup: 'general' }) },
  { label: t('news_title', 'Terracotta news', 'أخبار تيراكوتا') },
])

useSeoMeta({
  title: () => t('news_title', 'Terracotta news', 'أخبار تيراكوتا'),
  description: () => t('news_subtitle', 'Events and conferences we took part in.', 'فعاليات ومؤتمرات شاركنا فيها.'),
})
</script>
