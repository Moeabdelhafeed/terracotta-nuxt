<template>
  <!--
    The two screens ride in from beyond the section's edges as it scrolls past — no pin, so
    the page never stops moving under the reader.

    Motion note: the off-canvas start is set by GSAP, never as SSR CSS. With no JS — a
    crawler, a script error — the phones simply sit at the edges where the layout puts
    them, which is a perfectly good static composition.
  -->
  <section
    ref="root"
    id="get-app"
    class="relative isolate flex min-h-[80svh] flex-col items-center justify-center overflow-hidden bg-brand-mist/40 py-16 2xl:flex-row 2xl:py-0"
  >
    <div
      class="relative z-10 mx-auto flex max-w-6xl flex-col items-center px-6 text-center 2xl:-mt-20 2xl:pt-[10svh]"
    >
      <!-- AppMedia, not AppImage: `mediaAsset` hands back the `{ type, image }` wrapper
           (or the /public fallback path), which only AppMedia unwraps. -->
      <AppMedia
        v-if="logo"
        :src="logo"
        alt=""
        class="h-16 w-auto object-contain sm:h-20"
      />

      <p class="mt-6 text-xs uppercase tracking-[0.25em] text-brand-terracotta/70">
        {{ t("app_eyebrow", "The app", "التطبيق") }}
      </p>

      <h2
        class="mt-5 max-w-2xl font-display text-3xl font-semibold leading-tight sm:text-5xl"
      >
        {{
          t(
            "app_title",
            "Terracotta, on iOS and Android",
            "تيراكوتا، على iOS و Android",
          )
        }}
      </h2>

      <p
        class="mt-5 max-w-xl text-base leading-relaxed text-muted-foreground sm:text-lg"
      >
        {{
          t(
            "app_subtitle",
            "Book a workshop, order a piece and follow it to your door — all from your phone.",
            "احجز ورشة، اطلب قطعة، وتابعها حتى باب بيتك — كل ذلك من هاتفك.",
          )
        }}
      </p>

      <ul
        v-if="badges.length"
        class="mt-7 flex flex-wrap items-center justify-center gap-4"
      >
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
              >{{ badge.text }}</span
            >
          </a>
        </li>
      </ul>
    </div>

    <!--
      Two compositions. From `2xl` (1536px) the screens stand at either edge of the section
      with the copy between them — sized off the window's WIDTH as well as its height
      (`min(70svh, 34vw)`, 3vw in from the edge), so however tall the window is they stop
      short of the text. Below that they are a pair in the flow under the copy, leaning
      apart and scaled to the space.

      It used to switch at `sm` (640px) with the screens 120px in and 70% of the window
      tall: on every tablet and laptop that put them behind the heading, the words over
      the screenshots and the store buttons on top of both (QA WEB-01). `2xl:contents`
      drops this wrapper out of the layout for the side-by-side placement.
    -->
    <div class="mt-12 flex items-end justify-center 2xl:contents">
      <img
        ref="phoneStart"
        :src="screenOne"
        alt=""
        aria-hidden="true"
        class="pointer-events-none -me-6 h-[36svh] w-auto -rotate-6 drop-shadow-2xl md:h-[44svh] 2xl:absolute 2xl:right-[3vw] 2xl:-z-10 2xl:me-0 2xl:-mt-20 2xl:h-[min(70svh,34vw)] 2xl:rotate-0"
      />
      <img
        ref="phoneEnd"
        :src="screenTwo"
        alt=""
        aria-hidden="true"
        class="pointer-events-none -ms-6 h-[36svh] w-auto rotate-6 drop-shadow-2xl md:h-[44svh] 2xl:absolute 2xl:left-[3vw] 2xl:-z-10 2xl:ms-0 2xl:-mt-20 2xl:h-[min(70svh,34vw)] 2xl:rotate-0"
      />
    </div>
  </section>
</template>

<script setup>
import { ScrollSmoother, ScrollTrigger } from "gsap/all";

/**
 * The app pitch, between the gallery and the visit band: this build is for browsing, so
 * the page says once, plainly, where the booking and buying actually happen.
 */
const { t } = useLang("web", "home");
const { appStore, googlePlay, appGallery } = useAppSettings();
const { mediaAsset } = useMedia("web", "branding");
const { media: appMedia } = useMedia("web", "app");

/**
 * The two app screens, from dynamic storage so they are swapped from the admin when the
 * app's design moves on. `media()` rather than `mediaAsset()`: these are plain `<img>`
 * elements GSAP animates directly, so they need a URL, not the `{ type, image }` wrapper.
 * The /public files are the seed — first render uploads them and creates the keys.
 */
const screenOne = computed(() => appMedia("app_screen_1", "/app-screen-1.png"));
const screenTwo = computed(() => appMedia("app_screen_2", "/app-screen-2.png"));

// The terracotta mark, since this band is light.
const logo = computed(() => mediaAsset("logo_mark", "/logo-mark.png"));

const badges = computed(() => [
  ...appStore.value.map((item) => ({ ...item, block: "app_store" })),
  ...googlePlay.value.map((item) => ({ ...item, block: "google_play" })),
  ...appGallery.value.map((item) => ({ ...item, block: "app_gallery" })),
]);

const root = ref(null);
const phoneStart = ref(null);
const phoneEnd = ref(null);

let mm = null;

onMounted(async () => {
  // ScrollSmoother is created by the layout, whose onMounted runs *after* this one, and a
  // trigger built before it exists measures against the window instead of the smoothed
  // content.
  await new Promise((resolve) => {
    let frames = 30;
    const check = () =>
      ScrollSmoother.get() || frames-- <= 0
        ? resolve()
        : requestAnimationFrame(check);
    check();
  });

  const gsap = useGSAP();
  gsap.registerPlugin(ScrollTrigger);
  mm = gsap.matchMedia();

  mm.add("(prefers-reduced-motion: no-preference)", () => {
    const tl = gsap.timeline({
      scrollTrigger: {
        trigger: root.value,
        // A thousand pixels before the section's top reaches the top of the screen: the
        // screens are already travelling while the band is still below the fold, and are
        // settled by the time it arrives.
        start: "top-=1000 top",
        end: "top top",
        scrub: 0.8,
      },
    });

    // Each starts a full width beyond its own edge — `xPercent` rather than pixels, so it
    // holds at any screen size — and rides in to where the layout already places it.
    tl.from(phoneStart.value, { xPercent: 120, ease: "none" }, 0).from(
      phoneEnd.value,
      { xPercent: -120, ease: "none" },
      0,
    );

    return () => tl.scrollTrigger?.kill();
  });
});

onBeforeUnmount(() => {
  mm?.revert();
  mm = null;
});
</script>
