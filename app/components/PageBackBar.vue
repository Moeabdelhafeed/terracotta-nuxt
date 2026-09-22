<template>
  <div class="flex items-center justify-between">
    <a
      :href="fallback"
      class="flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground -ms-2 rtl:-scale-x-100"
      :aria-label="label || t('back', 'Back', 'رجوع')"
      @click="onBackClick"
    >
      <LucideArrowLeft class="size-5" />
    </a>

    <h1 class="min-w-0 truncate px-2 text-center font-display text-lg font-semibold text-foreground">
      {{ title }}
    </h1>

    <!-- Balances the arrow so the title stays centred; a page with a real action fills it. -->
    <slot name="action"><span class="size-10" /></slot>
  </div>
</template>

<script setup>
/**
 * The back arrow every inner page carries, with the page's title centred beside it.
 *
 * `fallback` is where back goes when there is nowhere to go back TO — see
 * `useBackNavigation` for why it is a fallback and not a destination.
 */
const props = defineProps({
  title: { type: String, default: '' },
  /** Where back goes when this page was opened cold. A path, so it can be an `href`. */
  fallback: { type: String, required: true },
  /** Screen-reader label; defaults to a plain "Back". */
  label: { type: String, default: '' },
})

const { t } = useLang('web', 'general')
const { onBackClick } = useBackNavigation(() => props.fallback)
</script>
