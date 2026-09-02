<template>
  <!-- Fixed and inert: it plays over whatever is underneath and can never swallow a tap
       meant for the page. -->
  <div ref="root" class="pointer-events-none fixed inset-0 z-[90] overflow-hidden" aria-hidden="true">
    <span
      v-for="n in count"
      :key="n"
      class="absolute left-1/2 top-1/3 block"
      :style="pieceStyle(n)"
    />
  </div>
</template>

<script setup>
/**
 * A burst of paper over the page, played once. Hand-rolled rather than a library: it is
 * a GSAP timeline over a few dozen spans, and GSAP is already here.
 *
 * The pieces are laid out at one point and thrown outward — position, angle and spin are
 * random per piece, so no two openings look alike.
 */
const props = defineProps({
  count: { type: Number, default: 90 },
  /** Brand paper. Anything CSS accepts. */
  colors: {
    type: Array,
    default: () => ['#FC8B8B', '#F07272', '#6B2E19', '#4A7C59', '#E8DCCB', '#FFFFFF'],
  },
})

const emit = defineEmits(['done'])

const random = (min, max) => min + Math.random() * (max - min)

// Sizes and colours are decided once, in render, so a piece keeps them for its whole life.
const pieceStyle = (n) => {
  const width = random(6, 12)
  return {
    width: `${width}px`,
    height: `${random(8, 16)}px`,
    backgroundColor: props.colors[n % props.colors.length],
    borderRadius: n % 3 === 0 ? '9999px' : '2px',
    opacity: 0,
  }
}

const root = ref(null)

onMounted(() => {
  // A burst of paper is exactly what reduced-motion asks us not to do.
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    emit('done')
    return
  }

  const gsap = useGSAP()
  const pieces = [...root.value.children]

  const tl = gsap.timeline({ onComplete: () => emit('done') })

  pieces.forEach((piece) => {
    // Thrown up and out, then carried down past the bottom of the screen — two tweens
    // rather than one arc, so the fall can outlast the rise the way paper does.
    const drift = random(-window.innerWidth * 0.55, window.innerWidth * 0.55)
    const lift = random(-window.innerHeight * 0.45, -window.innerHeight * 0.15)

    tl.fromTo(
      piece,
      { x: random(-30, 30), y: 0, opacity: 1, rotation: random(0, 360) },
      { x: drift, y: lift, duration: random(0.5, 0.9), ease: 'power2.out' },
      0,
    ).to(
      piece,
      {
        y: window.innerHeight * 0.9,
        x: drift + random(-60, 60),
        rotation: `+=${random(180, 720)}`,
        opacity: 0,
        duration: random(1.2, 2.2),
        ease: 'power1.in',
      },
      random(0.5, 0.9),
    )
  })

  onBeforeUnmount(() => tl.kill())
})
</script>
