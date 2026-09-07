<template>
  <section v-if="items.length" id="banners" class="mx-auto max-w-6xl px-6 py-16">
    <ul
      v-gsap.whenVisible.once.from.stagger="{ opacity: 0, y: 32, duration: 0.6 }"
      class="flex snap-x snap-mandatory gap-4 overflow-x-auto pb-2 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
    >
      <li
        v-for="banner in items"
        :key="banner.id"
        class="w-[85%] shrink-0 snap-start sm:w-[55%] lg:w-[40%]"
      >
        <!-- Three shapes, one card: an in-app link, an external anchor that opens in a new
             tab, and a plain box for a `none` banner, which is decoration and takes no tap. -->
        <component
          :is="banner.tag"
          v-bind="banner.attrs"
          class="group relative block aspect-[16/9] overflow-hidden rounded-3xl bg-brand-mist"
        >
          <AppImage
            v-if="banner.image?.image_api"
            :src="banner.image"
            :alt="banner.title"
            class="size-full object-cover transition-transform duration-700 group-hover:scale-105"
          />

          <div class="absolute inset-0 flex flex-col justify-end gap-1 bg-gradient-to-t from-brand-ink/70 via-brand-ink/20 to-transparent p-5 text-white">
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

const { banners } = useHome()
const { pages } = usePages()

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
          ? { href: route, target: '_blank', rel: 'noopener' }
          : { to: route },
    }
  })
  .filter((banner) => isBannerRenderable(banner, banner.route)))
</script>
