<template>
  <main v-if="status !== 'success' && !project" class="mx-auto max-w-6xl px-6 py-16" aria-busy="true">
    <AppSkeleton class="h-9 w-2/3" />
    <AppSkeleton class="mt-6 aspect-[16/9] w-full" />
    <AppSkeleton class="mt-6 h-24 w-full" />
  </main>

  <main v-else-if="project" class="bg-background">
    <!-- The project's own cover carries the hero, as an album's does in the gallery. -->
    <PageHero :image="project.image" :crumbs="crumbs" :title="project.title" :subtitle="clientLine(project)" />

    <div class="mx-auto grid max-w-6xl gap-10 px-6 py-12 lg:grid-cols-[1fr_20rem]">
      <div class="min-w-0 space-y-10">
        <p v-if="project.description" class="whitespace-pre-line text-lg leading-relaxed text-muted-foreground">
          {{ project.description }}
        </p>
        <AboutPhotoWall :photos="photos" :alt="project.title" />
      </div>

      <!-- The facts, the way a portfolio states them. The client's name only when the
           studio gave it; otherwise the card says what kind of place it was. -->
      <aside class="h-fit space-y-4 rounded-card border bg-brand-container p-5 lg:sticky lg:top-6">
        <div v-if="project.logo?.image_api" class="flex size-20 items-center justify-center overflow-hidden rounded-full bg-white p-2 shadow-sm">
          <AppImage :src="project.logo" :alt="project.client_name || ''" class="size-full object-contain" />
        </div>
        <dl class="divide-y text-sm">
          <div v-if="project.client_name" class="flex justify-between gap-4 py-2.5">
            <dt class="text-muted-foreground">{{ t('project_client', 'Client', 'العميل') }}</dt>
            <dd class="text-end font-medium">{{ project.client_name }}</dd>
          </div>
          <div class="flex justify-between gap-4 py-2.5">
            <dt class="text-muted-foreground">{{ t('project_client_type', 'Type', 'النوع') }}</dt>
            <dd class="text-end font-medium">{{ clientType(project.client_type) }}</dd>
          </div>
          <div v-if="project.city" class="flex justify-between gap-4 py-2.5">
            <dt class="text-muted-foreground">{{ t('project_city', 'City', 'المدينة') }}</dt>
            <dd class="text-end font-medium">{{ project.city }}</dd>
          </div>
          <div v-if="project.year" class="flex justify-between gap-4 py-2.5">
            <dt class="text-muted-foreground">{{ t('project_year', 'Year', 'السنة') }}</dt>
            <dd class="text-end font-medium" dir="ltr">{{ project.year }}</dd>
          </div>
        </dl>
        <NuxtLink to="/about/projects" class="inline-flex items-center gap-1.5 text-sm font-medium text-primary underline-offset-4 hover:underline">
          <LucideArrowLeft class="size-4 rtl:-scale-x-100" />
          {{ t('all_projects', 'All projects', 'كل المشاريع') }}
        </NuxtLink>
      </aside>
    </div>
  </main>
</template>

<script setup>
const route = useRoute()
const { record: project, error, status } = useProject(() => route.params.id)

// A project that does not exist, or one the studio switched off, hands over to the site's
// error page. Keyed on `status`, not `pending` — see the gallery album page for why.
watchEffect(() => {
  if (status.value === 'error' || (status.value === 'success' && !project.value)) {
    showError({ statusCode: error.value?.statusCode ?? 404, statusMessage: 'Project not found' })
  }
})

const { t, clientType, clientLine } = useAboutLabels()

const photos = computed(() => asList(project.value?.images))

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/about/projects', label: t('projects_title', 'Our projects', 'مشاريعنا') },
  { label: project.value?.title ?? '' },
])

useSeoMeta({
  title: () => project.value?.title ?? '',
  description: () => project.value?.description?.slice(0, 160) || clientLine(project.value),
})
</script>
