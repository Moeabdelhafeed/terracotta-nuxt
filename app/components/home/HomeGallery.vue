<template>
  <section id="gallery" v-if="pool.length" ref="root" class="bg-brand-mist/40">
    <!-- Exactly one viewport tall: header at the top, the wall taking whatever is left.
         Any spare height here pools above the heading as a gap. -->
    <div ref="panel" class="flex h-svh w-full flex-col gap-5 px-4 py-24 sm:px-6">
      <header class="mx-auto w-full max-w-[1600px]">
        <h2 class="font-display text-3xl font-semibold sm:text-4xl">
          {{ t('gallery_title', 'From the studio', 'من الاستوديو') }}
        </h2>
        <p class="mt-2 text-muted-foreground">
          {{ t('gallery_subtitle', 'Pieces our guests shaped, glazed and took home.', 'قطع صنعها ضيوفنا بأيديهم وأخذوها معهم.') }}
        </p>
      </header>

      <!-- Bento: fixed cells, changing contents. Each tile keeps its shape while the
           photograph inside it is swapped as the section is scrolled. -->
      <ul class="mx-auto grid w-full min-h-0 max-w-[1600px] flex-1 grid-cols-2 grid-rows-4 gap-3 sm:grid-cols-4 sm:grid-rows-3 sm:gap-4">
        <li
          v-for="(cell, index) in CELLS"
          :key="index"
          :class="cell"
          class="relative overflow-hidden bg-black/5"
        >
          <!-- A vertical strip of photographs, taller than the tile. Scroll drives its
               offset, so the pictures slide through the window rather than playing a
               transition of their own. -->
          <div ref="strips" class="absolute inset-0 will-change-transform">
            <div
              v-for="(slide, position) in slidesFor(index)"
              :key="slide.id"
              class="absolute inset-x-0 h-full"
              :style="{ top: `${position * 100}%` }"
            >
              <AppImage :src="slide.image" alt="" class="size-full object-cover" />
            </div>
          </div>
        </li>
      </ul>
    </div>
  </section>
</template>

<script setup>
/**
 * A bento wall of studio photographs, pinned while it is on screen: the tiles hold their
 * shape and the pictures inside them change as the section is scrolled.
 *
 * The pool is every image across every gallery category, gathered in one `useAsyncData`
 * so the whole set arrives with the server render.
 */
const { t } = useLang('web', 'home')
const api = useApi()

const lang = useCookie('lang')
const i18nLocale = useCookie('i18n_locale')

// Six tiles filling a 4x3 grid: 4 + 1 + 2 + 1 + 3 + 1 = 12 cells.
// Two columns on a phone (4 rows), four from `sm` up (3 rows). Both fill exactly.
const CELLS = [
  'col-span-2 row-span-2 sm:col-span-2 sm:row-span-2',
  'col-span-1 row-span-1 sm:col-span-1 sm:row-span-1',
  'col-span-1 row-span-2 sm:col-span-1 sm:row-span-2',
  'col-span-1 row-span-1 sm:col-span-1 sm:row-span-1',
  'col-span-2 row-span-1 sm:col-span-3 sm:row-span-1',
  'col-span-2 row-span-2 sm:col-span-1 sm:row-span-1',
]

const { data: pool } = await useAsyncData(
  'gallery-pool',
  async () => {
    const list = (await api('/api/gallery'))?.data ?? []

    const details = await Promise.all(
      list.map((category) => api(`/api/gallery/${category.id}`).catch(() => null)),
    )

    return details
      .flatMap((detail) => detail?.data?.items ?? [])
      .filter((item) => item.type === 'image' && item.image?.image_api)
  },
  { default: () => [], watch: [lang, i18nLocale] },
)

// How many photographs each tile cycles through.
const SLIDES = 4
// Timeline units: how long a photograph takes to slide in, and how long it then rests.
const MOVE = 1
const HOLD = 0.7

// Each tile starts at a different point in the pool, so no two windows show the same
// picture at the same time.
const slidesFor = (index) => {
  const items = pool.value
  if (!items.length) return []

  return Array.from({ length: SLIDES }, (_, position) => items[(index * SLIDES + position) % items.length])
}

const root = ref()
const panel = ref()
const strips = ref([])

let context = null

onMounted(async () => {
  if (!pool.value.length) return

  const gsap = useGSAP()
  // Imported here rather than at module scope: the plugin touches the document on import,
  // which would take the SSR render down.
  const { ScrollTrigger } = await import('gsap/all')
  gsap.registerPlugin(ScrollTrigger)

  await nextTick()
  if (!root.value || !panel.value) return

  context = gsap.context(() => {
    // Stepped rather than continuous: each photograph slides into place, then the
    // timeline holds it there for a stretch of scroll before the next one moves. The
    // hold is an empty tween — a scrubbed timeline maps its own time onto scroll
    // distance, so dead time on the timeline is dwell time on the page.
    const tl = gsap.timeline({
      scrollTrigger: {
        trigger: root.value,
        start: 'top top',
        end: () => `+=${(SLIDES - 1) * (MOVE + HOLD) * 620}`,
        pin: panel.value,
        scrub: true,
        invalidateOnRefresh: true,
      },
    })

    for (let slide = 1; slide < SLIDES; slide++) {
      tl.to(strips.value, {
        yPercent: -100 * slide,
        duration: MOVE,
        ease: 'power2.inOut',
      })
      tl.to({}, { duration: HOLD })
    }
  }, root.value)
})

onBeforeUnmount(() => context?.revert())
</script>
