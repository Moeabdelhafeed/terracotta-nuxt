<template>
  <!-- Ink at the top, terracotta at the foot: the band darkens out of the light gallery
       above it and then hands off to the footer's terracotta without a seam. -->
  <section
    id="visit"
    class="relative isolate overflow-hidden bg-brand-ink text-white"
  >
    <!-- The same line as the hero and the footer, so the page closes on the motif it
         opened with. Decorative only. -->
    <svg
      class="pointer-events-none absolute inset-0 -z-10 h-full w-full text-white/15"
      viewBox="0 0 1601 922"
      fill="none"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden="true"
    >
      <path
        d="M533.499 -308.5C561.499 -140.5 487.899 246.8 -30.5009 452C-678.501 708.5 240.999 -304.5 884.499 -146.5C1528 11.5 1738 466.5 1512 1153.5C1286 1840.5 349.5 489.5 -89.5 497.5"
        stroke="currentColor"
        stroke-width="2"
        vector-effect="non-scaling-stroke"
      />
    </svg>

    <div class="mx-auto grid max-w-6xl gap-10 px-6 py-20 sm:gap-14 sm:py-28 lg:grid-cols-[1.2fr_1fr] lg:items-end">
      <div>
        <p class="text-xs uppercase tracking-[0.25em] text-white/50">
          {{ t('visit_eyebrow', 'The studio', 'الاستوديو') }}
        </p>

        <h2 class="mt-5 max-w-2xl font-display text-3xl font-semibold leading-[1.15] sm:text-5xl lg:text-6xl">
          {{ t('visit_title', 'Come and make something', 'تعال واصنع شيئًا') }}
        </h2>

        <p class="mt-5 max-w-lg text-lg leading-relaxed text-white/75">
          {{ t('visit_subtitle', 'Book a seat, bring whoever you like, and leave with a piece that did not exist this morning.', 'احجز مقعدك، واحضر من تحب، واخرج بقطعة لم تكن موجودة هذا الصباح.') }}
        </p>

        <div class="mt-10 flex flex-wrap items-center gap-3">
          <Button size="lg" class="h-13 rounded-xl px-8 text-base" @click="scrollToWorkshops">
            {{ t('book_workshop', 'Book a workshop', 'احجز ورشة') }}
          </Button>

          <Button
            v-if="locationUrl"
            as-child
            size="lg"
            variant="outline"
            class="h-13 rounded-xl border-white/35 bg-transparent px-8 text-base text-white hover:border-white/60 hover:bg-white/10 hover:text-white"
          >
            <a :href="locationUrl" target="_blank" rel="noopener noreferrer">
              {{ t('get_directions', 'Get directions', 'الاتجاهات') }}
            </a>
          </Button>
        </div>
      </div>

      <!-- The practical facts, straight off the workshop the visitor would book. -->
      <dl v-if="facts.length" class="grid gap-px overflow-hidden rounded-2xl bg-white/15 sm:grid-cols-3 lg:grid-cols-1">
        <div v-for="fact in facts" :key="fact.label" class="bg-brand-ink px-6 py-6">
          <dt class="text-xs uppercase tracking-[0.2em] text-white/45">{{ fact.label }}</dt>
          <dd class="mt-2 font-display text-2xl font-semibold">{{ fact.value }}</dd>
        </div>
      </dl>
    </div>
  </section>
</template>

<script setup>
/**
 * The closing section: one statement, one action, and the few facts someone needs before
 * they commit. Contact details and socials live in the footer directly below, so they are
 * deliberately not repeated here.
 */
const { workshops } = useWorkshops()
const { t } = useLang('web', 'home')

const featured = computed(() => workshops.value[0] ?? null)
const locationUrl = computed(() => featured.value?.location_url ?? null)

const facts = computed(() => {
  const workshop = featured.value
  if (!workshop) return []

  return [
    {
      label: t('fact_duration', 'A session', 'الجلسة'),
      value: t('minutes', ':n min', ':n دقيقة', { n: workshop.duration_minutes }),
    },
    {
      label: t('fact_seats', 'Seats', 'المقاعد'),
      value: t('per_session', ':n per session', ':n لكل جلسة', { n: workshop.capacity_per_session }),
    },
    {
      label: t('fact_tracks', 'Workshops', 'الورشات'),
      value: t('tracks_count', ':n to choose from', ':n للاختيار', { n: workshops.value.length }),
    },
  ]
})

// The page scrolls through ScrollSmoother, so a native anchor jump would be ignored.
// Imported inside the handler: ScrollSmoother touches the document at module scope, and a
// top-level import of it takes the SSR render down with it.
const scrollToWorkshops = async () => {
  const target = document.getElementById('workshops')
  if (!target) return

  const { ScrollSmoother } = await import('gsap/all')
  const smoother = ScrollSmoother.get?.()

  if (smoother) smoother.scrollTo(target, true, 'top 80px')
  else target.scrollIntoView({ behavior: 'smooth' })
}
</script>
