<template>
  <main class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <header class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('gifts_title', 'My gifts', 'هداياي') }}</h1>
          <p class="mt-2 text-muted-foreground">
            {{ t('gifts_subtitle_both', 'Credit you have gifted and credit you have claimed, newest first.', 'الرصيد الذي أهديته والرصيد الذي استلمته، الأحدث أولًا.') }}
          </p>
        </div>

        <Button as-child class="h-12 rounded-control bg-brand-rust text-base hover:bg-brand-rust/90">
          <NuxtLink to="/gifts/new">
            <LucideGift class="size-4" />
            {{ t('gift_new_cta', 'Gift credit', 'اهداء رصيد') }}
          </NuxtLink>
        </Button>
      </header>

      <div v-if="pending && !entries.length" class="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3" aria-busy="true">
        <AppSkeleton v-for="n in 3" :key="n" class="h-40 w-full rounded-card!" />
      </div>

      <!-- A failed read is not an empty shelf: "no gifts yet" would be a claim the site
           cannot make when it never heard back. -->
      <AppLoadError v-else-if="error && !entries.length" class="mt-10" :error="error" :retry="refresh" />

      <section v-else-if="!entries.length" class="mx-auto mt-10 max-w-xl rounded-card border bg-card p-10 text-center">
        <span class="mx-auto flex size-14 items-center justify-center rounded-field bg-brand-rust/10 text-brand-rust">
          <LucideGift class="size-6" />
        </span>
        <h2 class="mt-5 font-display text-xl font-semibold">
          {{ t('gifts_empty_title', 'No gifts yet', 'لا توجد هدايا بعد') }}
        </h2>
        <p class="mt-2 text-sm text-muted-foreground">
          {{ t('gifts_empty_body', 'Send a credit gift to someone you love, to enjoy our pottery and ceramics workshops.', 'أرسل هدية رصيد لأحبائك للاستمتاع بورشات الفخار والسيراميك') }}
        </p>
        <Button as-child class="mt-6 h-12 rounded-control bg-brand-rust px-8 text-base hover:bg-brand-rust/90">
          <NuxtLink to="/gifts/new">{{ t('gift_new_cta', 'Gift credit', 'اهداء رصيد') }}</NuxtLink>
        </Button>
      </section>

      <template v-else>
        <!-- The counts are the filter: `totals` covers the whole history whatever is
             shown, so a chip's label is true before it is pressed and after. -->
        <ul class="mt-10 flex flex-wrap gap-2" data-test="gift-filters">
          <li v-for="tab in tabs" :key="tab.key">
            <Button
              size="sm"
              class="rounded-control"
              :variant="tab.key === only ? 'default' : 'outline'"
              :class="tab.key === only ? 'bg-brand-rust hover:bg-brand-rust/90' : ''"
              :data-direction="tab.key"
              @click="only = tab.key"
            >
              {{ tab.label }}
              <span class="ms-2 rounded-full px-2 text-xs" :class="tab.key === only ? 'bg-white/20' : 'bg-muted'">{{ tab.count }}</span>
            </Button>
          </li>
        </ul>

        <!-- Said about the filter, not about the history: they have gifts, just none on
             this side. -->
        <p v-if="!shown.length" class="mt-8 rounded-card border bg-card p-10 text-center text-sm text-muted-foreground" data-test="gifts-filter-empty">
          {{ only === 'received'
            ? t('gift_none_received', 'You have not claimed any gifts yet', 'لم تستلم أي هدية بعد')
            : t('gift_none_sent', 'You have not sent any gifts yet', 'لم ترسل أي هدية بعد') }}
        </p>

        <ul v-else class="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <li v-for="entry in shown" :key="`${entry.direction}-${entry.id}`">
            <GiftReceivedCard v-if="entry.direction === 'received'" :gift="entry" />
            <GiftCard v-else :gift="entry" />
          </li>
        </ul>
      </template>
    </div>
  </main>
</template>

<script setup>
/**
 * Both sides of the reader's gifting — what they bought and what they claimed — off
 * `GET /api/gifts/history`. The whole list arrives at once (no `per_page`), so narrowing
 * to one side is a filter rather than a request and a spinner.
 *
 * A received row is narrower than a sent one and has no detail page behind it: the token
 * and the share link belong to whoever bought the gift.
 */
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'gifts',
})

const { t } = useLang('web', 'gifts')
const { history } = useGifts()

const { entries, sentCount, receivedCount, pending, error, refresh } = history()

const only = ref('all')

const tabs = computed(() => [
  { key: 'all', label: t('gift_filter_all', 'All', 'الكل'), count: sentCount.value + receivedCount.value },
  { key: 'sent', label: t('gift_filter_sent', 'Sent', 'أرسلتها'), count: sentCount.value },
  { key: 'received', label: t('gift_filter_received', 'Claimed', 'استلمتها'), count: receivedCount.value },
])

// A row with no `direction` is a sent one: that is the shape carrying everything.
const shown = computed(() => entries.value.filter(
  (entry) => only.value === 'all' || (entry.direction ?? 'sent') === only.value,
))

const crumbs = computed(() => [{ label: t('gifts_title', 'My gifts', 'هداياي') }])

useSeoMeta({ title: () => t('gifts_title', 'My gifts', 'هداياي'), robots: 'noindex, nofollow' })
</script>
