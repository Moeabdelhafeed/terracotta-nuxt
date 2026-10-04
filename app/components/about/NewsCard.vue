<template>
  <NuxtLink
    :to="`/about/news/${item.id}`"
    class="group flex h-full overflow-hidden rounded-card border bg-card transition-[transform,box-shadow] duration-200 hover:-translate-y-0.5 hover:shadow-md"
  >
    <span class="flex min-w-0 flex-1 items-start gap-4 p-4">
      <!-- The event's own date, as a calendar leaf: it is what a timeline is read by. -->
      <span
        class="flex w-16 shrink-0 flex-col items-center gap-0.5 rounded-control bg-brand-terracotta px-1 py-2.5 text-center text-white"
      >
        <span class="font-display text-2xl font-bold leading-none">{{ day(item.starts_on, { day: "numeric" }) }}</span>
        <span class="text-[11px] text-white/85">{{ day(item.starts_on, { month: "short" }) }}</span>
      </span>

      <span class="flex min-w-0 flex-1 flex-col gap-1">
        <span v-if="item.category" class="self-start rounded-full bg-brand-terracotta/10 px-2.5 py-0.5 text-xs font-medium text-brand-terracotta">
          {{ item.category.name }}
        </span>
        <span class="font-display text-base font-semibold leading-snug">{{ item.title }}</span>
        <span class="text-sm text-muted-foreground">
          {{ [item.place, day(item.starts_on, { year: "numeric" })].filter(Boolean).join(" · ") }}
        </span>
      </span>
    </span>

    <!-- The photograph runs the card's full height along its edge, flush, rather than a
         thumbnail floating in the padding. -->
    <span v-if="item.image?.image_api" class="relative w-24 shrink-0 self-stretch overflow-hidden bg-brand-mist sm:w-32">
      <AppImage
        :src="item.image"
        :alt="item.title"
        class="absolute inset-0 size-full object-cover transition-transform duration-500 group-hover:scale-105"
      />
    </span>
  </NuxtLink>
</template>

<script setup>
/** One event or conference, as the home page, the About teaser and the news timeline all show it. */
defineProps({
  item: { type: Object, required: true },
});

const { day } = useAboutLabels();
</script>
