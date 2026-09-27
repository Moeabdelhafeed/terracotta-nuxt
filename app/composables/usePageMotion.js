/**
 * Whether this device gets scroll-driven motion at all.
 *
 * Phones do not. ScrollSmoother, pinned scrubs and entrance staggers are a desktop
 * flourish that costs a phone real frames, fights the OS's own scrolling, and — inside the
 * app's web view — leaves the page feeling like it is resisting the finger. The site is
 * laid out to read correctly with none of it: every animated element is visible in the
 * server's HTML and only ever animates *from* somewhere, so switching the motion off
 * changes nothing about what is on screen.
 *
 * 1024px is the same boundary `useStickyAside` already pins against, so one rule governs
 * every scroll effect on the site. `prefers-reduced-motion` switches it off at any size.
 *
 * Read once, at setup: a phone does not become a desktop mid-visit, and re-evaluating on
 * resize would start a pinned timeline against a page that has already been laid out
 * without one.
 */
export const pageMotionEnabled = () =>
  import.meta.client &&
  window.matchMedia("(min-width: 1024px)").matches &&
  !window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/** The `from` object for an entrance animation, or nothing to animate on a phone. */
export const entranceFrom = (from) => (pageMotionEnabled() ? from : {});
