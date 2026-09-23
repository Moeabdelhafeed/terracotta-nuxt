<template>
  <svg
    class="pointer-events-none absolute inset-0 h-full w-full"
    viewBox="0 0 1601 922"
    fill="none"
    preserveAspectRatio="xMidYMid slice"
    aria-hidden="true"
  >
    <path
      d="M533.499 -308.5C561.499 -140.5 487.899 246.8 -30.5009 452C-678.501 708.5 240.999 -304.5 884.499 -146.5C1528 11.5 1738 466.5 1512 1153.5C1286 1840.5 349.5 489.5 -89.5 497.5"
      stroke="currentColor"
      stroke-width="2"
      vector-effect="non-scaling-stroke"
    />
  </svg>
</template>

<script setup>
/**
 * The one line the site is drawn with — the sweep that starts in the hero and carries
 * through to the footer. Decorative, and always the same curve: it was copied into five
 * files, which is four chances for one of them to drift into a different mark.
 *
 * The caller owns its ink and its depth (`text-white/20`, `-z-10`); the curve and the way
 * it fills its box belong here. `slice`, so it crops rather than squashing — the shape is
 * a gesture, and a squashed gesture reads as a different one.
 *
 * `HomeHero` keeps its own copy on purpose: there the path is drawn on by GSAP and needs
 * a ref of its own.
 */
</script>
