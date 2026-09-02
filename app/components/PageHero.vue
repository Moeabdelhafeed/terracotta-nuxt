<template>
  <section class="overflow-hidden bg-background">
    <div class="flex w-full flex-col items-center pt-10">
      <!-- Sized exactly as the home hero's mark: there it fills the strip the scaled
           section opens up, height x (1 - 0.87) / 2, so 6.5% of the viewport. -->
      <AppMedia v-if="logo" :src="logo" alt="" class="h-[6.5svh] w-auto object-contain" />

      <!-- The trail sits on the white ground rather than over the picture, where it would
           compete with the title and lose contrast against a light photograph. -->
      <nav v-if="crumbs.length" class="mt-6 w-[90%]" :aria-label="t('breadcrumb', 'Breadcrumb', 'مسار التنقل')">
        <ol class="flex flex-wrap items-center text-sm text-muted-foreground">
          <li v-for="(crumb, index) in crumbs" :key="index" class="flex min-w-0 items-center">
            <NuxtLink
              v-if="crumb.to"
              :to="crumb.to"
              class="whitespace-nowrap underline-offset-4 transition-colors hover:text-foreground hover:underline"
            >{{ crumb.label }}</NuxtLink>
            <span v-else class="truncate font-medium text-foreground" aria-current="page">{{ crumb.label }}</span>

            <span v-if="index < crumbs.length - 1" class="px-2 text-muted-foreground/50" aria-hidden="true">/</span>
          </li>
        </ol>
      </nav>

      <!-- 90% of the viewport, not of a centred column: the picture is nearly full width,
           with just enough white ground left either side to frame it. The copy sits over
           it, as it does on the home page. -->
      <div v-if="image" class="relative mt-4 w-[90%] overflow-hidden">
        <!-- Dynamic storage hands back a `{ type, image|video|file }` wrapper, which only
             AppMedia unwraps; a record's own picture is a bare Image object, whose `type`
             is the file extension — AppMedia would read that as a file and render a link. -->
        <AppImage
          v-if="isBareImage"
          :src="image"
          :alt="title"
          class="aspect-[16/5] w-full object-cover sm:aspect-[21/6]"
        />
        <AppMedia v-else :src="image" :alt="title" class="aspect-[16/5] w-full object-cover sm:aspect-[21/6]" />

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
  /** Key inside the `heroes` sub-group, e.g. `hero_workshops`. Omit when passing `image`. */
  mediaKey: { type: String, default: '' },
  /**
   * A picture that belongs to the record being shown — a gallery album's cover, say —
   * rather than a CMS-managed page hero. Wins over `mediaKey` when both are given.
   */
  image: { type: [Object, String], default: null },
  /** `{ label, to? }` each; the last one is the current page, so it carries no link. */
  crumbs: { type: Array, default: () => [] },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  /**
   * Stands in until the key is uploaded. A `/public` path is also used as the seed: the
   * key is created in the CMS with that file, exactly like a missing translation, so the
   * hero is replaceable from the admin instead of needing a deploy.
   */
  fallback: { type: [Object, String], default: '' },
})

const { mediaAsset: heroAsset } = useMedia('web', 'heroes')
const { mediaAsset: brandAsset } = useMedia('web', 'branding')
const { t } = useLang('web', 'general')

// The terracotta mark, since this box is white.
const logo = computed(() => brandAsset('logo_mark', '/logo-mark.png'))

const image = computed(() => {
  if (props.image) return props.image
  if (!props.mediaKey) return null

  return typeof props.fallback === 'string'
    ? heroAsset(props.mediaKey, props.fallback)
    : heroAsset(props.mediaKey) ?? props.fallback
})

const isBareImage = computed(() => typeof image.value === 'string' || Boolean(image.value?.image_api))
</script>
