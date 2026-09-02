<template>
  <Html :lang="code" :dir="dir" class="light">
    <Body class="bg-brand-terracotta">
      <main class="relative isolate flex min-h-svh flex-col items-center justify-center overflow-hidden px-6 py-16 text-center text-white">
        <!-- The line the rest of the site is drawn with. Decorative only. -->
        <svg
          class="pointer-events-none absolute inset-0 -z-10 h-full w-full text-white/15"
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

        <img src="/logo-light.png" alt="" class="h-14 w-auto object-contain sm:h-16">

        <p class="mt-10 font-display text-6xl font-black leading-none sm:text-7xl">{{ status }}</p>

        <h1 class="mt-6 max-w-md font-display text-2xl font-semibold sm:text-3xl">{{ copy.title }}</h1>
        <p class="mt-4 max-w-sm text-white/75">{{ copy.body }}</p>

        <div class="mt-10 flex flex-wrap items-center justify-center gap-3">
          <Button size="lg" variant="secondary" class="h-12 rounded-xl px-8" @click="handleError">
            {{ copy.home }}
          </Button>

          <Button
            v-if="!isNotFound"
            size="lg"
            variant="outline"
            class="h-12 rounded-xl border-white/40 bg-transparent px-8 text-white hover:bg-white/10 hover:text-white"
            @click="reload"
          >
            {{ copy.retry }}
          </Button>
        </div>
      </main>
    </Body>
  </Html>
</template>

<script setup>
/**
 * The whole site's error screen — 404s and crashes both land here.
 *
 * Deliberately self-contained: no `useLang`, no `useMedia`, no API call of any kind. This
 * page is what renders when something has already gone wrong, and a fetch here would be
 * one more thing to fail. The locale comes off the cookie and the copy is inline.
 */
const props = defineProps({
  error: { type: Object, default: () => ({}) },
})

const lang = useCookie('lang')

const code = computed(() => lang.value?.code ?? 'ar')
const dir = computed(() => lang.value?.direction ?? 'rtl')

const status = computed(() => props.error?.statusCode ?? 500)
const isNotFound = computed(() => status.value === 404)

const COPY = {
  ar: {
    notFound: {
      title: 'لم نجد هذه الصفحة',
      body: 'الرابط الذي فتحته لم يعد موجودًا، أو ربما تغيّر.',
    },
    failed: {
      title: 'حدث خطأ ما',
      body: 'تعذّر تحميل الصفحة. حاول مرة أخرى بعد قليل.',
    },
    home: 'العودة للرئيسية',
    retry: 'حاول مرة أخرى',
  },
  en: {
    notFound: {
      title: 'We could not find that page',
      body: 'The link you opened no longer exists, or it may have changed.',
    },
    failed: {
      title: 'Something went wrong',
      body: 'The page could not be loaded. Try again in a moment.',
    },
    home: 'Back to home',
    retry: 'Try again',
  },
}

const copy = computed(() => {
  const set = COPY[code.value] ?? COPY.ar
  const state = isNotFound.value ? set.notFound : set.failed

  return { ...state, home: set.home, retry: set.retry }
})

// Clears the error before navigating, otherwise the screen stays up over the new route.
const handleError = () => clearError({ redirect: '/' })
const reload = () => reloadNuxtApp()
</script>
