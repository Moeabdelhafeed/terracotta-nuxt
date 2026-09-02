<template>
  <div v-if="hero" >
    <div ref="wrapper" class=" w-full h-full">
      <div ref="last" class="bg-brand-terracotta overflow-hidden w-full h-full absolute z-10">
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
        <div class="mx-auto flex h-full max-w-6xl items-center px-6 py-12 sm:py-16">
          <div class="grid w-full items-center gap-6 sm:gap-10 lg:grid-cols-2 lg:gap-16">
            <!-- What the material actually is: the panel earns its full screen by
                 explaining the name rather than repeating the pitch. -->
            <div class="flex flex-col gap-5 text-white">
              <h2 class="font-display text-3xl font-semibold leading-tight sm:text-4xl lg:text-5xl">
                {{ t('about_title', 'What is terracotta?', 'ما هي التيراكوتا؟') }}
              </h2>

              <p class="max-w-xl text-sm leading-relaxed text-white/85 sm:text-base lg:text-lg">
                {{ t('about_body_1', 'Terracotta is baked earth — iron-rich clay shaped by hand and fired until it holds its form for good. The iron is what gives it that warm red-brown colour, with no glaze or pigment involved.', 'التيراكوتا هي الطين المشوي — طين غني بالحديد يُشكّل باليد ويُحرق حتى يثبت شكله للأبد. الحديد هو ما يمنحه لونه البني المائل للحمرة، دون أي طلاء أو صبغة.') }}
              </p>

              <p class="hidden max-w-xl text-sm leading-relaxed text-white/70 sm:block sm:text-base lg:text-lg">
                {{ t('about_body_2', 'It is one of the oldest materials people have worked with, and it still behaves the same way: soft enough to take a thumbprint, permanent once it leaves the kiln.', 'إنها من أقدم المواد التي عمل بها الإنسان، وما زالت تتصرف بالطريقة ذاتها: طريّة بما يكفي لتحتفظ ببصمة إبهامك، ودائمة بمجرد خروجها من الفرن.') }}
              </p>
            </div>

            <!-- Studio photographs, held in dynamic storage (group `web`, sub-group
                 `studio`, keys studio_1…4) so they are swapped from the CMS, not a deploy.
                 A key with nothing uploaded drops out rather than leaving a hole. -->
            <ul  ref="img_list" v-if="studioTiles.length" class="grid grid-cols-2 gap-4 sm:gap-6">
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
                  :alt="t('about_title', 'What is terracotta?', 'ما هي التيراكوتا؟')"
                  class="w-full object-cover"
                  :class="TALL_TILES.includes(index) ? 'aspect-[3/4]' : 'aspect-square'"
                />
              </li>
            </ul>
          </div>
        </div>
      </div>
      
      <!-- The mark comes from dynamic storage (group `web`, sub-group `branding`, key
           `logo_mark`), so it is swapped from the CMS. The /public file is the fallback
           and is uploaded automatically the first time the key is missing. -->
      <AppMedia
        ref="logo"
        :src="logoMark"
        alt=""
        class="absolute top-0 inset-x-0 mx-auto w-auto object-contain"
      />

      <!-- Inline, not an <img>: DrawSVG animates the path's stroke, which only exists as
           a real node in the document. Sits beside the logo, so the scaling section (and
           its video) paints over it and it is revealed as the section shrinks. -->
      <svg
        class="absolute inset-0 h-full w-full text-brand-terracotta"
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
     

    <div  ref= "section" class="w-full overflow-hidden h-svh bg-background">


  <AppMedia
          v-if="heroVideoAsset"
          :src="heroVideoAsset"
          :alt="hero.title"
          :controls="false"
          autoplay
          loop
          muted
          playsinline
          preload="metadata"
          class=" h-full w-full absolute object-cover"
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
        <AppImage
          v-else-if="hero.image?.image_api"
          :src="hero.image"
          :alt="hero.title"
          class="h-full w-full absolute object-cover"
        />

        <!-- Centred over the film, static. -->
        <div
          class="pointer-events-none absolute inset-0 z-10 flex flex-col items-center justify-center gap-4 px-6 text-center"
        >
          <h1 class="font-display text-4xl font-semibold text-white drop-shadow-lg sm:text-6xl lg:text-7xl">
            {{ hero.title }}
          </h1>
          <p v-if="hero.label" class="max-w-xl text-lg text-white/85 drop-shadow">
            {{ hero.label }}
          </p>
        </div>

    </div>

       </div>
  </div>
</template>

<script setup>
import { Section } from 'lucide-vue-next'
import { DrawSVGPlugin } from 'gsap/all'

const { banners } = useHome()
await useApiFetch('/api/media', { key: 'media-web', query: { group: 'web' } })
const { mediaAsset } = useMedia('web', 'home')
const { mediaAsset: brandAsset } = useMedia('web', 'branding')

const logoMark = computed(() => brandAsset('logo_mark', '/logo-mark.png'))
const { t } = useLang('web', 'home')

const img_list = ref()
const wrapper = ref()
const section = ref()
const logo = ref()
const line = ref()
const heart = ref()
const last = ref()
const vector17 = ref()

const SCALE = 0.8

onMounted(async () => {

  await nextTick()
  const gsap = useGSAP()
  // Not among the plugins v-gsap pre-registers, so it has to be added here.
  gsap.registerPlugin(DrawSVGPlugin)

  const tl = gsap.timeline({
    scrollTrigger:{
      trigger: wrapper.value,
      start: 'top top',
      end: '+=2000',
      scrub:true,
      pin:true
    }
  })

  // Scaling from the centre opens an equal strip above and below the section:
  // height x (1 - scale) / 2. The logo is set once to that final strip height.
  gsap.set(logo.value?.$el ?? logo.value, {top: ((section.value.offsetHeight * (1 - 0.8)) / 2 - ((section.value.offsetHeight * (1 - 0.87)) / 2 ))/2, height: (section.value.offsetHeight * (1 - 0.87)) / 2 })

  tl.to(section.value, {
    borderRadius: 0,
    scale: SCALE,
  })

  // Drawn across the same scrub as the scale, starting at 0 so both finish together.
  tl.from(line.value, {
    drawSVG: '0%',
    ease: 'none',
  })

  tl.from(last.value,{
    y: '100%'
  })

  // The grid sits behind `v-if="studioTiles.length"`, so with no media uploaded the <ul>
  // never renders and this ref is undefined. Guarded rather than assumed.
  const tiles = img_list.value?.querySelectorAll('li')

  if (tiles?.length) {
    tl.from(tiles, {
      y: (i) => (i % 2 === 0 ? 200 : -200),
    }, '<')
  }
 

  
})

const hero = computed(() => banners.value[0] ?? null)
// Three is enough to read as a set; the covers are already Image objects.
const STUDIO_KEYS = ['studio_1', 'studio_2', 'studio_3', 'studio_4']

// Top-left and bottom-right: the two that overhang the grid.
const TALL_TILES = [0, 3]

// Each key carries the /public file it seeds itself from, so a backend with nothing
// uploaded fills in on the first render instead of dropping the grid.
const studioTiles = computed(() =>
  STUDIO_KEYS
    .map((key, index) => ({
      key,
      asset: mediaAsset(key, `/seed/studio-${index + 1}.webp`, { subGroup: 'studio' }),
    }))
    .filter((tile) => tile.asset),
)


const rest = computed(() => banners.value.slice(1, 6))


/**
 * The uploaded video, or the /public file it seeds itself from. `mediaAsset` hands back a
 * `{ type: 'video', video }` wrapper once the key exists and a plain path until then —
 * only the wrapper goes to AppMedia, so the path is kept separately for a bare <video>.
 * Without this the hero showed no video at all on a backend with nothing uploaded.
 */
const heroVideoAsset = computed(() => {
  const asset = mediaAsset('hero_video', '/seed/hero-video.mp4')
  return asset?.type === 'video' && asset.video?.video_api ? asset : null
})

const heroVideoFile = computed(() => {
  const asset = mediaAsset('hero_video', '/seed/hero-video.mp4')
  return typeof asset === 'string' ? asset : null
})
</script>

