<template>
  <main class="bg-background">
    <PageHero
      media-key="hero_about"
      fallback="/seed/hero-about.webp"
      :crumbs="[
        { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
        { label: t('nav_about', 'About', 'عن تيراكوتا', { subGroup: 'general' }) },
      ]"
      :title="t('about_hero_title', 'About Terracotta', 'عن تيراكوتا')"
      :subtitle="t('about_hero_subtitle', 'A studio in Amman where clay is shaped by hand.', 'استوديو في عمّان يُشكَّل فيه الطين باليد.')"
    />

    <!-- Loading: the shape of the page's usual opening — a picture beside copy, then
         the band — so the content lands where the shimmer was. -->
    <div v-if="sectionsPending && !blocks.length" aria-busy="true" data-test="about-loading">
      <section class="mx-auto max-w-6xl px-6 py-20 sm:py-24">
        <div class="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
          <AppSkeleton class="aspect-[4/3] w-full !rounded-none" />
          <div class="space-y-4">
            <AppSkeleton class="h-3 w-24" />
            <AppSkeleton class="h-9 w-2/3" />
            <AppSkeleton class="h-4 w-full" />
            <AppSkeleton class="h-4 w-full" />
            <AppSkeleton class="h-4 w-4/5" />
          </div>
        </div>
      </section>
      <div class="bg-brand-terracotta/10 px-6 py-24">
        <div class="mx-auto flex max-w-3xl flex-col items-center gap-5">
          <AppSkeleton class="h-10 w-3/4" />
          <AppSkeleton class="h-4 w-full" />
          <AppSkeleton class="h-4 w-2/3" />
        </div>
      </div>
    </div>

    <template v-for="block in blocks" :key="block.id">
      <!-- The band: centred copy on terracotta, carrying the same line the hero and the
           footer are drawn with. -->
      <section
        v-if="block.type === 'banner'"
        class="relative isolate overflow-hidden bg-brand-terracotta text-white"
        data-test="about-banner"
      >
        <BrandLine class="-z-10 text-white/15" />

        <div class="mx-auto max-w-3xl px-6 py-24 text-center sm:py-28">
          <h2 class="font-display text-3xl font-semibold leading-tight sm:text-5xl">{{ block.title }}</h2>
          <p v-if="block.body" class="mt-6 whitespace-pre-line text-lg leading-relaxed text-white/80">{{ block.body }}</p>
        </div>
      </section>

      <!-- Picture and copy. Every other pictured section swaps the columns, so the page
           reads as one rhythm rather than a stack of the same block. A section with no
           picture is the copy alone, centred. -->
      <section v-else class="mx-auto max-w-6xl px-6 py-20 sm:py-24" data-test="about-section">
        <div
          class="grid items-center gap-10 lg:gap-16"
          :class="block.image?.image_api ? 'lg:grid-cols-2' : 'mx-auto max-w-3xl text-center'"
        >
          <div v-if="block.image?.image_api" :class="block.mirrored ? 'lg:order-2' : ''">
            <div class="overflow-hidden bg-brand-mist">
              <AppImage :src="block.image" :alt="block.title" class="aspect-[4/3] w-full object-cover" />
            </div>
          </div>

          <div :class="block.mirrored ? 'lg:order-1' : ''">
            <p v-if="block.eyebrow" class="mb-5 text-xs uppercase tracking-[0.25em] text-brand-terracotta/70">
              {{ block.eyebrow }}
            </p>
            <h2 class="font-display text-3xl font-semibold leading-tight sm:text-4xl">{{ block.title }}</h2>
            <p v-if="block.body" class="mt-5 whitespace-pre-line text-lg leading-relaxed text-muted-foreground">{{ block.body }}</p>
          </div>
        </div>
      </section>
    </template>

    <!-- The two things filed under About, newest three of each. Either one hides itself
         until the studio has published something in it. -->
    <section v-if="projects.length" class="mx-auto max-w-6xl px-6 py-20" data-test="about-projects">
      <header class="mb-8 flex items-end justify-between gap-4">
        <div>
          <h2 class="font-display text-3xl font-semibold sm:text-4xl">
            {{ t('about_projects_title', 'Our work with hotels and restaurants', 'مشاريعنا مع الفنادق والمطاعم') }}
          </h2>
          <p class="mt-2 text-muted-foreground">
            {{ t('about_projects_subtitle', 'Pieces we made for the tables of the places we work with.', 'قطع صنعناها خصيصًا لطاولات من نعمل معهم.') }}
          </p>
        </div>
        <NuxtLink to="/about/projects" class="shrink-0 text-sm font-medium text-primary underline-offset-4 hover:underline">
          {{ t('view_all', 'View all', 'عرض الكل') }}
        </NuxtLink>
      </header>
      <ul class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        <li v-for="project in projects" :key="project.id"><AboutProjectCard :project="project" /></li>
      </ul>
    </section>

    <section v-if="news.length" data-test="about-news">
      <div class="mx-auto max-w-6xl px-6 py-20">
        <header class="mb-8 flex items-end justify-between gap-4">
          <div>
            <h2 class="font-display text-3xl font-semibold sm:text-4xl">
              {{ t('about_news_title', 'Terracotta news', 'أخبار تيراكوتا') }}
            </h2>
            <p class="mt-2 text-muted-foreground">
              {{ t('about_news_subtitle', 'Events and conferences we took part in.', 'فعاليات ومؤتمرات شاركنا فيها.') }}
            </p>
          </div>
          <NuxtLink to="/about/news" class="shrink-0 text-sm font-medium text-primary underline-offset-4 hover:underline">
            {{ t('view_all', 'View all', 'عرض الكل') }}
          </NuxtLink>
        </header>
        <ul class="grid gap-4 lg:grid-cols-3">
          <li v-for="item in news" :key="item.id"><AboutNewsCard :item="item" /></li>
        </ul>
      </div>
    </section>
  </main>
</template>

<script setup>
/**
 * The studio's own page. The hero is dynamic storage and translations like every hero;
 * everything below it comes from the CMS's About page — sections and banners in the order
 * the studio stacked them — followed by the newest projects and news.
 *
 * The page's words stay in the `home` sub-group, where the hero's always were: moving them
 * would re-seed them elsewhere and drop whatever the studio had already reworded.
 */
const { t } = useLang('web', 'home')

const { sections, pending: sectionsPending } = useAboutSections()
const { items: projects } = useProjects({ per_page: 3 }, 'about-projects-teaser')
const { items: news } = useNews({ per_page: 3 }, 'about-news-teaser')

// Which sections swap their columns: every second one that has a picture beside it.
const blocks = computed(() => {
  let pictured = 0
  return sections.value.map((section) => {
    const hasPicture = section.type === 'section' && !!section.image?.image_api
    const mirrored = hasPicture && pictured++ % 2 === 1
    return { ...section, mirrored }
  })
})

useSeoMeta({
  title: () => t('about_hero_title', 'About Terracotta', 'عن تيراكوتا'),
  description: () => t('about_hero_subtitle', 'A studio in Amman where clay is shaped by hand.', 'استوديو في عمّان يُشكَّل فيه الطين باليد.'),
})

useSchemaOrg([
  defineBreadcrumb({
    itemListElement: [
      { name: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }), item: '/' },
      { name: t('nav_about', 'About', 'عن تيراكوتا', { subGroup: 'general' }), item: '/about' },
    ],
  }),
])
</script>
