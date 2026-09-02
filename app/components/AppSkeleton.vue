<template>
  <div class="skeleton" :class="rounded ? 'rounded-full' : 'rounded-md'" aria-hidden="true" />
</template>

<script setup>
/**
 * One placeholder block. Size it from the caller — `class="h-4 w-24"` — since only the
 * caller knows the shape of the thing that is loading.
 *
 * Marked `aria-hidden`: the list it stands in carries `aria-busy`, which is what a
 * screen reader should hear, rather than a dozen empty boxes.
 */
defineProps({
  /** Pill shape, for avatars and chips. */
  rounded: { type: Boolean, default: false },
})
</script>
