<template>
  <nav
    class="fixed inset-x-0 bottom-5 z-50 flex justify-center px-4 transition-all duration-500"
    :class="visible ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-6 opacity-0'"
    :aria-hidden="!visible"
  >
    <ul
      class="flex max-w-full items-center gap-1 overflow-x-auto rounded-full border border-white/10 bg-brand-ink/85 p-1.5 text-sm text-white shadow-lg backdrop-blur-md"
    >
      <li v-for="item in items" :key="item.to">
        <NuxtLink
          :to="item.to"
          class="block whitespace-nowrap rounded-full px-4 py-2 transition-colors"
          :class="isActive(item.to) ? 'bg-white text-brand-ink' : 'text-white/75 hover:text-white'"
        >{{ item.label }}</NuxtLink>
      </li>

      <li aria-hidden="true" class="mx-1 h-5 w-px bg-white/15" />

      <li>
        <LanguageSwitcher />
      </li>
    </ul>
  </nav>
</template>

<script setup>
/**
 * The site's primary navigation, as a floating bar. Every destination is public — this
 * build is for exploring, so nothing here leads to booking, checkout or an account.
 *
 * It lives outside `#smooth-content` (see the layout): `position: fixed` inside an
 * element that ScrollSmoother transforms behaves like `absolute` and scrolls away.
 */
const route = useRoute()
const { t } = useLang('web', 'general')

const items = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية') },
  { to: '/workshops', label: t('nav_workshops', 'Workshops', 'الورشات') },
  { to: '/shop', label: t('nav_shop', 'Shop', 'المتجر') },
  { to: '/gallery', label: t('nav_gallery', 'Gallery', 'المعرض') },
  { to: '/about', label: t('nav_about', 'About', 'عن تيراكوتا') },
])

const isActive = (to) => (to === '/' ? route.path === '/' : route.path.startsWith(to))

// On the home page the bar waits until the hero is behind you; everywhere else it is the
// only navigation on screen, so it is there from the start.
const visible = ref(false)

let onScroll = null

onMounted(() => {
  onScroll = () => {
    visible.value = route.path !== '/' || window.scrollY > window.innerHeight * 0.75
  }

  onScroll()
  window.addEventListener('scroll', onScroll, { passive: true })
})

watch(() => route.path, async () => {
  onScroll?.()

  // ScrollSmoother owns the scroll position, so a route change has to reset it explicitly
  // or the next page opens part-way down.
  const { ScrollSmoother } = await import('gsap/all')
  ScrollSmoother.get?.()?.scrollTo(0, false)
})

onBeforeUnmount(() => {
  if (onScroll) window.removeEventListener('scroll', onScroll)
})
</script>
