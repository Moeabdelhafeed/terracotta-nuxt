<template>
  <NuxtLink
    :to="`/about/news/${item.id}`"
    class="group flex h-full items-start gap-4 rounded-card border bg-card p-4 transition-[transform,box-shadow] duration-200 hover:-translate-y-0.5 hover:shadow-md"
  >
    <!-- The event's own date, as a calendar leaf: it is what a timeline is read by. -->
    <span
      class="flex w-16 shrink-0 flex-col items-center gap-0.5 rounded-control bg-brand-terracotta px-1 py-2.5 text-center text-white"
    >
      <span class="font-display text-2xl font-bold leading-none">{{ day(item.starts_on, { day: "numeric" }) }}</span>
      <span class="text-[11px] text-white/85">{{ day(item.starts_on, { month: "short" }) }}</span>
    </span>

    <span class="flex min-w-0 flex-1 flex-col gap-1">
      <span class="self-start rounded-full bg-brand-terracotta/10 px-2.5 py-0.5 text-xs font-medium text-brand-terracotta">
        {{ newsType(item.type) }}
      </span>
      <span class="font-display text-base font-semibold leading-snug">{{ item.title }}</span>
      <span class="text-sm text-muted-foreground">
        {{ [item.place, day(item.starts_on, { year: "numeric" })].filter(Boolean).join(" · ") }}
      </span>
    </span>

    <span v-if="item.image?.image_api" class="hidden size-20 shrink-0 overflow-hidden rounded-control bg-brand-mist sm:block">
      <AppImage :src="item.image" :alt="item.title" class="size-full object-cover" />
    </span>
  </NuxtLink>
</template>

<script setup>
/** One event or conference, as the About teaser and the news timeline both show it. */
defineProps({
  item: { type: Object, required: true },
});

const { newsType, day } = useAboutLabels();
</script>
