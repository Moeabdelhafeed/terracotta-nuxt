<template>
  <nav
    class="fixed inset-x-0 bottom-6 z-50 flex justify-center px-3 transition-all duration-500"
    :class="
      visible
        ? 'translate-y-0 opacity-100'
        : 'pointer-events-none translate-y-6 opacity-0'
    "
    :aria-hidden="!visible"
  >
    <!-- The app's bar, to its own measurements: a solid terracotta slab at 11, its
         destinations 54 square inside 10 of padding, and the current one lit by white
         at 16% behind a 5-corner square.
         The app draws no edge on it because an app screen is never terracotta. This one
         floats over `HomeHero`'s panel and `PageBar`, which are the *same* token, so
         without the hairline the bar dissolves into them. A ring rather than a border:
         it costs the flex row no width. -->
    <ul
      class="flex max-w-full items-center gap-1.5 overflow-x-auto scrollbar-none rounded-control bg-brand-terracotta p-2.5 text-sm text-white ring-1 ring-white/10"
    >
      <li v-for="item in items" :key="item.to">
        <NuxtLink
          :to="item.to"
          class="flex h-[54px] items-center whitespace-nowrap rounded-[5px] px-4 transition-colors"
          :class="
            isActive(item.to)
              ? 'bg-white/15 text-white'
              : 'text-white/70 hover:bg-white/10 hover:text-white'
          "
          >{{ item.label }}</NuxtLink
        >
      </li>

      <li aria-hidden="true" class="mx-1 h-6 w-px bg-white/20" />

      <li>
        <NuxtLink
          to="/cart"
          class="relative flex size-[54px] items-center justify-center rounded-[5px] transition-colors"
          :class="
            isActive('/cart')
              ? 'bg-white/15 text-white'
              : 'text-white/70 hover:bg-white/10 hover:text-white'
          "
          :aria-label="t('nav_cart', 'Cart', 'عربيتي')"
        >
          <LucideShoppingCart class="size-[26px]" />
          <span
            v-if="cartCount > 0"
            class="absolute top-2 end-2 flex h-4 min-w-4 items-center justify-center rounded-full bg-brand-blush px-1 text-[10px] font-semibold text-brand-ink"
            dir="ltr"
            >{{ cartCount > 99 ? "99+" : cartCount }}</span
          >
        </NuxtLink>
      </li>

      <li>
        <NotificationBell />
      </li>

      <li>
        <LanguageSwitcher />
      </li>
    </ul>
  </nav>
</template>

<script setup>
/**
 * The site's primary navigation, as a floating bar. The last item is the account entry
 * point — Login for a guest, Profile once signed in — so it moves as the session does.
 *
 * It lives outside `#smooth-content` (see the layout): `position: fixed` inside an
 * element that ScrollSmoother transforms behaves like `absolute` and scrolls away.
 */
const route = useRoute();
const { t } = useLang("web", "general");
const { appUsers } = useAuthConfig();

// Everyone gets a guest identity automatically, so being authenticated is not "has an
// account" — a browsing guest would otherwise see "Profile" and land on a page gated to
// registered users only.
const { isRegistered } = useIsRegistered();

// A visitor without an account has a cart too — it just lives in localStorage until they
// sign in — so the entry and its badge are shown to everyone.
const { count: cartCount } = useCart();

const items = computed(() => [
  { to: "/", label: t("nav_home", "Home", "الرئيسية") },
  { to: "/workshops", label: t("nav_workshops", "Workshops", "الورشات") },
  { to: "/shop", label: t("nav_shop", "Shop", "المتجر") },
  {
    to: "/materials",
    label: t("nav_materials", "Raw materials & tools", "المواد الخام والأدوات"),
  },
  { to: "/gallery", label: t("nav_gallery", "Gallery", "المعرض") },
  { to: "/about", label: t("nav_about", "About", "عن تيراكوتا") },
  ...(appUsers.value
    ? [
        isRegistered.value
          ? { to: "/profile", label: t("nav_profile", "Profile", "حسابي") }
          : { to: "/login", label: t("nav_login", "Login", "تسجيل الدخول") },
      ]
    : []),
]);

const isActive = (to) =>
  to === "/" ? route.path === "/" : route.path.startsWith(to);

// On the home page the bar waits until the hero is behind you; everywhere else it is the
// only navigation on screen, so it is there from the start.
const visible = ref(false);

let onScroll = null;

onMounted(() => {
  onScroll = () => {
    visible.value =
      route.path !== "/" || window.scrollY > window.innerHeight * 0.75;
  };

  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });
});

watch(
  () => route.path,
  async () => {
    onScroll?.();

    // ScrollSmoother owns the scroll position, so a route change has to reset it explicitly
    // or the next page opens part-way down.
    const { ScrollSmoother } = await import("gsap/all");
    ScrollSmoother.get?.()?.scrollTo(0, false);
  },
);

onBeforeUnmount(() => {
  if (onScroll) window.removeEventListener("scroll", onScroll);
});
</script>
