<template>
  <section v-if="items.length" id="banners" class="relative py-16">
    <ul
      ref="track"
      v-gsap.whenVisible.once.from.stagger="{ opacity: 0, y: 32, duration: 0.6 }"
      class="flex snap-x snap-mandatory gap-4 overflow-x-auto overflow-y-hidden scrollbar-none scroll-ps-6 px-6 pb-2"
    >
      <li
        v-for="banner in items"
        :key="banner.id"
        class="w-[85%] shrink-0 snap-start sm:w-[48%] lg:w-[32%]"
      >
        <!-- Three shapes, one card: an in-app link, an external anchor that opens in a new
             tab, and a plain box for a `none` banner, which is decoration and takes no tap. -->
        <component
          :is="banner.tag"
          v-bind="banner.attrs"
          class="group relative block aspect-[3/2] overflow-hidden rounded-2xl bg-brand-mist lg:aspect-[16/9]"
        >
          <AppImage
            v-if="banner.image?.image_api"
            :src="banner.image"
            :alt="banner.title"
            class="size-full object-cover transition-transform duration-700 group-hover:scale-105"
          />

          <div class="absolute inset-0 flex flex-col justify-end gap-1 bg-gradient-to-t from-brand-ink/85 via-brand-ink/35 to-transparent p-5 text-white">
            <p v-if="banner.label" class="text-xs font-medium uppercase tracking-wide text-white/80">{{ banner.label }}</p>
            <h3 class="font-display text-xl font-semibold drop-shadow-sm sm:text-2xl">{{ banner.title }}</h3>
            <span
              v-if="banner.cta_text && banner.attrs.to"
              class="mt-1 text-sm font-medium underline-offset-4 group-hover:underline"
            >
              {{ banner.cta_text }}
            </span>
            <span
              v-else-if="banner.cta_text && banner.attrs.href"
              class="mt-1 inline-flex items-center gap-1 text-sm font-medium underline-offset-4 group-hover:underline"
            >
              {{ banner.cta_text }}
              <LucideExternalLink class="size-3.5" />
            </span>
          </div>
        </component>
      </li>
    </ul>

    <!-- Paging by card, not by pixel. The track is a plain scroller, so RTL flips the
         sign of `scrollBy` — read the resolved direction rather than assuming LTR. -->
    <!-- Arrows from `sm` up only: a finger drags the rail itself, and two buttons sitting
         over a 390px-wide banner cover the thing they are there to reveal. -->
    <template v-if="items.length > 1">
      <button
        type="button"
        class="absolute top-1/2 z-10 hidden size-11 -translate-y-1/2 items-center justify-center rounded-xl border bg-background/90 text-brand-terracotta shadow-sm backdrop-blur transition-colors hover:bg-background sm:flex ltr:left-3 rtl:right-3"
        :aria-label="t('previous', 'Previous', 'السابق', { subGroup: 'general' })"
        @click="scrollByCard(-1)"
      >
        <LucideChevronLeft class="size-5 rtl:rotate-180" />
      </button>

      <button
        type="button"
        class="absolute top-1/2 z-10 hidden size-11 -translate-y-1/2 items-center justify-center rounded-xl border bg-background/90 text-brand-terracotta shadow-sm backdrop-blur transition-colors hover:bg-background sm:flex ltr:right-3 rtl:left-3"
        :aria-label="t('next', 'Next', 'التالي', { subGroup: 'general' })"
        @click="scrollByCard(1)"
      >
        <LucideChevronRight class="size-5 rtl:rotate-180" />
      </button>
    </template>
  </section>
</template>

<script setup>
/**
 * The promo carousel from `GET /api/home`. The first banner is the page's hero
 * (`HomeHero` renders it full-bleed), so this is the rest of the set.
 *
 * `link_type` alone decides the destination — `bannerRoute` maps all ten of them, and the
 * `page` type needs the CMS list, since the API sends a numeric page id and the route
 * takes the slug.
 */
import { NuxtLink } from '#components'

/** `gap-4` in the track, needed in JS to page by a whole card. */
const GAP = 16

const { banners } = useHome()
const { pages } = usePages()
const { t } = useLang('web', 'home')

const track = ref()

// No mouse drag here: this rail has arrows, and they are the desktop way through it.
// What is still wanted is the click guard — a finger that swipes the rail must not open
// the card it happened to start on.
useDragScroll(track, { drag: false })

const scrollByCard = (direction) => {
  const el = track.value
  if (!el) return
  const card = el.firstElementChild
  const step = card ? card.offsetWidth + GAP : el.clientWidth
  const sign = getComputedStyle(el).direction === 'rtl' ? -1 : 1
  el.scrollBy({ left: step * direction * sign, behavior: 'smooth' })
}

const items = computed(() => banners.value
  .slice(1)
  .map((banner) => {
    const route = bannerRoute(banner, pages.value)
    const external = isExternalRoute(route)

    return {
      ...banner,
      route,
      tag: !route ? 'div' : external ? 'a' : NuxtLink,
      attrs: !route
        ? {}
        : external
          ? { href: route, target: '_blank', rel: 'noopener noreferrer' }
          : { to: route },
    }
  })
  .filter((banner) => isBannerRenderable(banner, banner.route)))
</script>
