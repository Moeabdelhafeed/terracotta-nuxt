<template>
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="mx-auto flex max-w-3xl flex-col gap-5">
        <div class="flex items-center justify-between">
          <NuxtLink
            to="/"
            class="flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground -ms-2 rtl:-scale-x-100"
            :aria-label="t('back', 'Back', 'رجوع')"
          >
            <LucideArrowLeft class="size-5" />
          </NuxtLink>
          <h1 class="min-w-0 text-center font-display text-lg font-semibold text-foreground">{{ page?.name ?? '' }}</h1>
          <span class="size-10" />
        </div>

        <div v-if="pending" class="flex flex-col gap-3 rounded-2xl border bg-card p-5" aria-busy="true">
          <AppSkeleton class="h-8 w-1/2" />
          <AppSkeleton v-for="n in 6" :key="n" class="h-4" :class="n % 3 === 0 ? 'w-2/3' : 'w-full'" />
        </div>

        <div v-else-if="!page" class="flex flex-col items-center gap-3 rounded-2xl border bg-card p-10 text-center">
          <h2 class="font-display text-xl font-semibold text-foreground">{{ t('page_not_found', 'Page not found', 'الصفحة غير موجودة') }}</h2>
          <p class="text-sm text-muted-foreground">
            {{ t('page_not_found_note', 'This page does not exist or is unavailable.', 'هذه الصفحة غير موجودة أو غير متاحة.') }}
          </p>
        </div>

        <div v-else class="rounded-2xl border bg-card p-5 sm:p-8">
          <AppImage
            v-if="page.image?.image_api"
            :src="page.image"
            :alt="page.name"
            class="mb-6 aspect-video w-full rounded-xl object-cover"
          />
          <div
            class="prose prose-sm max-w-none break-words dark:prose-invert [&_a]:text-brand-rust [&_a]:underline [&_h2]:mt-6 [&_h2]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h3]:mt-4 [&_h3]:mb-2 [&_h3]:font-semibold [&_li]:my-1 [&_p]:my-3 [&_ul]:list-disc [&_ul]:ps-6 [&_img]:h-auto [&_img]:max-w-full [&_pre]:overflow-x-auto [&_table]:block [&_table]:overflow-x-auto"
            v-html="page.content"
          />
        </div>
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({ name: 'page' })

const route = useRoute()
const { t } = useLang()
const { page, pending } = usePage(() => route.params.slug)

// The CMS page's own content is HTML; the description is the first readable line of it.
const summary = computed(() => String(page.value?.content ?? '')
  .replace(/<[^>]*>/g, ' ')
  .replace(/\s+/g, ' ')
  .trim()
  .slice(0, 160))

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`

useSeoMeta({
  title: () => page.value?.name ?? '',
  description: () => summary.value,
  ogImage: () => page.value?.image?.image_api ?? fallbackCard,
})
</script>
