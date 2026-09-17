<template>
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-5">
        <div class="flex items-center justify-between">
          <NuxtLink
            to="/shop"
            class="flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground -ms-2 rtl:-scale-x-100"
            :aria-label="t('back_to_shop', 'Back to the shop', 'عودة للمتجر')"
          >
            <LucideArrowLeft class="size-5" />
          </NuxtLink>
          <h1 class="font-display text-lg font-semibold text-foreground">{{ t('orders_title', 'My orders', 'طلباتي') }}</h1>
          <span class="size-10" />
        </div>

        <AppLoadError v-if="error" :error="error" :retry="refresh" />

        <ul v-else-if="pending && !items.length" class="grid gap-3 lg:grid-cols-2" aria-busy="true">
          <AppSkeleton v-for="n in 3" :key="n" class="h-28 w-full rounded-2xl!" />
        </ul>

        <div v-else-if="!items.length" class="mx-auto w-full max-w-xl rounded-2xl border bg-card p-8 text-center">
          <span class="mx-auto flex size-14 items-center justify-center rounded-2xl bg-brand-rust/10 text-brand-rust">
            <LucidePackage class="size-6" />
          </span>
          <p class="mt-4 font-display text-lg font-semibold">{{ t('orders_empty_title', 'No orders yet', 'لا توجد طلبات بعد') }}</p>
          <p class="mt-2 text-sm text-muted-foreground">{{ t('orders_empty_body', 'Your orders will appear here once you place one.', 'ستظهر طلباتك هنا بعد أول طلب.') }}</p>
          <Button as-child class="mt-6 h-12 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90">
            <NuxtLink to="/shop">{{ t('browse_shop', 'Browse the shop', 'تصفح المتجر', { subGroup: 'shop' }) }}</NuxtLink>
          </Button>
        </div>

        <ul v-else class="grid gap-3 lg:grid-cols-2">
          <li v-for="order in items" :key="order.id">
            <NuxtLink :to="`/orders/${order.id}`" class="block h-full rounded-2xl border bg-card p-5 transition-colors hover:bg-brand-mist/40">
              <div class="flex items-center justify-between gap-3">
                <span class="font-display text-base font-semibold text-foreground">
                  {{ t('order_number', 'Order #:id', 'الطلب رقم :id', { id: order.id }) }}
                </span>
                <ShopOrderStatusBadge :status="order.status" />
              </div>

              <p class="mt-1 text-xs text-muted-foreground">{{ formatDate(order.created_at) }}</p>

              <div class="mt-4 flex items-end justify-between gap-3">
                <span class="text-sm text-muted-foreground">
                  {{ t('order_item_count', ':n pieces', ':n قطعة', { n: itemCount(order) }) }}
                </span>
                <span class="font-display text-lg font-black text-primary">{{ format(order.total_price) }}</span>
              </div>

              <p v-if="order.status === 'awaiting_payment'" class="mt-3 rounded-xl bg-brand-blush/40 px-3 py-2 text-xs font-medium text-brand-rust">
                {{ t('order_awaiting_note', 'Waiting for payment — open it to pay or cancel.', 'بانتظار الدفع — افتحه للدفع أو الإلغاء.') }}
              </p>
            </NuxtLink>
          </li>
        </ul>

        <!-- Real links, so a page is shareable and the back button walks it. -->
        <nav v-if="lastPage > 1" class="mt-2 flex flex-wrap items-center justify-center gap-2">
          <Button v-if="currentPage > 1" as-child size="sm" variant="outline" class="rounded-xl">
            <NuxtLink :to="linkTo(currentPage - 1)" rel="prev">{{ t('previous', 'Previous', 'السابق', { subGroup: 'general' }) }}</NuxtLink>
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
            <NuxtLink :to="linkTo(currentPage + 1)" rel="next">{{ t('next', 'Next', 'التالي', { subGroup: 'general' }) }}</NuxtLink>
          </Button>
        </nav>
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'orders',
})

/** Order history, newest first. The list payload already carries the items, so the card
 *  can show a count without a second call. */
const route = useRoute()
const { t } = useLang('web', 'shop')
const { format } = usePrice()
const { formatDate } = useDateFormat()

const PER_PAGE = 10
const currentPage = computed(() => Math.max(1, Number(route.query.page ?? 1)))

const { items, lastPage, pending, error, refresh } = useOrders({ page: currentPage, perPage: PER_PAGE })

const itemCount = (order) => (order.items ?? []).reduce((sum, item) => sum + (item.quantity ?? 0), 0)

const pageNumbers = computed(() => {
  const span = 2
  const from = Math.max(1, currentPage.value - span)
  const to = Math.min(lastPage.value, currentPage.value + span)
  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

const linkTo = (page) => ({ query: { ...route.query, page: page > 1 ? page : undefined } })

useSeoMeta({ title: () => t('orders_title', 'My orders', 'طلباتي'), robots: 'noindex' })
</script>
