<template>
  <!--
    Detail pages open straight into content, with no hero to carry the brand or say where
    you are. This band does both: the mark on terracotta, and the trail back up.
  -->
  <header class="bg-brand-terracotta text-white">
    <div class="mx-auto flex max-w-6xl items-center gap-4 px-6 py-4">
      <NuxtLink to="/" class="shrink-0" :aria-label="t('nav_home', 'Home', 'الرئيسية')">
        <AppMedia :src="logo" alt="" class="h-9 w-auto object-contain" />
      </NuxtLink>

      <nav class="min-w-0 flex-1">
        <ol class="flex items-center text-sm">
          <li v-for="(crumb, index) in crumbs" :key="index" class="flex min-w-0 items-center">
            <NuxtLink
              v-if="crumb.to"
              :to="crumb.to"
              class="whitespace-nowrap text-white/75 underline-offset-4 transition-colors hover:text-white hover:underline"
            >{{ crumb.label }}</NuxtLink>
            <span v-else class="truncate font-medium">{{ crumb.label }}</span>

            <span v-if="index < crumbs.length - 1" class="px-2 text-white/40" aria-hidden="true">/</span>
          </li>
        </ol>
      </nav>
    </div>
  </header>
</template>

<script setup>
/** A crumb without `to` is the current page, so the last one is normally plain text. */
defineProps({
  crumbs: { type: Array, default: () => [] },
})

const { t } = useLang('web', 'general')
const { mediaAsset } = useMedia('web', 'branding')

// The band sits on terracotta, so it takes the light mark rather than the default one.
const logo = computed(() => mediaAsset('logo_light', '/logo-light.png'))
</script>
