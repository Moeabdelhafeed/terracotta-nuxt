<template>
  <!--
    The two screens ride in from beyond the section's edges as it scrolls past — no pin, so
    the page never stops moving under the reader.

    Motion note: the off-canvas start is set by GSAP, never as SSR CSS. With no JS — a
    crawler, a script error — the phones simply sit at the edges where the layout puts
    them, which is a perfectly good static composition.
  -->
  <section ref="root" id="get-app" class="relative flex items-center isolate h-[80svh] overflow-hidden bg-brand-mist/40">
    <div class="relative -mt-20  z-10 mx-auto flex max-w-6xl flex-col items-center px-6 pt-[10svh] text-center">
      <!-- AppMedia, not AppImage: `mediaAsset` hands back the `{ type, image }` wrapper
           (or the /public fallback path), which only AppMedia unwraps. -->
      <AppMedia v-if="logo" :src="logo" alt="" class="h-16 w-auto object-contain sm:h-20" />

      <p class="mt-6 text-xs uppercase tracking-[0.25em] text-brand-rust/70">
        {{ t('app_eyebrow', 'The app', 'التطبيق') }}
      </p>

      <h2 class="mt-5 max-w-2xl font-display text-3xl font-semibold leading-tight sm:text-5xl">
        {{ t('app_title', 'Terracotta, on iOS and Android', 'تيراكوتا، على iOS و Android') }}
      </h2>

      <p class="mt-5 max-w-xl text-base leading-relaxed text-muted-foreground sm:text-lg">
        {{ t('app_subtitle', 'Book a workshop, order a piece and follow it to your door — all from your phone.', 'احجز ورشة، اطلب قطعة، وتابعها حتى باب بيتك — كل ذلك من هاتفك.') }}
      </p>

      <ul v-if="badges.length" class="mt-7 flex flex-wrap items-center justify-center gap-4">
        <li v-for="badge in badges" :key="`${badge.block}-${badge.id}`">
          <a
            :href="badge.url"
            target="_blank"
            rel="noopener noreferrer"
            :title="badge.text"
            class="block transition-transform hover:-translate-y-1"
          >
            <AppImage
              v-if="badge.image?.image_api"
              :src="badge.image"
              :alt="badge.text"
              class="h-12 w-auto object-contain sm:h-14"
            />
            <span
              v-else
              class="inline-flex h-12 items-center rounded-2xl border bg-card px-6 font-medium sm:h-14"
            >{{ badge.text }}</span>
          </a>
        </li>
      </ul>
    </div>

    <!-- The screens sit under the copy in the stack, so the text stays readable where the
         two overlap at the start of the scroll. -->
    <img
      ref="phoneStart"
      :src="screenOne"
      alt=""
      aria-hidden="true"
      class="pointer-events-none -mt-20 absolute right-30  -z-10 h-[48svh] w-auto  drop-shadow-2xl sm:h-[70svh] "
    >
    <img
      ref="phoneEnd"
      :src="screenTwo"
      alt=""
      aria-hidden="true"
      class="pointer-events-none -mt-20 absolute  left-30 -z-10 h-[48svh] w-auto   drop-shadow-2xl sm:h-[70svh] "
    >
  </section>
</template>

<script setup>
import { ScrollSmoother, ScrollTrigger } from 'gsap/all'

/**
 * The app pitch, between the gallery and the visit band: this build is for browsing, so
 * the page says once, plainly, where the booking and buying actually happen.
 */
const { t } = useLang('web', 'home')
const { appStore, googlePlay, appGallery } = useAppSettings()
const { mediaAsset } = useMedia('web', 'branding')
const { media: appMedia } = useMedia('web', 'app')

/**
 * The two app screens, from dynamic storage so they are swapped from the admin when the
 * app's design moves on. `media()` rather than `mediaAsset()`: these are plain `<img>`
 * elements GSAP animates directly, so they need a URL, not the `{ type, image }` wrapper.
 * The /public files are the seed — first render uploads them and creates the keys.
 */
const screenOne = computed(() => appMedia('app_screen_1', '/app-screen-1.png'))
const screenTwo = computed(() => appMedia('app_screen_2', '/app-screen-2.png'))

// The terracotta mark, since this band is light.
const logo = computed(() => mediaAsset('logo_mark', '/logo-mark.png'))

const badges = computed(() => [
  ...appStore.value.map((item) => ({ ...item, block: 'app_store' })),
  ...googlePlay.value.map((item) => ({ ...item, block: 'google_play' })),
  ...appGallery.value.map((item) => ({ ...item, block: 'app_gallery' })),
])

const root = ref(null)
const phoneStart = ref(null)
const phoneEnd = ref(null)

let mm = null

onMounted(async () => {
  // ScrollSmoother is created by the layout, whose onMounted runs *after* this one, and a
  // trigger built before it exists measures against the window instead of the smoothed
  // content.
  await new Promise((resolve) => {
    let frames = 30
    const check = () => (ScrollSmoother.get() || frames-- <= 0 ? resolve() : requestAnimationFrame(check))
    check()
  })

  const gsap = useGSAP()
  gsap.registerPlugin(ScrollTrigger)
  mm = gsap.matchMedia()

  mm.add('(prefers-reduced-motion: no-preference)', () => {
    const tl = gsap.timeline({
      scrollTrigger: {
        trigger: root.value,
        // A thousand pixels before the section's top reaches the top of the screen: the
        // screens are already travelling while the band is still below the fold, and are
        // settled by the time it arrives.
        start: 'top-=1000 top',
        end: 'top top',
        scrub: 0.8,
      },
    })

    // Each starts a full width beyond its own edge — `xPercent` rather than pixels, so it
    // holds at any screen size — and rides in to where the layout already places it.
    tl.from(phoneStart.value, { xPercent: 120, ease: 'none' }, 0)
      .from(phoneEnd.value, { xPercent: -120, ease: 'none' }, 0)

    return () => tl.scrollTrigger?.kill()
  })
})

onBeforeUnmount(() => {
  mm?.revert()
  mm = null
})
</script>
