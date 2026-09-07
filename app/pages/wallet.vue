<template>
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="mx-auto flex max-w-lg flex-col gap-5">
        <div class="flex items-center justify-between">
          <NuxtLink
            to="/profile"
            class="flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground ltr:-ms-2 rtl:-me-2 rtl:-scale-x-100"
            :aria-label="t('back_to_profile', 'Back to profile', 'عودة للملف')"
          >
            <LucideArrowLeft class="size-5" />
          </NuxtLink>
          <h1 class="font-display text-lg font-semibold text-foreground">{{ t('wallet', 'Wallet', 'المحفظة') }}</h1>
          <span class="size-10" />
        </div>

        <div class="flex flex-col items-center gap-1 rounded-2xl border bg-card p-8">
          <span class="text-sm text-muted-foreground">{{ t('current_balance', 'Current balance', 'الرصيد الحالي') }}</span>
          <span class="font-display text-3xl font-semibold text-brand-rust">{{ format(balance) }}</span>
        </div>

        <section class="rounded-2xl border bg-card p-5">
          <h2 class="font-display text-base font-semibold text-foreground">{{ t('transactions', 'Transactions', 'العمليات') }}</h2>

          <ul v-if="pending" class="mt-4 flex flex-col gap-3" aria-busy="true">
            <AppSkeleton v-for="n in 4" :key="n" class="h-14 w-full" />
          </ul>

          <p v-else-if="!transactions.length" class="mt-4 text-sm text-muted-foreground">
            {{ t('no_transactions', 'No transactions yet.', 'لا توجد عمليات بعد.') }}
          </p>

          <ul v-else class="mt-4 flex flex-col gap-3">
            <li
              v-for="tx in transactions"
              :key="tx.id"
              class="flex items-center justify-between gap-4 rounded-xl border p-4 text-sm"
            >
              <div class="flex flex-col gap-0.5">
                <span class="font-medium text-foreground">{{ reasonLabel(tx.reason) }}</span>
                <span class="text-xs text-muted-foreground">{{ formatDate(tx.created_at) }}</span>
              </div>
              <span
                class="shrink-0 font-medium"
                :class="tx.type === 'credit' ? 'text-brand-green' : 'text-destructive'"
              >{{ tx.type === 'credit' ? '+' : '−' }}{{ format(tx.amount) }}</span>
            </li>
          </ul>

          <!-- Real links, so a page is shareable and crawlable rather than a click handler. -->
          <nav v-if="lastPage > 1" class="mt-6 flex flex-wrap items-center justify-center gap-2">
            <Button v-if="currentPage > 1" as-child size="sm" variant="outline" class="rounded-full">
              <NuxtLink :to="linkTo(currentPage - 1)" rel="prev">{{ t('previous', 'Previous', 'السابق') }}</NuxtLink>
            </Button>
            <Button
              v-for="number in pageNumbers"
              :key="number"
              as-child
              size="sm"
              :variant="number === currentPage ? 'default' : 'outline'"
              class="min-w-10 rounded-full"
            >
              <NuxtLink :to="linkTo(number)" :aria-current="number === currentPage ? 'page' : undefined">{{ number }}</NuxtLink>
            </Button>
            <Button v-if="currentPage < lastPage" as-child size="sm" variant="outline" class="rounded-full">
              <NuxtLink :to="linkTo(currentPage + 1)" rel="next">{{ t('next', 'Next', 'التالي') }}</NuxtLink>
            </Button>
          </nav>
        </section>
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'wallet',
})

const route = useRoute()
const { t } = useLang('web', 'profile')
const { format } = usePrice()

const PER_PAGE = 10
const currentPage = computed(() => Math.max(1, Number(route.query.page ?? 1)))

const { data, pending } = useApiFetch('/api/wallet/transactions', {
  key: 'wallet-transactions',
  query: { page: currentPage, per_page: PER_PAGE },
})

const balance = computed(() => data.value?.data?.balance ?? 0)

const transactions = computed(() => {
  const payload = data.value?.data?.transactions ?? []
  return Array.isArray(payload) ? payload : (payload.data ?? [])
})

const lastPage = computed(() => data.value?.data?.transactions?.last_page ?? 1)

const pageNumbers = computed(() => {
  const last = lastPage.value
  const span = 2
  const from = Math.max(1, currentPage.value - span)
  const to = Math.min(last, currentPage.value + span)
  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

const linkTo = (page) => ({ query: { ...route.query, page: page > 1 ? page : undefined } })

// Free-form reasons from the backend (delivery_fee, booking_cancelled, ...) — translate the
// ones we know, fall back to a readable version of the raw string for anything new.
const reasonLabel = (reason) => {
  const known = {
    delivery_fee: t('reason_delivery_fee', 'Delivery fee', 'رسوم التوصيل'),
    booking_cancelled: t('reason_booking_cancelled', 'Booking cancelled', 'إلغاء حجز'),
  }
  return known[reason] ?? String(reason ?? '').replaceAll('_', ' ')
}

const formatDate = (s) => {
  try { return new Date(s).toLocaleDateString() } catch { return s }
}
</script>
