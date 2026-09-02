<template>
  <main>
    <PageHero
      media-key="hero_workshops"
      fallback="/seed/hero-workshops.webp"
      :crumbs="[
        { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
        { label: t('nav_workshops', 'Workshops', 'الورشات', { subGroup: 'general' }) },
      ]"
      :title="t('workshops_title', 'The workshop experience', 'تجربة الورشة')"
      :subtitle="t('workshops_subtitle', 'Hands-on sessions with an instructor — shape or paint your piece step by step in the studio.', 'جلسات عملية بإشراف مدرّبين تصنع أو تلوّن قطعتك خطوة بخطوة داخل الاستوديو')"
    />

    <div class="mx-auto max-w-6xl px-6 py-16">

      <ul v-if="pending" class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3" aria-busy="true">
        <li v-for="n in 3" :key="n" class="overflow-hidden rounded-3xl border bg-card">
          <AppSkeleton class="aspect-[4/3] w-full !rounded-none" />
          <div class="flex flex-col gap-3 p-6">
            <AppSkeleton class="h-6 w-2/3" />
            <AppSkeleton class="h-4 w-full" />
            <AppSkeleton class="h-4 w-4/5" />
            <div class="mt-4 flex gap-4">
              <AppSkeleton class="h-4 w-20" />
              <AppSkeleton class="h-4 w-20" />
            </div>
          </div>
        </li>
      </ul>

      <ul v-else class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
      <li v-for="workshop in workshops" :key="workshop.id">
        <NuxtLink
          :to="`/workshops/${workshop.id}`"
          class="group flex h-full flex-col overflow-hidden rounded-3xl border bg-card transition-shadow hover:shadow-lg"
        >
          <div class="relative aspect-[4/3] overflow-hidden bg-brand-mist">
            <AppImage
              v-if="workshop.image?.image_api"
              :src="workshop.image"
              :alt="workshop.title"
              class="size-full object-cover transition-transform duration-700 group-hover:scale-105"
            />
            <span
              class="absolute top-4 rounded-full px-3 py-1 text-xs font-medium text-white ltr:left-4 rtl:right-4"
              :style="{ backgroundColor: workshop.color || 'var(--brand-terracotta)' }"
            >{{ typeLabel(workshop.type) }}</span>
          </div>

          <div class="flex flex-1 flex-col gap-2 p-6">
            <h2 class="font-display text-xl font-semibold">{{ workshop.title }}</h2>
            <p class="line-clamp-2 text-sm text-muted-foreground">{{ workshop.short_description }}</p>

            <dl class="mt-auto flex items-center gap-4 pt-4 text-sm text-muted-foreground">
              <div class="flex items-center gap-1.5">
                <LucideClock class="size-4" />
                <dd>{{ t('minutes', ':n min', ':n دقيقة', { n: workshop.duration_minutes }) }}</dd>
              </div>
              <div class="flex items-center gap-1.5">
                <LucideUsers class="size-4" />
                <dd>{{ t('up_to_people', 'up to :n', 'حتى :n', { n: workshop.max_people_per_booking }) }}</dd>
              </div>
            </dl>
          </div>
        </NuxtLink>
      </li>
      </ul>
    </div>
  </main>
</template>

<script setup>
const { workshops, pending } = useWorkshops()
const { t } = useLang('web', 'home')

const typeLabel = (type) => ({
  make_your_piece: t('type_make_piece', 'Make your piece', 'اصنع قطعتك'),
  paint_your_piece: t('type_paint_piece', 'Paint your piece', 'لوّن قطعتك'),
  make_your_candle: t('type_make_candle', 'Make your candle', 'اصنع شمعتك'),
}[type] ?? type)

const { media: heroMedia } = useMedia('web', 'heroes')

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`

useSeoMeta({
  title: () => t('workshops_title', 'Workshops', 'الورشات'),
  description: () => t('workshops_subtitle', 'Hands-on sessions with an instructor — shape or paint your piece step by step in the studio.', 'جلسات عملية بإشراف مدرّبين تصنع أو تلوّن قطعتك خطوة بخطوة داخل الاستوديو'),
  ogImage: () => heroMedia('hero_workshops') ?? fallbackCard,
})

useSchemaOrg([
  defineBreadcrumb({
    itemListElement: [
      { name: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }), item: '/' },
      { name: t('nav_workshops', 'Workshops', 'الورشات', { subGroup: 'general' }), item: '/workshops' },
    ],
  }),
])
</script>
