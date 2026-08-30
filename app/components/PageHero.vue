<template>
  <section class="overflow-hidden bg-background">
    <div class="flex w-full flex-col items-center pt-10">
      <!-- Sized exactly as the home hero's mark: there it fills the strip the scaled
           section opens up, height x (1 - 0.87) / 2, so 6.5% of the viewport. -->
      <AppMedia v-if="logo" :src="logo" alt="" class="h-[6.5svh] w-auto object-contain" />

      <!-- 90% of the viewport, not of a centred column: the picture is nearly full width,
           with just enough white ground left either side to frame it. The copy sits over
           it, as it does on the home page. -->
      <div v-if="image" class="relative mt-8 w-[90%] overflow-hidden">
        <AppMedia :src="image" :alt="title" class="aspect-[16/5] w-full object-cover sm:aspect-[21/6]" />

        <div class="absolute inset-0 flex flex-col items-center justify-center px-6 text-center text-white">
          <h1 class="max-w-2xl font-display text-3xl font-semibold drop-shadow-lg sm:text-5xl">{{ title }}</h1>
          <p v-if="subtitle" class="mt-3 max-w-xl text-sm text-white/85 drop-shadow sm:text-base">{{ subtitle }}</p>
        </div>
      </div>

      <!-- Without a picture the copy still needs somewhere to live. -->
      <div v-else class="mt-8 max-w-2xl px-6 text-center">
        <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ title }}</h1>
        <p v-if="subtitle" class="mt-3 text-muted-foreground">{{ subtitle }}</p>
      </div>
    </div>
  </section>
</template>
<script setup>
/**
 * The page header used across the inner pages: a white box carrying the mark at the top
 * and one picture below it, the copy sitting over the picture.
 *
 * Deliberately plain — no pinning, no scroll animation, and nothing taller than it needs
 * to be. The home page hero is the set piece; these are signposts.
 *
 * The picture comes from dynamic storage (group `web`, sub-group `heroes`) so it is a CMS
 * upload, with `fallback` covering the key not being filled in yet.
 */
const props = defineProps({
  /** Key inside the `heroes` sub-group, e.g. `hero_workshops`. */
  mediaKey: { type: String, required: true },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  /**
   * Stands in until the key is uploaded. A `/public` path is also used as the seed: the
   * key is created in the CMS with that file, exactly like a missing translation, so the
   * hero is replaceable from the admin instead of needing a deploy.
   */
  fallback: { type: [Object, String], default: '/herobg.png' },
})

const { mediaAsset: heroAsset } = useMedia('web', 'heroes')
const { mediaAsset: brandAsset } = useMedia('web', 'branding')

// The terracotta mark, since this box is white.
const logo = computed(() => brandAsset('logo_mark', '/logo-mark.png'))
const image = computed(() =>
  typeof props.fallback === 'string'
    ? heroAsset(props.mediaKey, props.fallback)
    : heroAsset(props.mediaKey) ?? props.fallback,
)
</script>
