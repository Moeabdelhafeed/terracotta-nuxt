<template>
  <Html :lang="code" :dir="dir" class="light">
    <Body>
      <!--
        ScrollSmoother moves #smooth-content with a transform, which means anything
        `position: fixed` *inside* it behaves like `absolute` and scrolls away. The
        language switcher therefore lives outside the wrapper, as do teleported modals.
      -->
      <div id="smooth-wrapper">
        <div id="smooth-content">
          <div class="flex min-h-svh flex-col">
            <!-- The page takes the slack so a short page still pushes the footer to the
                 bottom, instead of the layout collapsing around whatever it renders. -->
            <div class="flex-1">
              <NuxtPage />
            </div>
            <AppFooter />
          </div>
        </div>
      </div>

      <AppBottomNav />
    </Body>
  </Html>
</template>

<script setup>
import { ScrollSmoother } from 'gsap/all'

const { code, dir } = useLang()

onBeforeMount(() => {
  useGSAP().registerPlugin(ScrollSmoother)
})

let smoother = null

onMounted(() => {
  // Honour the OS setting: smoothing is a comfort feature for some and motion sickness
  // for others, and ScrollSmoother has no reduced-motion behaviour of its own.
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return

  smoother = ScrollSmoother.create({
    smooth: 1, // seconds it takes to catch up to the real scroll position
    smoothTouch: 0.1, // touch devices get a much shorter catch-up, or it feels laggy
    effects: true, // enables data-speed / data-lag attributes for parallax
    normalizeScroll: true, // keeps mobile address-bar resizes from fighting the pins
  })
})

onBeforeUnmount(() => {
  smoother?.kill()
  smoother = null
})
</script>
