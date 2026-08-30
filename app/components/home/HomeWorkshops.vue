<template>
  <!--
    Motion note: the fade lives in the binding value (opacity: 0), not in the
    `fromInvisible` modifier. That modifier ships `opacity: 0` as plain SSR CSS, so a
    failed trigger — no JS, an error, a crawler — would leave the section invisible for
    good. Passing it to GSAP instead means the content renders visible and only animates
    when the script actually runs.
  -->
  <section id="workshops" v-if="workshops.length" class="mx-auto max-w-6xl px-6 py-24">
    <header class="mb-12 flex flex-wrap items-end justify-between gap-4">
      <div class="max-w-xl">
        <h2 class="font-display text-4xl font-semibold sm:text-5xl">
          {{ t('workshops_title', 'The workshop experience', 'تجربة الورشة') }}
        </h2>
        <p class="mt-3 text-muted-foreground">
          {{ t('workshops_subtitle', 'Hands-on sessions with an instructor — shape or paint your piece step by step in the studio.', 'جلسات عملية بإشراف مدرّبين تصنع أو تلوّن قطعتك خطوة بخطوة داخل الاستوديو') }}
        </p>
      </div>
      <NuxtLink to="/workshops" class="text-sm font-medium text-primary underline-offset-4 hover:underline">
        {{ t('view_all', 'View all', 'عرض الكل') }}
      </NuxtLink>
    </header>

    <ul
      v-gsap.whenVisible.once.from.stagger="{ opacity: 0, y: 48, duration: 0.7 }"
      class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3"
    >
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
            <!-- Workshops can ship without a photo; a flat grey box reads as broken, so
                 fall back to the workshop's own colour and mark. -->
            <div
              v-else
              class="flex size-full items-center justify-center"
              :style="{ backgroundColor: `color-mix(in oklch, ${workshop.color || 'var(--brand-terracotta)'} 18%, var(--brand-mist))` }"
            >
              <component
                :is="typeIcon(workshop.type)"
                class="size-14 opacity-70"
                :style="{ color: workshop.color || 'var(--brand-terracotta)' }"
              />
            </div>
            <span
              class="absolute top-4 rounded-full px-3 py-1 text-xs font-medium text-white ltr:left-4 rtl:right-4"
              :style="{ backgroundColor: workshop.color || 'var(--brand-terracotta)' }"
            >{{ typeLabel(workshop.type) }}</span>
          </div>

          <div class="flex flex-1 flex-col gap-2 p-6">
            <h3 class="font-display text-xl font-semibold">{{ workshop.title }}</h3>
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

            <p v-if="Number(workshop.price) > 0" class="font-display text-lg font-black text-primary">
              {{ format(workshop.price) }}
            </p>
          </div>
        </NuxtLink>
      </li>
    </ul>
  </section>
</template>

<script setup>
const { workshops } = useWorkshops()
const { t } = useLang('web', 'home')
const { format } = usePrice()

const typeIcon = (type) => ({
  make_your_piece: resolveComponent('LucideHandHelping'),
  paint_your_piece: resolveComponent('LucidePaintbrush'),
  make_your_candle: resolveComponent('LucideFlame'),
}[type] ?? resolveComponent('LucideShapes'))

const typeLabel = (type) => ({
  make_your_piece: t('type_make_piece', 'Make your piece', 'اصنع قطعتك'),
  paint_your_piece: t('type_paint_piece', 'Paint your piece', 'لوّن قطعتك'),
  make_your_candle: t('type_make_candle', 'Make your candle', 'اصنع شمعتك'),
}[type] ?? type)
</script>
