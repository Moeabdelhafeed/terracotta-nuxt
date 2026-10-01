<template>
  <!-- The studio's work and its news, as the product rows above them are drawn: a title,
       "View all", and three cards. Each row is absent until the studio has published
       something in it — an empty heading on the front door says nothing good. -->
  <section v-if="projects.length" id="projects" class="mx-auto max-w-6xl px-6 py-20" data-test="home-projects">
    <header class="mb-8 flex items-end justify-between gap-4">
      <div>
        <h2 class="font-display text-3xl font-semibold sm:text-4xl">
          {{ t('home_projects_title', 'Our work with hotels and restaurants', 'مشاريعنا مع الفنادق والمطاعم') }}
        </h2>
        <p class="mt-2 text-muted-foreground">
          {{ t('home_projects_subtitle', 'Pieces we made for the tables of the places we work with.', 'قطع صنعناها خصيصًا لطاولات من نعمل معهم.') }}
        </p>
      </div>
      <NuxtLink to="/about/projects" class="shrink-0 text-sm font-medium text-primary underline-offset-4 hover:underline">
        {{ t('view_all', 'View all', 'عرض الكل') }}
      </NuxtLink>
    </header>
    <ul
      v-gsap.whenVisible.once.from.stagger="entranceFrom({ opacity: 0, y: 36, duration: 0.6 })"
      class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3"
    >
      <li v-for="project in projects" :key="project.id"><AboutProjectCard :project="project" /></li>
    </ul>
  </section>

  <section v-if="news.length" id="news" data-test="home-news">
    <div class="mx-auto max-w-6xl px-6 py-20">
      <header class="mb-8 flex items-end justify-between gap-4">
        <div>
          <h2 class="font-display text-3xl font-semibold sm:text-4xl">
            {{ t('home_news_title', 'Terracotta news', 'أخبار تيراكوتا') }}
          </h2>
          <p class="mt-2 text-muted-foreground">
            {{ t('home_news_subtitle', 'Events and conferences we took part in.', 'فعاليات ومؤتمرات شاركنا فيها.') }}
          </p>
        </div>
        <NuxtLink to="/about/news" class="shrink-0 text-sm font-medium text-primary underline-offset-4 hover:underline">
          {{ t('view_all', 'View all', 'عرض الكل') }}
        </NuxtLink>
      </header>
      <ul
        v-gsap.whenVisible.once.from.stagger="entranceFrom({ opacity: 0, y: 36, duration: 0.6 })"
        class="grid gap-4 lg:grid-cols-3"
      >
        <li v-for="item in news" :key="item.id"><AboutNewsCard :item="item" /></li>
      </ul>
    </div>
  </section>
</template>

<script setup>
/** The front door's window onto the About pages: the newest three projects and news items. */
const { t } = useLang('web', 'home')

// Keys of their own: the About page asks for the same three, and the full list pages for
// everything — one key each so none of them is handed another's answer.
const { items: projects } = useProjects({ per_page: 3 }, 'home-projects')
const { items: news } = useNews({ per_page: 3 }, 'home-news')
</script>
