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
      <LoginPrompt />
      <AppToaster />

      <!-- Once per page LOAD, wherever that load lands. It used to live on the home page
           alone, so arriving on a shared link to a workshop or a piece — which is how most
           people arrive — never showed the studio's mark at all. -->
      <AppSplash />
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
  // One rule for every scroll effect on the site — see `pageMotionEnabled()`. It covers
  // the OS reduced-motion setting (smoothing is a comfort feature for some and motion
  // sickness for others, and ScrollSmoother has none of its own) and every screen below
  // desktop width.
  //
  // Phones keep their own scrolling. A touch scroll is already inertial, and smoothing it
  // means every flick is re-driven a frame late through a transform — the lag a thumb
  // reads as the page not answering. `normalizeScroll` makes it worse: it takes the touch
  // over entirely.
  if (!pageMotionEnabled()) return

  smoother = ScrollSmoother.create({
    smooth: 1, // seconds it takes to catch up to the real scroll position
    smoothTouch: 0.1, // touch devices get a much shorter catch-up, or it feels laggy
    effects: true, // enables data-speed / data-lag attributes for parallax
    /*
     * Normalising keeps the mobile address bar from fighting the pins, but it does it by
     * taking touch over completely — and that stops every nested scroller on the site
     * working with a finger: the date rail, the seats, the banners, the category shelves.
     * `allowNestedScroll` hands a touch back to whichever scrollable element it started
     * in, so those rails pan natively again while the page keeps the normalised scroll.
     */
    normalizeScroll: { allowNestedScroll: true },
    /*
     * ScrollSmoother scrolls to whatever takes focus, so keyboard users land on what they
     * tabbed to. That only makes sense for the page's own content: the nav bar, its
     * dropdown, the dialogs and the toasts live OUTSIDE #smooth-content, and "scrolling
     * to" one of them computes a position that means nothing. Opening the About dropdown
     * focuses its menu, and every click threw the page up a screen (QA WEB-02).
     */
    onFocusIn: (self, event) => self.content().contains(event.target),
  })
})

onBeforeUnmount(() => {
  smoother?.kill()
  smoother = null
})
</script>
