<template>
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-5">
        <div class="flex items-center justify-between">
          <NuxtLink
            to="/profile"
            class="flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground -ms-2 rtl:-scale-x-100"
            :aria-label="t('back_to_profile', 'Back to profile', 'عودة للملف')"
          >
            <LucideArrowLeft class="size-5" />
          </NuxtLink>
          <h1 class="font-display text-lg font-semibold text-foreground">{{ t('my_gallery', 'My gallery', 'معرضي') }}</h1>
          <span class="size-10" />
        </div>
        <p class="-mt-3 text-center text-sm text-muted-foreground">
          {{ t('my_gallery_description', 'Photos of the pieces you made in workshops.', 'صور القطع التي صنعتها في الورشات.') }}
        </p>

        <div v-if="pending" class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6" aria-busy="true">
          <AppSkeleton v-for="n in 12" :key="n" class="aspect-square w-full rounded-xl" />
        </div>

        <div v-else-if="!photos.length" class="mx-auto flex w-full max-w-xl flex-col items-center gap-2 rounded-2xl border bg-card p-10 text-center">
          <p class="text-sm text-muted-foreground">{{ t('no_photos_yet', 'No photos yet.', 'لا توجد صور بعد.') }}</p>
        </div>

        <div v-else class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
          <a
            v-for="photo in photos"
            :key="photo.id"
            :href="photo.image_api"
            target="_blank"
            rel="noopener noreferrer"
            class="group flex flex-col gap-1.5"
          >
            <AppImage :src="photo" :alt="photo.piece_label ?? photo.workshop_title" class="aspect-square w-full rounded-xl object-cover transition-opacity group-hover:opacity-90" />
            <span class="truncate text-xs text-muted-foreground">{{ photo.piece_label ?? photo.workshop_title }}</span>
          </a>
        </div>

        <!-- Real links, so a page is shareable and crawlable rather than a click handler. -->
        <nav v-if="lastPage > 1" class="mt-2 flex flex-wrap items-center justify-center gap-2">
          <Button v-if="currentPage > 1" as-child size="sm" variant="outline" class="rounded-xl">
            <NuxtLink :to="linkTo(currentPage - 1)" rel="prev">{{ t('previous', 'Previous', 'السابق') }}</NuxtLink>
          </Button>
          <Button
            v-for="number in pageNumbers"
            :key="number"
            as-child
            size="sm"
            :variant="number === currentPage ? 'default' : 'outline'"
            class="min-w-10 rounded-xl"
          >
            <NuxtLink :to="linkTo(number)" :aria-current="number === currentPage ? 'page' : undefined">{{ number }}</NuxtLink>
          </Button>
          <Button v-if="currentPage < lastPage" as-child size="sm" variant="outline" class="rounded-xl">
            <NuxtLink :to="linkTo(currentPage + 1)" rel="next">{{ t('next', 'Next', 'التالي') }}</NuxtLink>
          </Button>
        </nav>
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'my-gallery',
})

const route = useRoute()
const { t } = useLang('web', 'profile')

const PER_PAGE = 12
const currentPage = computed(() => Math.max(1, Number(route.query.page ?? 1)))

const { data, pending } = useApiFetch('/api/workshops/images', {
  key: 'my-workshop-photos',
  query: { page: currentPage, per_page: PER_PAGE },
})

const photos = computed(() => {
  const payload = asList(data.value?.data)
  return Array.isArray(payload) ? payload : (payload.data ?? [])
})

const lastPage = computed(() => data.value?.data?.last_page ?? 1)

const pageNumbers = computed(() => {
  const last = lastPage.value
  const span = 2
  const from = Math.max(1, currentPage.value - span)
  const to = Math.min(last, currentPage.value + span)
  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

const linkTo = (page) => ({ query: { ...route.query, page: page > 1 ? page : undefined } })
</script>
