<template>
  <main class="bg-background">
    <PageHero
      media-key="hero_projects"
      fallback="/seed/studio-2.webp"
      :crumbs="crumbs"
      :title="t('projects_title', 'Our projects', 'مشاريعنا')"
      :subtitle="t('projects_subtitle', 'Pieces we made for hotels, restaurants and cafés.', 'قطع صنعناها لفنادق ومطاعم ومقاهٍ.')"
    />

    <div class="mx-auto max-w-6xl px-6 py-12">
      <!-- Only the kinds of client the studio has actually worked for: a "Cafés" pill
           that opens an empty grid is a promise the page can't keep. -->
      <div v-if="kinds.length > 1" class="mb-8 flex flex-wrap gap-2" role="group" :aria-label="t('filter_by_client', 'Filter by client', 'تصفية حسب العميل')">
        <button
          v-for="kind in [null, ...kinds]"
          :key="kind ?? 'all'"
          type="button"
          class="rounded-full border px-4 py-2 text-sm transition-colors"
          :class="kind === active ? 'border-brand-ink bg-brand-ink text-white' : 'bg-card hover:bg-brand-mist'"
          :aria-pressed="kind === active"
          data-test="project-filter"
          @click="active = kind"
        >
          {{ kind ? clientType(kind) : t('all', 'All', 'الكل') }}
        </button>
      </div>

      <ul v-if="pending && !projects.length" class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3" aria-busy="true">
        <li v-for="n in 6" :key="n"><AppSkeleton class="aspect-[4/5] w-full !rounded-card" /></li>
      </ul>

      <AppLoadError v-else-if="error && !projects.length" :error="error" :retry="refresh" />

      <div v-else-if="!projects.length" class="mx-auto flex max-w-xl flex-col items-center gap-3 rounded-card border bg-card p-10 text-center">
        <span class="flex size-12 items-center justify-center rounded-control bg-brand-terracotta/10 text-brand-terracotta">
          <LucideBriefcase class="size-5" />
        </span>
        <h2 class="font-display text-lg font-semibold">{{ t('projects_empty_title', 'Our projects are on their way', 'مشاريعنا في الطريق') }}</h2>
        <p class="text-sm text-muted-foreground">{{ t('projects_empty_body', 'We are photographing our latest work. Check back soon.', 'نصوّر أحدث أعمالنا الآن، عُد قريبًا.') }}</p>
      </div>

      <ul v-else class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        <li v-for="project in shown" :key="project.id"><AboutProjectCard :project="project" /></li>
      </ul>
    </div>
  </main>
</template>

<script setup>
/**
 * The studio's portfolio, in the order the studio arranged it. Fetched whole — it is a
 * portfolio, not a feed — so the client-type pills filter on the page without a request.
 */
const { t, clientType } = useAboutLabels()
const { items: projects, pending, error, refresh } = useProjects()

const kinds = computed(() =>
  PROJECT_CLIENT_TYPES.filter((kind) => projects.value.some((project) => project.client_type === kind)),
)
const active = ref(null)
const shown = computed(() =>
  active.value ? projects.value.filter((project) => project.client_type === active.value) : projects.value,
)

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/about', label: t('nav_about', 'About', 'عن تيراكوتا', { subGroup: 'general' }) },
  { label: t('projects_title', 'Our projects', 'مشاريعنا') },
])

useSeoMeta({
  title: () => t('projects_title', 'Our projects', 'مشاريعنا'),
  description: () => t('projects_subtitle', 'Pieces we made for hotels, restaurants and cafés.', 'قطع صنعناها لفنادق ومطاعم ومقاهٍ.'),
})
</script>
