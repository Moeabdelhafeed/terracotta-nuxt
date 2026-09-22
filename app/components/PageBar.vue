<template>
  <!--
    Detail pages open straight into content, with no hero to carry the brand or say where
    you are. This band does both: the mark on terracotta, and the trail back up.
  -->
  <header class="bg-chrome text-white">
    <div class="mx-auto flex max-w-6xl items-center gap-4 px-6 py-4">
      <!-- Every bar carries one: these pages hide the bottom bar, so without it there is
           no way back out but the browser's own button.

           `backTo` is the FALLBACK, not the destination — a workshop is opened from the
           home page, the workshops list and «قطعي» alike. See `useBackNavigation`. -->
      <a
        :href="backTo"
        class="-ms-2 flex size-10 shrink-0 items-center justify-center rounded-control text-white/85 transition-colors hover:bg-white/15 hover:text-white"
        :aria-label="t('back', 'Back', 'رجوع')"
        @click="onBackClick"
      >
        <LucideArrowLeft class="size-5 rtl:-scale-x-100" />
      </a>

      <NuxtLink to="/" class="shrink-0" :aria-label="t('nav_home', 'Home', 'الرئيسية')">
        <AppMedia :src="logo" alt="" class="h-9 w-auto object-contain" />
      </NuxtLink>

      <nav class="min-w-0 flex-1">
        <ol class="flex flex-wrap items-center gap-y-1 text-sm">
          <li v-for="(crumb, index) in crumbs" :key="index" class="flex min-w-0 items-center">
            <NuxtLink
              v-if="crumb.to"
              :to="crumb.to"
              class="whitespace-nowrap text-white/75 underline-offset-4 transition-colors hover:text-white hover:underline"
            >{{ crumb.label }}</NuxtLink>
            <span v-else class="truncate text-base font-bold" aria-current="page">{{ crumb.label }}</span>

            <span v-if="index < crumbs.length - 1" class="px-2 text-white/40" aria-hidden="true">/</span>
          </li>
        </ol>
      </nav>
    </div>
  </header>
</template>

<script setup>
/** A crumb without `to` is the current page, so the last one is normally plain text. */
const props = defineProps({
  crumbs: { type: Array, default: () => [] },
  /**
   * Fallback for the back arrow. Left out, the trail supplies it: the last crumb that
   * links somewhere IS this page's parent, so there is nothing to repeat by hand.
   */
  back: { type: String, default: '' },
})

const backTo = computed(() =>
  props.back || [...props.crumbs].reverse().find((crumb) => crumb.to)?.to || '/',
)

const { t } = useLang('web', 'general')
const { onBackClick } = useBackNavigation(backTo)
const { mediaAsset } = useMedia('web', 'branding')

// The band sits on terracotta, so it takes the light mark rather than the default one.
const logo = computed(() => mediaAsset('logo_light', '/logo-light.png'))
</script>
