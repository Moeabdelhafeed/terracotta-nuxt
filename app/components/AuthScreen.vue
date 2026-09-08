<template>
  <!--
    The shared shell behind every auth screen: mark, heading, subtitle, then whatever the
    page needs below. Matches the mobile app's own auth screens — same mark, same line
    motif, same rust CTA — rather than the generic centred-card look these pages had.
  -->
  <div class="relative isolate flex min-h-svh flex-col overflow-hidden bg-background">
    <!-- The same line the home hero draws behind itself (Vector 17), not the one used
         everywhere else on the site — that one is the DrawSVG reveal, this is the
         passive background texture. The hero fits it into a wide landscape band, so
         "slice" only ever crops it a little; a narrow phone screen is tall and narrow
         enough that "slice" instead zooms into one thin vertical strip of the curve,
         and a loop's tip landing mid-screen reads as the line just stopping. Matching
         the box's aspect ratio to the viewBox keeps the whole curve proportional
         instead — "meet" then has nothing left to crop. -->
    <svg
      class="pointer-events-none absolute inset-x-0 top-0 -z-10 aspect-1652/922 w-full text-brand-mist"
      viewBox="0 0 1652 922"
      fill="none"
      preserveAspectRatio="xMidYMid meet"
      aria-hidden="true"
    >
      <path
        d="M1307 -56C1253.17 68 1264.5 312.2 1740.5 297C2335.5 278 903 1173 427 1083.5C-48.9998 994 -184.5 -34 102 -45C388.5 -56 399 853.5 131.5 1055.5"
        stroke="currentColor"
        stroke-width="2"
        vector-effect="non-scaling-stroke"
      />
    </svg>

    <NuxtLink
      v-if="back"
      :to="back"
      class="absolute top-6 flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground ltr:left-4 rtl:right-4"
      :aria-label="t('back', 'Back', 'رجوع')"
    >
      <LucideArrowLeft class="size-5 rtl:-scale-x-100" />
    </NuxtLink>

    <div class="mx-auto flex w-full max-w-sm flex-1 flex-col justify-center px-6 py-16 pb-28">
      <AppMedia v-if="logo" :src="logo" alt="" class="mx-auto h-12 w-auto object-contain" />

      <h1 class="mt-6 text-center font-display text-2xl font-semibold text-foreground">{{ title }}</h1>
      <p v-if="subtitle" class="mt-2 text-center text-sm leading-relaxed break-words text-muted-foreground">{{ subtitle }}</p>

      <div class="mt-8">
        <slot />
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  /** Route name/path for the top-corner back link. Omit to hide it. */
  back: { type: [String, Object], default: null },
})

const { t } = useLang('web', 'general')
const { mediaAsset } = useMedia('web', 'branding')
const logo = computed(() => mediaAsset('logo_mark', '/logo-mark.png'))
</script>
