<template>
  <!-- Nothing here comes from a banner any more. Banners are the app's carousel and this
       is the website's front door: its words are translation keys, its film and its studio
       tiles are media keys, and each seeds itself. The hero used to read `banners[0]`,
       which meant an install with no active banner had no hero at all — and the copy the
       site actually shows could only be edited by editing an app banner. -->
  <div>
    <!-- Two layouts, one markup. On desktop the brown panel lies over the film and is
         revealed as a pinned scrub shrinks it; on a phone there is no scrub, so the two
         are simply stacked — film first, brown panel underneath it — and read by
         scrolling. Left overlapping with the scrub switched off, the panel sat on top of
         the film and the hero was never seen at all. -->
    <!-- The layout switch is CSS, not `motion`: `lg:motion-safe:` is the same rule as
         `pageMotionEnabled()` (1024px up, reduced motion off), and a media query applies
         to the server's HTML as sent, where the window does not exist. Picking them in script
         rendered the phone layout on the server, and a class mismatch is never repaired
         on hydration — so a desktop that loaded the home page ran the pinned scrub over
         the stacked phone layout, and the brown panel jumped around under it. -->
    <div
      ref="wrapper"
      class="flex flex-col lg:motion-safe:block lg:motion-safe:h-full lg:motion-safe:w-full"
    >
      <div
        ref="last"
        class="relative order-2 w-full overflow-hidden bg-brand-terracotta lg:motion-safe:absolute lg:motion-safe:z-10 lg:motion-safe:order-none lg:motion-safe:h-full"
      >
        <!-- Vector 17, inline so the stroke can be coloured (and drawn) from here.
             Decorative background only. -->
        <svg
          ref="vector17"
          class="pointer-events-none absolute inset-0 h-full w-full text-white/30"
          viewBox="0 0 1652 922"
          fill="none"
          preserveAspectRatio="xMidYMid slice"
          aria-hidden="true"
        >
          <path
            d="M1307 -56C1253.17 68 1264.5 312.2 1740.5 297C2335.5 278 903 1173 427 1083.5C-48.9998 994 -184.5 -34 102 -45C388.5 -56 399 853.5 131.5 1055.5"
            stroke="currentColor"
            stroke-width="2"
            vector-effect="non-scaling-stroke"
          />
        </svg>
        <!--
          `overflow-hidden`, never `auto`. This panel lives inside the PINNED section, so
          a scrollbar here is one the reader cannot use: every wheel and every touch drives
          the pinned timeline instead, and the bar sits there advertising a scroll that
          does nothing. The copy is sized to fit the panel instead — see the padding, which
          is tight on a phone for exactly that reason.
        -->
        <div
          class="mx-auto flex min-h-dvh max-w-6xl items-center-safe overflow-hidden px-6 py-6 sm:py-16 lg:motion-safe:h-full lg:motion-safe:min-h-0"
        >
          <div
            class="grid w-full items-center gap-6 sm:gap-10 lg:grid-cols-2 lg:gap-16"
          >
            <!-- What the material actually is: the panel earns its full screen by
                 explaining the name rather than repeating the pitch. -->
            <div class="flex flex-col gap-5 text-white">
              <h2
                class="font-display text-3xl font-semibold leading-tight sm:text-4xl lg:text-5xl"
              >
                {{
                  t("about_title", "What is terracotta?", "ما هي التيراكوتا؟")
                }}
              </h2>

              <p
                class="max-w-xl text-sm leading-relaxed text-white/85 sm:text-base lg:text-lg"
              >
                {{
                  t(
                    "about_body_1",
                    "Terracotta is baked earth — iron-rich clay shaped by hand and fired until it holds its form for good. The iron is what gives it that warm red-brown colour, with no glaze or pigment involved.",
                    "التيراكوتا هي الطين المشوي — طين غني بالحديد يُشكّل باليد ويُحرق حتى يثبت شكله للأبد. الحديد هو ما يمنحه لونه البني المائل للحمرة، دون أي طلاء أو صبغة.",
                  )
                }}
              </p>

              <p
                class="hidden max-w-xl text-sm leading-relaxed text-white/70 sm:block sm:text-base lg:text-lg"
              >
                {{
                  t(
                    "about_body_2",
                    "It is one of the oldest materials people have worked with, and it still behaves the same way: soft enough to take a thumbprint, permanent once it leaves the kiln.",
                    "إنها من أقدم المواد التي عمل بها الإنسان، وما زالت تتصرف بالطريقة ذاتها: طريّة بما يكفي لتحتفظ ببصمة إبهامك، ودائمة بمجرد خروجها من الفرن.",
                  )
                }}
              </p>

              <!-- The panel explains the material; the page that explains the studio is a
                   tap away rather than only reachable from the bar. `self-start` so the
                   button is its own width, not the column's. -->
              <NuxtLink
                to="/about"
                class="mt-1 inline-flex items-center gap-2 self-start rounded-control bg-white/95 px-6 py-3 text-sm font-semibold text-brand-ink transition-colors hover:bg-white sm:text-base"
              >
                {{ t("about_more", "About Terracotta", "عن تيراكوتا") }}
                <LucideArrowRight class="size-4 rtl:-scale-x-100" />
              </NuxtLink>
            </div>

            <!-- Studio photographs, held in dynamic storage (group `web`, sub-group
                 `studio`, keys studio_1…4) so they are swapped from the CMS, not a deploy.
                 A key with nothing uploaded drops out rather than leaving a hole. -->
            <ul
              ref="img_list"
              v-if="studioTiles.length"
              class="grid grid-cols-2 gap-4 sm:gap-6"
            >
              <li
                v-for="(tile, index) in studioTiles"
                :key="tile.key"
                class="overflow-hidden"
                :class="index < 2 ? 'self-end' : 'self-start'"
              >
                <!-- The taller tiles overhang outward while the shared edges stay on the
                     grid line: the top row is bottom-aligned, so tile 1 grows upward, and
                     the bottom row is top-aligned, so tile 4 grows downward. The gap
                     between the two rows stays exactly `gap-6` either way. -->
                <AppMedia
                  :src="tile.asset"
                  :alt="
                    t('about_title', 'What is terracotta?', 'ما هي التيراكوتا؟')
                  "
                  class="w-full object-cover"
                  :class="
                    TALL_TILES.includes(index)
                      ? 'aspect-[3/4]'
                      : 'aspect-square'
                  "
                />
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- The mark comes from dynamic storage (group `web`, sub-group `branding`, key
           `logo_mark`), so it is swapped from the CMS. The /public file is the fallback
           and is uploaded automatically the first time the key is missing. -->
      <!-- Desktop only: GSAP sizes and places this one into the strip the shrinking film
           opens up. On a phone it is rendered inside the film section instead, where it
           belongs without a scrub to reveal it. -->
      <!-- The link adds no box of its own: the mark stays absolute against the hero, where
           GSAP places it. On the home page it is a same-page link, so it scrolls back up. -->
      <NuxtLink
        to="/"
        class="hidden lg:motion-safe:inline"
        :aria-label="t('nav_home', 'Home', 'الرئيسية')"
      >
        <AppMedia
          ref="logo"
          :src="logoMark"
          alt=""
          class="absolute top-0 inset-x-0 mx-auto w-auto object-contain"
        />
      </NuxtLink>

      <!-- Inline, not an <img>: DrawSVG animates the path's stroke, which only exists as
           a real node in the document. Sits beside the logo, so the scaling section (and
           its video) paints over it and it is revealed as the section shrinks. -->
      <!-- Drawn by the scrub as the film shrinks. With no scrub there is nothing to
           reveal them against, and they would sit over the film as stray strokes. -->
      <svg
        class="pointer-events-none absolute inset-0 hidden h-full w-full text-brand-terracotta lg:motion-safe:block"
        viewBox="0 0 1601 922"
        fill="none"
        preserveAspectRatio="xMidYMid slice"
        aria-hidden="true"
      >
        <path
          ref="line"
          d="M533.499 -308.5C561.499 -140.5 487.899 246.8 -30.5009 452C-678.501 708.5 240.999 -304.5 884.499 -146.5C1528 11.5 1738 466.5 1512 1153.5C1286 1840.5 349.5 489.5 -89.5 497.5"
          stroke="currentColor"
          stroke-width="2"
          vector-effect="non-scaling-stroke"
        />

        <!-- Heart drawn in a 0-100 box and placed with a transform, so the shape stays
             readable instead of being hand-fitted to the 1601x922 viewBox. -->
        <path
          ref="heart"
          d="M50 88 C 20 65, 0 45, 0 28 C 0 12, 12 0, 26 0 C 36 0, 45 6, 50 14 C 55 6, 64 0, 74 0 C 88 0, 100 12, 100 28 C 100 45, 80 65, 50 88 Z"
          transform="translate(660 300) scale(2.8)"
          stroke="currentColor"
          stroke-width="2"
          vector-effect="non-scaling-stroke"
        />
      </svg>

      <!--
        `dvh`: the box the reader can actually see, at whatever size the phone's toolbar
        currently leaves it. `lvh` is taller than that while the toolbar is out — which is
        the whole time at the top of the page — so the video was sized against a box bigger
        than the screen and never squared up on scroll.

        It was `svh` because `dvh` moves under a pin ScrollTrigger has already measured.
        That is handled rather than avoided now: the trigger invalidates on refresh and
        `sizeLogo` re-derives the strip from the height the section has at that moment, so
        a toolbar sliding away resizes the hero instead of leaving a band of background
        under it.
      -->
      <div
        ref="section"
        class="relative order-1 h-dvh w-full overflow-hidden bg-background lg:motion-safe:static lg:motion-safe:order-none"
      >
        <AppMedia
          v-if="heroVideoAsset"
          :src="heroVideoAsset"
          :alt="t('home_hero_title', 'Terracotta', 'تيراكوتا')"
          :controls="false"
          autoplay
          loop
          muted
          playsinline
          preload="metadata"
          class="h-full w-full absolute object-cover"
        />
        <video
          v-else-if="heroVideoFile"
          :src="heroVideoFile"
          autoplay
          loop
          muted
          playsinline
          preload="metadata"
          class="absolute h-full w-full object-cover"
        />
        <!-- The same scrim the inner pages carry: the film is whatever the studio uploaded,
             and a bright frame leaves the title unreadable. Below the copy's own z-10. -->
        <div class="pointer-events-none absolute inset-0 bg-black/40" aria-hidden="true" />

        <!-- The mark, white, across the top of the film — the phone's version of the strip
             the desktop scrub opens. -->
        <NuxtLink
          to="/"
          class="absolute inset-x-0 top-8 z-20 mx-auto h-12 w-fit lg:motion-safe:hidden"
          :aria-label="t('nav_home', 'Home', 'الرئيسية')"
        >
          <AppMedia :src="logoLight" alt="" class="h-full w-auto object-contain" />
        </NuxtLink>

        <!--
          Centred over the film, static.

          The words are translation keys, not the first banner's `title`/`label`. Banners
          are the app's carousel: an entry made for a phone screen was being read as this
          site's headline, so editing the site's own copy in Translations changed nothing
          and editing the hero meant editing an app banner. `home_hero_title` and
          `home_hero_subtitle` seed themselves like every other string here.
        -->
        <div
          class="pointer-events-none absolute inset-0 z-10 flex flex-col items-center justify-center gap-4 px-6 text-center"
        >
          <h1
            class="font-display text-4xl font-semibold text-white drop-shadow-lg sm:text-6xl lg:text-7xl"
          >
            {{ t("home_hero_title", "Terracotta", "تيراكوتا") }}
          </h1>
          <p class="max-w-xl text-lg text-white/85 drop-shadow">
            {{ t("home_hero_subtitle", "Handmade in Amman", "مصنوع يدويًا في عمّان") }}
          </p>

          <!-- The overlay itself ignores the pointer so the film underneath keeps its own
               hover; only the call to action takes a tap. It leads to the workshops, the
               studio's own offer — the banner's `link_type` decided this before, which is
               the app's routing, not this site's. -->
          <NuxtLink
            to="/workshops"
            class="pointer-events-auto rounded-xl bg-white/95 px-6 py-2.5 text-sm font-semibold text-brand-ink transition-colors hover:bg-white"
          >
            {{ t("home_hero_cta", "Book a workshop", "احجز ورشة") }}
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Section } from "lucide-vue-next";
import { DrawSVGPlugin } from "gsap/all";

await useApiFetch("/api/media", { key: "media-web", query: { group: "web" } });
const { mediaAsset } = useMedia("web", "home");
const { mediaAsset: brandAsset } = useMedia("web", "branding");

const logoMark = computed(() => brandAsset("logo_mark", "/logo-mark.png"));

// The white wordmark, for the phone's film: the coloured mark is drawn for the pale strip
// the desktop scrub opens, and over a photograph it disappears into it. Same
// `logo_light` key the footer, the page bar and the curtain already use.
const logoLight = computed(() => brandAsset("logo_light", "/logo-light.png"));
const { t } = useLang("web", "home");

const img_list = ref();
const wrapper = ref();
const section = ref();
const logo = ref();
const line = ref();
const heart = ref();
const last = ref();
const vector17 = ref();

// Desktop gets the pinned scrub; a phone gets the two sections stacked. The layout is the
// template's `lg:motion-safe:` classes, the same rule this reads, so the timeline only
// ever runs over the layout it was written for.
const motion = pageMotionEnabled();

const SCALE = 0.8;

onMounted(async () => {
  await nextTick();

  // No pinned scrub on a phone — the film and the panel are two stacked sections there,
  // so there is nothing to pin and nothing to reveal. See the template and
  // `pageMotionEnabled()`.
  if (!motion) return;

  const gsap = useGSAP();
  // Not among the plugins v-gsap pre-registers, so it has to be added here.
  gsap.registerPlugin(DrawSVGPlugin);

  // Scaling from the centre opens an equal strip above and below the section:
  // height x (1 - scale) / 2. The logo is sized to that strip — and re-sized on every
  // refresh, because the section is `dvh`: the strip is a fraction of a height that
  // changes as the phone's toolbar comes and goes.
  const sizeLogo = () => {
    const height = section.value?.offsetHeight ?? 0;

    gsap.set(logo.value?.$el ?? logo.value, {
      top: ((height * (1 - 0.8)) / 2 - (height * (1 - 0.87)) / 2) / 2,
      height: (height * (1 - 0.87)) / 2,
    });
  };

  const tl = gsap.timeline({
    scrollTrigger: {
      trigger: wrapper.value,
      start: "top top",
      end: "+=2000",
      scrub: true,
      pin: true,
      // The pinned spacer is measured once; `dvh` is not a once. Both are re-taken
      // together whenever ScrollTrigger refreshes.
      invalidateOnRefresh: true,
      onRefresh: sizeLogo,
    },
  });

  sizeLogo();

  tl.to(section.value, {
    borderRadius: 0,
    scale: SCALE,
  });

  // Drawn across the same scrub as the scale, starting at 0 so both finish together.
  tl.from(line.value, {
    drawSVG: "0%",
    ease: "none",
  });

  tl.from(last.value, {
    y: "100%",
  });

  // The grid sits behind `v-if="studioTiles.length"`, so with no media uploaded the <ul>
  // never renders and this ref is undefined. Guarded rather than assumed.
  const tiles = img_list.value?.querySelectorAll("li");

  if (tiles?.length) {
    tl.from(
      tiles,
      {
        y: (i) => (i % 2 === 0 ? 200 : -200),
      },
      "<",
    );
  }
});

// Three is enough to read as a set; the covers are already Image objects.
const STUDIO_KEYS = ["studio_1", "studio_2", "studio_3", "studio_4"];

// Top-left and bottom-right: the two that overhang the grid.
const TALL_TILES = [0, 3];

// Each key carries the /public file it seeds itself from, so a backend with nothing
// uploaded fills in on the first render instead of dropping the grid.
const studioTiles = computed(() =>
  STUDIO_KEYS.map((key, index) => ({
    key,
    asset: mediaAsset(key, `/seed/studio-${index + 1}.webp`, {
      subGroup: "studio",
    }),
  })).filter((tile) => tile.asset),
);

/**
 * The uploaded video, or the /public file it seeds itself from. `mediaAsset` hands back a
 * `{ type: 'video', video }` wrapper once the key exists and a plain path until then —
 * only the wrapper goes to AppMedia, so the path is kept separately for a bare <video>.
 * Without this the hero showed no video at all on a backend with nothing uploaded.
 */
const heroVideoAsset = computed(() => {
  const asset = mediaAsset("hero_video", "/seed/hero-video.mp4");
  return asset?.type === "video" && asset.video?.video_api ? asset : null;
});

const heroVideoFile = computed(() => {
  const asset = mediaAsset("hero_video", "/seed/hero-video.mp4");
  return typeof asset === "string" ? asset : null;
});
</script>
