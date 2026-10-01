<template>
  <NuxtLink
    :to="`/about/projects/${project.id}`"
    class="group flex h-full flex-col overflow-hidden rounded-card border bg-card transition-[transform,box-shadow] duration-200 hover:-translate-y-0.5 hover:shadow-md"
  >
    <div class="relative aspect-[4/3] overflow-hidden bg-brand-mist">
      <AppImage
        v-if="project.image?.image_api"
        :src="project.image"
        :alt="project.title"
        class="size-full object-cover transition-transform duration-500 group-hover:scale-105"
      />

      <!-- The client's mark, on white so a logo drawn for a light ground stays legible
           over any photograph. -->
      <span
        v-if="project.logo?.image_api"
        class="absolute bottom-3 flex size-12 items-center justify-center overflow-hidden rounded-full bg-white p-1.5 shadow-sm ltr:left-3 rtl:right-3"
      >
        <AppImage :src="project.logo" :alt="project.client_name || ''" class="size-full object-contain" />
      </span>
    </div>

    <div class="flex flex-1 flex-col gap-1.5 p-4">
      <span class="self-start rounded-full bg-brand-terracotta/10 px-2.5 py-0.5 text-xs font-medium text-brand-terracotta">
        {{ clientType(project.client_type) }}
      </span>
      <h3 class="font-display text-lg font-semibold leading-snug">{{ project.title }}</h3>
      <p class="mt-auto text-sm text-muted-foreground">
        {{ [clientLine(project), project.year].filter(Boolean).join(" · ") }}
      </p>
    </div>
  </NuxtLink>
</template>

<script setup>
/** One project, as the About teaser and the projects list both show it. */
defineProps({
  project: { type: Object, required: true },
});

const { clientType, clientLine } = useAboutLabels();
</script>
