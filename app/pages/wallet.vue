<template>
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-5">
        <div class="flex items-center justify-between">
          <NuxtLink
            to="/profile"
            class="flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground -ms-2 rtl:-scale-x-100"
            :aria-label="t('back_to_profile', 'Back to profile', 'عودة للملف')"
          >
            <LucideArrowLeft class="size-5" />
          </NuxtLink>
          <h1 class="font-display text-lg font-semibold text-foreground">{{ t('wallet', 'Wallet', 'المحفظة') }}</h1>
          <span class="size-10" />
        </div>

        <div class="grid gap-5 lg:grid-cols-2 lg:items-start">
          <div class="flex flex-col items-center gap-1 rounded-2xl border bg-card p-8">
            <span class="text-sm text-muted-foreground">{{ t('terracotta_balance', 'Terracotta balance', 'رصيد تيراكوتا') }}</span>
            <span data-test="wallet-balance" class="font-display text-3xl font-semibold text-brand-rust">{{ format(balance) }}</span>
            <Button as-child class="mt-4 h-12 w-full rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90">
              <NuxtLink to="/gifts/new">
                <LucideGift class="size-4" />
                {{ t('gift_credit', 'Gift credit', 'اهداء رصيد') }}
              </NuxtLink>
            </Button>
          </div>

          <!-- Store credit is not cash — saying so here saves a support ticket per refund. -->
          <section class="rounded-2xl border bg-card p-5">
            <h2 class="flex items-center gap-2 font-display text-base font-semibold text-foreground">
              <LucideInfo class="size-4 text-brand-rust" />
              {{ t('wallet_how_it_works', 'How the wallet works', 'كيف تعمل المحفظة') }}
            </h2>
            <ul class="mt-3 flex flex-col gap-2 text-sm text-muted-foreground">
              <li class="flex gap-2">
                <LucideCheck class="mt-0.5 size-4 shrink-0 text-brand-green" />
                {{ t('wallet_rule_credit', 'Your balance is store credit for Terracotta — it cannot be withdrawn as cash.', 'رصيدك هو رصيد شراء داخل تيراكوتا — لا يمكن سحبه نقدًا.') }}
              </li>
              <li class="flex gap-2">
                <LucideCheck class="mt-0.5 size-4 shrink-0 text-brand-green" />
                {{ t('wallet_rule_refunds', 'Refunds and gifts you receive land here automatically.', 'الاستردادات والهدايا التي تصلك تُضاف هنا تلقائيًا.') }}
              </li>
              <li class="flex gap-2">
                <LucideCheck class="mt-0.5 size-4 shrink-0 text-brand-green" />
                {{ t('wallet_rule_spend', 'Spend it by switching the wallet on at checkout — it covers as much of the total as it can.', 'استخدمه بتفعيل خيار المحفظة عند الدفع — يغطي أكبر قدر ممكن من المبلغ.') }}
              </li>
              <li class="flex gap-2">
                <LucideCheck class="mt-0.5 size-4 shrink-0 text-brand-green" />
                {{ t('wallet_rule_cancel', 'Cancelling a workshop refunds its full price; cancelling a shop order refunds only what the wallet paid.', 'إلغاء الورشة يعيد كامل قيمتها؛ إلغاء طلب المتجر يعيد ما دفعته المحفظة فقط.') }}
              </li>
            </ul>
          </section>
        </div>

        <section class="rounded-2xl border bg-card p-5">
          <h2 class="font-display text-base font-semibold text-foreground">{{ t('transactions', 'Transactions', 'العمليات') }}</h2>

          <div v-if="pending && !transactions.length" class="mt-4 grid gap-3 lg:grid-cols-2" aria-busy="true">
            <AppSkeleton v-for="n in 4" :key="n" class="h-16 w-full" />
          </div>

          <p v-else-if="!transactions.length" class="mt-4 text-sm text-muted-foreground">
            {{ t('no_transactions', 'No transactions yet.', 'لا توجد معاملات بعد') }}
          </p>

          <ul v-else class="mt-4 grid gap-3 lg:grid-cols-2" data-test="wallet-ledger">
            <li v-for="tx in transactions" :key="tx.id" class="flex items-start gap-3 rounded-xl border p-4 text-sm">
              <span class="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust">
                <component :is="walletReasonIcon(tx.reason)" class="size-4" />
              </span>
              <div class="min-w-0 flex-1">
                <span class="block font-medium text-foreground" data-test="wallet-reason">{{ walletReasonLabel(tx.reason, t) }}</span>
                <span class="block text-xs text-muted-foreground">{{ formatDate(tx.created_at) }}</span>
                <span class="mt-0.5 block text-xs text-muted-foreground">
                  {{ t('balance_after', 'Balance after: :amount', 'الرصيد بعدها: :amount', { amount: format(tx.balance_after) }) }}
                </span>
              </div>
              <span
                class="shrink-0 font-medium"
                :class="tx.type === 'credit' ? 'text-brand-green' : 'text-destructive'"
                dir="ltr"
              >{{ tx.type === 'credit' ? '+' : '−' }}{{ format(tx.amount) }}</span>
            </li>
          </ul>

          <!-- Real links, so a page is shareable and crawlable rather than a click handler. -->
          <nav v-if="lastPage > 1" class="mt-6 flex flex-wrap items-center justify-center gap-2">
            <Button v-if="currentPage > 1" as-child size="sm" variant="outline" class="rounded-xl">
              <NuxtLink :to="linkTo(currentPage - 1)" rel="prev">{{ t('previous', 'Previous', 'السابق') }}</NuxtLink>
            </Button>
            <Button
              v-for="number in pageNumbers"
              :key="number"
              as-child
              size="sm"
              :variant="number === currentPage ? 'default' : 'outline'"
              class="min-w-10 rounded-xl"
            >
              <NuxtLink :to="linkTo(number)" :aria-current="number === currentPage ? 'page' : undefined">{{ number }}</NuxtLink>
            </Button>
            <Button v-if="currentPage < lastPage" as-child size="sm" variant="outline" class="rounded-xl">
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
const { t } = useLang('web', 'account')
const { format } = usePrice()
const { formatDate } = useDateFormat()

const currentPage = computed(() => Math.max(1, Number(route.query.page ?? 1)))
const { balance, transactions, lastPage, pending } = useWallet({ page: currentPage, perPage: 10 })

const pageNumbers = computed(() => {
  const from = Math.max(1, currentPage.value - 2)
  const to = Math.min(lastPage.value, currentPage.value + 2)
  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

const linkTo = (page) => ({ query: { ...route.query, page: page > 1 ? page : undefined } })
</script>
