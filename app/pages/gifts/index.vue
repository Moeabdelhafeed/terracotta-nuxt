<template>
  <main class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-4xl px-6 py-16">
      <header class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('gifts_title', 'My gifts', 'هداياي') }}</h1>
          <p class="mt-2 text-muted-foreground">
            {{ t('gifts_subtitle', 'Credit you have gifted, newest first.', 'الرصيد الذي أهديته، الأحدث أولًا.') }}
          </p>
        </div>

        <Button as-child class="h-12 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90">
          <NuxtLink to="/gifts/new">
            <LucideGift class="size-4" />
            {{ t('gift_new_cta', 'Gift credit', 'اهداء رصيد') }}
          </NuxtLink>
        </Button>
      </header>

      <div v-if="pending && !items.length" class="mt-10 flex flex-col gap-4" aria-busy="true">
        <AppSkeleton v-for="n in 3" :key="n" class="h-40 w-full !rounded-3xl" />
      </div>

      <section v-else-if="!items.length" class="mt-10 rounded-3xl border bg-card p-10 text-center">
        <span class="mx-auto flex size-14 items-center justify-center rounded-2xl bg-brand-mist text-brand-rust">
          <LucideGift class="size-6" />
        </span>
        <h2 class="mt-5 font-display text-xl font-semibold">
          {{ t('gifts_empty_title', 'No gifts yet', 'لا توجد هدايا بعد') }}
        </h2>
        <p class="mt-2 text-sm text-muted-foreground">
          {{ t('gifts_empty_body', 'Send a credit gift to someone you love, to enjoy our pottery and ceramics workshops.', 'أرسل هدية رصيد لأحبائك للاستمتاع بورشات الفخار والسيراميك') }}
        </p>
        <Button as-child class="mt-6 h-12 rounded-xl bg-brand-rust px-8 text-base hover:bg-brand-rust/90">
          <NuxtLink to="/gifts/new">{{ t('gift_new_cta', 'Gift credit', 'اهداء رصيد') }}</NuxtLink>
        </Button>
      </section>

      <ul v-else class="mt-10 flex flex-col gap-4">
        <li v-for="gift in items" :key="gift.id">
          <GiftCard :gift="gift" />
        </li>
      </ul>

      <nav v-if="lastPage > 1" class="mt-10 flex items-center justify-center gap-2">
        <Button
          v-for="n in pages"
          :key="n"
          as-child
          size="sm"
          class="rounded-full"
          :variant="n === page ? 'default' : 'outline'"
        >
          <NuxtLink :to="linkTo(n)">{{ n }}</NuxtLink>
        </Button>
      </nav>
    </div>
  </main>
</template>

<script setup>
/**
 * The buyer's own gifts. `per_page` is opt-in on this endpoint — sending it is what turns
 * the plain array into a paginator, which is why the page always sends one.
 */
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'gifts',
})

const route = useRoute()
const { t } = useLang('web', 'gifts')
const { list } = useGifts()

const page = computed(() => Number(route.query.page ?? 1) || 1)
const { items, lastPage, pending } = list({ page, per_page: 10 })

const crumbs = computed(() => [{ label: t('gifts_title', 'My gifts', 'هداياي') }])

const pages = computed(() => {
  const from = Math.max(1, page.value - 2)
  const to = Math.min(lastPage.value, page.value + 2)
  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

const linkTo = (n) => ({ query: { ...route.query, page: n > 1 ? n : undefined } })

useSeoMeta({ title: () => t('gifts_title', 'My gifts', 'هداياي'), robots: 'noindex, nofollow' })
</script>
