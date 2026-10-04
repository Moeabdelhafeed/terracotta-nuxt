<template>
  <!-- A portfolio tile, not a shop card: the photograph IS the card, the words sit on it.
       A product card has a white body with a price under its picture; drawn the same way,
       a hotel commission read as something you could put in a basket. -->
  <NuxtLink
    :to="`/about/projects/${project.id}`"
    class="group relative block aspect-[4/5] overflow-hidden rounded-card bg-brand-ink"
    data-test="project-card"
  >
    <AppImage
      v-if="project.image?.image_api"
      :src="project.image"
      :alt="project.title"
      class="absolute inset-0 size-full object-cover transition-transform duration-700 group-hover:scale-105"
    />

    <!-- Dark from the bottom up, so the white words read over any photograph. -->
    <span class="absolute inset-0 bg-gradient-to-t from-brand-ink/90 via-brand-ink/30 to-transparent" aria-hidden="true" />

    <span class="absolute inset-x-4 top-4 flex items-start justify-between gap-3">
      <span v-if="project.category" class="rounded-full bg-white/90 px-3 py-1 text-xs font-semibold text-brand-terracotta backdrop-blur-sm">
        {{ project.category.name }}
      </span>
      <!-- The client's mark, on white so a logo drawn for a light ground stays legible. -->
      <span
        v-if="project.logo?.image_api"
        class="ms-auto flex size-14 shrink-0 items-center justify-center overflow-hidden rounded-full bg-white p-2 shadow-sm"
      >
        <AppImage :src="project.logo" :alt="project.client_name || ''" class="size-full object-contain" />
      </span>
    </span>

    <span class="absolute inset-x-0 bottom-0 flex flex-col gap-1.5 p-5 text-white">
      <span class="font-display text-xl font-semibold leading-snug">{{ project.title }}</span>
      <span class="text-sm text-white/80">{{ [clientLine(project), project.year].filter(Boolean).join(' · ') }}</span>
      <span
        class="mt-2 inline-flex items-center gap-1.5 text-sm font-medium text-white/90 transition-opacity duration-300 sm:opacity-0 sm:group-hover:opacity-100"
      >
        {{ t('view_project', 'View project', 'عرض المشروع') }}
        <LucideArrowRight class="size-4 rtl:-scale-x-100" />
      </span>
    </span>
  </NuxtLink>
</template>

<script setup>
/** One project, as the home page, the About teaser and the projects list all show it. */
defineProps({
  project: { type: Object, required: true },
})

const { t, clientLine } = useAboutLabels()
</script>
