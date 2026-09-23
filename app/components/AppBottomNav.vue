<template>
  <!--
    The bar, from `sm` up. Seven destinations plus three controls fit a tablet and do not
    fit a phone: at 390 they became a horizontally scrolling strip, so finding "Gallery"
    meant dragging the navigation sideways before you could use it.
  -->
  <nav
    class="fixed inset-x-0 bottom-6 z-50 hidden justify-center px-3 transition-all duration-500 sm:flex"
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
      class="chrome-fixed flex max-w-full items-center gap-1.5 overflow-x-auto scrollbar-none rounded-control bg-brand-terracotta p-2.5 text-sm text-white ring-1 ring-white/10"
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

      <li v-if="appUsers">
        <NuxtLink
          to="/favorites"
          class="relative flex size-[54px] items-center justify-center rounded-[5px] transition-colors"
          :class="
            isActive('/favorites')
              ? 'bg-white/15 text-white'
              : 'text-white/70 hover:bg-white/10 hover:text-white'
          "
          :aria-label="t('nav_favorites', 'Favourites', 'المفضلة')"
        >
          <LucideHeart class="size-[26px]" />
          <span
            v-if="favoriteCount > 0"
            class="absolute top-2 end-2 flex h-4 min-w-4 items-center justify-center rounded-full bg-brand-blush px-1 text-[10px] font-semibold text-brand-ink"
            dir="ltr"
            >{{ favoriteCount > 99 ? "99+" : favoriteCount }}</span
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

  <!--
    The phone: one button, and everything behind it.

    On the ENDING side rather than centred — a thumb reaches the bottom corner of a phone
    it is already holding, and the middle of the screen is where the page's own last
    control usually sits.
  -->
  <div
    class="chrome-fixed fixed bottom-6 z-50 transition-all duration-500 sm:hidden ltr:right-4 rtl:left-4"
    :class="
      visible
        ? 'translate-y-0 opacity-100'
        : 'pointer-events-none translate-y-6 opacity-0'
    "
    :aria-hidden="!visible"
  >
    <button
      type="button"
      class="relative flex size-14 items-center justify-center rounded-full bg-brand-terracotta text-white shadow-lg ring-1 ring-white/10 transition-transform active:scale-95"
      :aria-label="t('nav_menu', 'Menu', 'القائمة')"
      aria-haspopup="menu"
      :aria-expanded="menuOpen"
      data-test="nav-fab"
      @click="menuOpen = true"
    >
      <LucideMenu class="size-6" />

      <!-- The basket is the one thing worth knowing without opening anything. -->
      <span
        v-if="cartCount > 0"
        class="absolute -top-0.5 flex h-5 min-w-5 items-center justify-center rounded-full bg-brand-blush px-1 text-[11px] font-semibold text-brand-ink ltr:-right-0.5 rtl:-left-0.5"
        dir="ltr"
        >{{ cartCount > 99 ? "99+" : cartCount }}</span
      >
    </button>
  </div>

  <Teleport to="body">
    <Transition name="sheet">
      <div
        v-if="menuOpen"
        data-animated
        class="fixed inset-0 z-[60] sm:hidden"
        role="dialog"
        aria-modal="true"
        :aria-label="t('nav_menu', 'Menu', 'القائمة')"
        data-test="nav-menu"
      >
        <div class="absolute inset-0 bg-black/50" @click="menuOpen = false" />

        <!--
          Anchored to the button it came out of, not centred: the menu opens where the
          thumb already is, and the list runs up the screen away from it.
        -->
        <div
          data-sheet-panel
          class="chrome-fixed absolute inset-x-4 bottom-6 max-h-[80svh] origin-bottom overflow-y-auto rounded-sheet bg-brand-terracotta p-3 text-white shadow-2xl ring-1 ring-white/10"
        >
          <ul class="flex flex-col gap-1">
            <li v-for="item in items" :key="item.to">
              <NuxtLink
                :to="item.to"
                class="flex h-12 items-center rounded-control px-4 text-base transition-colors"
                :class="
                  isActive(item.to)
                    ? 'bg-white/15 text-white'
                    : 'text-white/80 active:bg-white/10'
                "
                >{{ item.label }}</NuxtLink
              >
            </li>
          </ul>

          <div class="my-3 h-px bg-white/20" aria-hidden="true" />

          <!-- The controls the bar carries, icon-only on one row so the destinations
               keep the height. -->
          <div class="flex items-center gap-1.5">
            <NuxtLink
              to="/cart"
              class="relative flex size-[54px] items-center justify-center rounded-[5px] transition-colors"
              :class="
                isActive('/cart')
                  ? 'bg-white/15 text-white'
                  : 'text-white/80 active:bg-white/10'
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

            <NuxtLink
              v-if="appUsers"
              to="/favorites"
              class="relative flex size-[54px] items-center justify-center rounded-[5px] transition-colors"
              :class="
                isActive('/favorites')
                  ? 'bg-white/15 text-white'
                  : 'text-white/80 active:bg-white/10'
              "
              :aria-label="t('nav_favorites', 'Favourites', 'المفضلة')"
            >
              <LucideHeart class="size-[26px]" />
              <span
                v-if="favoriteCount > 0"
                class="absolute top-2 end-2 flex h-4 min-w-4 items-center justify-center rounded-full bg-brand-blush px-1 text-[10px] font-semibold text-brand-ink"
                dir="ltr"
                >{{ favoriteCount > 99 ? "99+" : favoriteCount }}</span
              >
            </NuxtLink>

            <NotificationBell />
            <LanguageSwitcher />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
/**
 * The site's primary navigation. A floating bar with room for every destination from `sm`
 * up; on a phone, one button that opens the same list.
 *
 * The last item is the account entry point — Login for a guest, Profile once signed in —
 * so it moves as the session does.
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

// Hearts count for everyone too: a guest's live in localStorage until they sign in.
const { count: favoriteCount } = useFavorites();

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

const menuOpen = ref(false);

// The page behind a full-screen menu must not scroll under it.
const locked = useScrollLock(import.meta.client ? document.body : null);
watch(menuOpen, (open) => { locked.value = open; });
onScopeDispose(() => { locked.value = false; });

const onKey = (event) => { if (event.key === "Escape") menuOpen.value = false; };
onMounted(() => window.addEventListener("keydown", onKey));
onBeforeUnmount(() => window.removeEventListener("keydown", onKey));

// On the home page the bar waits until the hero is behind you; everywhere else it is the
// only navigation on screen, so it is there from the start.
const visible = ref(false);

let onScroll = null;

onMounted(() => {
  onScroll = () => {
    const past =
      route.path !== "/" || window.scrollY > window.innerHeight * 0.75;

    visible.value = past;
  };

  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });
});

watch(
  () => route.path,
  async () => {
    // Tapping a destination is the one thing this menu is for, so it closes itself.
    menuOpen.value = false;
    onScroll?.();

    // Whatever owns the scroll has to be reset explicitly, or the next page opens
    // part-way down.
    await scrollToTop();
  },
);

onBeforeUnmount(() => {
  if (onScroll) window.removeEventListener("scroll", onScroll);
});
</script>
