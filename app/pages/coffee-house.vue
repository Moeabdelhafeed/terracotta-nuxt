<template>
  <main class="bg-background">
    <PageHero
      media-key="hero_coffee_house"
      fallback="/seed/studio-3.webp"
      :crumbs="crumbs"
      :title="t('coffee_title', 'Coffee house', 'المقهى')"
      :subtitle="t('coffee_subtitle', 'Coffee, tea and something sweet — order at the counter.', 'قهوة وشاي وشيء حلو — اطلب من الكاونتر.')"
    />

    <div class="mx-auto max-w-6xl px-6 py-12">
      <!-- Only sections with something in them come back from the API, so every pill
           opens a list that has items. -->
      <div
        v-if="sections.length > 1"
        class="mb-8 flex flex-wrap gap-2"
        role="group"
        :aria-label="t('coffee_filter', 'Menu sections', 'أقسام القائمة')"
      >
        <button
          v-for="section in [null, ...sections]"
          :key="section?.id ?? 'all'"
          type="button"
          class="rounded-full border px-4 py-2 text-sm transition-colors"
          :class="(section?.id ?? null) === active ? 'border-brand-ink bg-brand-ink text-white' : 'bg-card hover:bg-brand-mist'"
          :aria-pressed="(section?.id ?? null) === active"
          data-test="coffee-filter"
          @click="active = section?.id ?? null"
        >
          {{ section ? section.title : t('all', 'All', 'الكل') }}
        </button>
      </div>

      <div v-if="pending && !sections.length" class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3" aria-busy="true">
        <AppSkeleton v-for="n in 6" :key="n" class="aspect-[4/5] w-full !rounded-card" />
      </div>

      <AppLoadError v-else-if="error && !sections.length" :error="error" :retry="refresh" />

      <div
        v-else-if="!sections.length"
        class="mx-auto flex max-w-xl flex-col items-center gap-3 rounded-card border bg-card p-10 text-center"
        data-test="coffee-empty"
      >
        <span class="flex size-12 items-center justify-center rounded-control bg-brand-terracotta/10 text-brand-terracotta">
          <LucideCoffee class="size-5" />
        </span>
        <h2 class="font-display text-lg font-semibold">{{ t('coffee_empty_title', 'The menu is being written', 'القائمة قيد الإعداد') }}</h2>
        <p class="text-sm text-muted-foreground">
          {{ t('coffee_empty_body', 'Ask at the counter for today\'s drinks.', 'اسأل في الكاونتر عن مشروبات اليوم.') }}
        </p>
      </div>

      <div v-else class="space-y-12">
        <section v-for="section in shown" :key="section.id" data-test="coffee-section">
          <h2 class="mb-5 border-b pb-2 font-display text-2xl font-bold text-brand-terracotta">{{ section.title }}</h2>
          <ul class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            <li v-for="item in section.items" :key="item.id"><CoffeeItemCard :item="item" /></li>
          </ul>
        </section>
      </div>
    </div>
  </main>
</template>

<script setup>
/**
 * The coffee house menu. Fetched whole — a menu, not a feed — so the section pills filter
 * on the page without a request. The hero is dynamic storage (`heroes` / `hero_coffee_house`)
 * and its words translations, like every other page's.
 */
const { t } = useLang('web', 'coffee')
const { sections, pending, error, refresh } = useCoffeeMenu()

const active = ref(null)
const shown = computed(() => (active.value ? sections.value.filter((section) => section.id === active.value) : sections.value))

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { label: t('coffee_title', 'Coffee house', 'المقهى') },
])

useSeoMeta({
  title: () => t('coffee_title', 'Coffee house', 'المقهى'),
  description: () => t('coffee_subtitle', 'Coffee, tea and something sweet — order at the counter.', 'قهوة وشاي وشيء حلو — اطلب من الكاونتر.'),
})
</script>
