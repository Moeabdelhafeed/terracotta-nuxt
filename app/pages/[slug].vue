<template>
  <main class="bg-background">
    <!-- The same header every inner page wears — mark, breadcrumb trail, then the picture
         with the title over it. A CMS page carries its own `image`, so the hero is the
         one the operator uploaded with the page; a page with no picture falls back to the
         plain title, which PageHero already draws. -->
    <PageHero
      :image="page?.image?.image_api ? page.image : null"
      :crumbs="[
        { to: '/', label: t('nav_home', 'Home', 'الرئيسية') },
        { label: page?.name ?? t('page', 'Page', 'صفحة') },
      ]"
      :title="page?.name ?? ''"
    />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="mx-auto flex max-w-3xl flex-col gap-5">
        <div v-if="pending" class="flex flex-col gap-3 rounded-2xl border bg-card p-5" aria-busy="true">
          <AppSkeleton class="h-8 w-1/2" />
          <AppSkeleton v-for="n in 6" :key="n" class="h-4" :class="n % 3 === 0 ? 'w-2/3' : 'w-full'" />
        </div>

        <AppLoadError v-else-if="status === 'error'" :error="error" :retry="refresh" />

        <div v-else-if="page" class="rounded-2xl border bg-card p-5 sm:p-8">
          <div
            class="prose prose-sm max-w-none break-words dark:prose-invert [&_a]:text-brand-terracotta [&_a]:underline [&_h2]:mt-6 [&_h2]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h3]:mt-4 [&_h3]:mb-2 [&_h3]:font-semibold [&_li]:my-1 [&_p]:my-3 [&_ul]:list-disc [&_ul]:ps-6 [&_img]:h-auto [&_img]:max-w-full [&_pre]:overflow-x-auto [&_table]:block [&_table]:overflow-x-auto"
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
const { page, pending, status, error, refresh } = usePage(() => route.params.slug)

// An unknown slug has to answer 404, not a 200 carrying a "not found" card — otherwise a
// typo, a stale inbound link or a crawler gets a success status and the page is indexed.
// Keyed on `status`, not `pending`: a client-side navigation arrives with the fetch not
// yet started, where `pending` is false and the record still null.
watchEffect(() => {
  if (status.value === 'success' && !page.value) {
    showError({ statusCode: 404, statusMessage: 'Page not found' })
  }
})

// The CMS page's own content is HTML; the description is the first readable line of it.
const summary = computed(() => String(page.value?.content ?? '')
  .replace(/<[^>]*>/g, ' ')
  .replace(/\s+/g, ' ')
  .trim()
  .slice(0, 160))


useSeoMeta({
  title: () => page.value?.name ?? '',
  description: () => summary.value,
})
</script>
