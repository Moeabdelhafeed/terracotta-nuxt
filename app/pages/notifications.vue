<template>
  <main class="bg-background">
    <PageBar :crumbs="crumbs" />
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-5">
        <h1 class="font-display text-3xl font-semibold sm:text-4xl">
          {{ t('notifications_title', 'Notifications', 'الإشعارات') }}
        </h1>

        <div class="flex flex-wrap items-center justify-between gap-3">
          <!-- The SERVER filters and the SERVER counts: `meta.filter_counts` is the whole
               inbox, so a tab carries a number before anyone opens it. A tab with nothing
               behind it is left off, except the one currently chosen — hiding that would
               take the way back with it. -->
          <div class="flex flex-wrap gap-2" data-test="notification-filters">
            <Button
              v-for="tab in tabs"
              :key="tab"
              as-child
              size="sm"
              class="rounded-xl"
              :variant="tab === filter ? 'default' : 'outline'"
            >
              <NuxtLink :to="linkTo(1, tab)" :data-test="`filter-${tab}`">
                {{ filterLabel(tab) }}
                <span v-if="countFor(tab)" class="ms-1 rounded-full bg-brand-blush px-1.5 text-[10px] font-semibold text-brand-ink" dir="ltr">{{ countFor(tab) }}</span>
              </NuxtLink>
            </Button>
          </div>
          <button
            type="button"
            class="text-sm font-medium text-brand-terracotta underline-offset-4 hover:underline disabled:opacity-50 disabled:no-underline"
            :disabled="markingAll || unreadCount === 0"
            data-test="mark-all"
            @click="onMarkAll"
          >
            {{ markingAll ? t('working', 'Working...', 'لحظة...') : t('notifications_mark_all_read', 'Mark all as read', 'تحديد الكل كمقروء') }}
          </button>
        </div>

        <AppLoadError v-if="error" :error="error" :retry="refresh" />

        <div v-else-if="pending && !notifications.length" class="grid gap-3 lg:grid-cols-2" aria-busy="true">
          <AppSkeleton v-for="n in 4" :key="n" class="h-20 w-full !rounded-2xl" />
        </div>

        <div v-else-if="!notifications.length" class="mx-auto flex w-full max-w-xl flex-col items-center gap-3 rounded-2xl border bg-card p-10 text-center">
          <span class="flex size-12 items-center justify-center rounded-full bg-brand-terracotta/10 text-brand-terracotta">
            <LucideBellOff class="size-5" />
          </span>
          <h2 class="font-display text-lg font-semibold text-foreground">
            {{ emptyTitle }}
          </h2>
          <p class="text-sm text-muted-foreground">
            {{ t('notifications_none_note', 'Order and workshop updates will show up here.', 'ستظهر هنا تحديثات طلباتك وورشاتك.') }}
          </p>
        </div>

        <ul v-else class="grid gap-3 lg:grid-cols-2" data-test="notification-list">
          <li v-for="n in notifications" :key="n.id">
            <button
              type="button"
              class="group flex h-full w-full items-start gap-3 rounded-2xl border bg-card p-4 text-start transition-colors hover:bg-brand-mist/40"
              :class="n.is_read ? '' : 'border-brand-terracotta/30 bg-brand-mist/30'"
              :aria-label="notificationTitle(n, t)"
              @click="open(n)"
            >
              <span
                class="mt-1 flex size-9 shrink-0 items-center justify-center rounded-xl"
                :class="n.is_read ? 'bg-brand-mist/70 text-foreground/60' : 'bg-brand-terracotta text-white'"
              >
                <component :is="iconFor(n)" class="size-4" />
              </span>
              <span class="min-w-0 flex-1">
                <span class="flex items-center gap-2">
                  <span class="truncate text-sm text-foreground" :class="n.is_read ? 'font-medium' : 'font-semibold'">{{ notificationTitle(n, t) }}</span>
                  <span v-if="!n.is_read" class="size-2 shrink-0 rounded-full bg-brand-terracotta" aria-hidden="true" />
                </span>
                <span class="mt-0.5 block text-sm break-words text-muted-foreground">{{ n.body }}</span>
                <time class="mt-1 block text-xs text-muted-foreground" :datetime="n.created_at" :title="formatDate(n.created_at)">{{ relative(n.created_at) }}</time>
              </span>
              <LucideChevronRight v-if="notificationRoute(n)" class="mt-1 size-4 shrink-0 text-muted-foreground rtl:-scale-x-100 group-hover:text-foreground" />
            </button>
          </li>
        </ul>

        <nav v-if="lastPage > 1" class="mt-12 flex flex-wrap items-center justify-center gap-2">
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

        <p v-if="total" class="mt-6 text-center text-sm text-muted-foreground">
          {{ t('notifications_count', ':total notifications', ':total إشعار', { total }) }}
        </p>
      </div>
    </div>
  </main>
</template>

<script setup>
import { Bell, CalendarDays, Gift, ShoppingBag, Wallet } from 'lucide-vue-next'
definePageMeta({
  // Entered from somewhere, with its own way back in the header — the site's
  middleware: ['auth-mode', 'require-registered'],
  name: 'notifications',
})

const route = useRoute()
const { t, code } = useLang('web', 'account')

// Reached from the profile, so the trail says so — and PageBar's arrow follows it.
const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/profile', label: t('nav_profile', 'Profile', 'حسابي', { subGroup: 'general' }) },
  { label: t('notifications_title', 'Notifications', 'الإشعارات') },
])
const { formatDate } = useDateFormat()
const toast = useToast()

const currentPage = computed(() => Math.max(1, Number(route.query.page ?? 1)))

// `?unread=1` was the only slice this page had; it still lands on the unread tab.
const filter = computed(() => {
  const asked = String(route.query.filter ?? (route.query.unread === '1' ? 'unread' : 'all'))
  return NOTIFICATION_FILTERS.includes(asked) ? asked : 'all'
})

const { notifications, unreadCount, filterCounts, lastPage, total, pending, error, markRead, markAllRead, refresh } = useNotifications({ page: currentPage, filter })

const linkTo = (page, slice = filter.value) => ({
  query: { page: page > 1 ? page : undefined, filter: slice === 'all' ? undefined : slice },
})

const FILTER_LABELS = {
  all: ['All', 'الكل'],
  unread: ['Unread', 'غير المقروءة'],
  bookings: ['Bookings', 'الحجوزات'],
  reminders: ['Reminders', 'التذكيرات'],
  pieces: ['Pieces', 'القطع'],
  orders: ['Orders', 'الطلبات'],
  gifts: ['Gifts', 'الهدايا'],
  wallet: ['Wallet', 'المحفظة'],
}
const filterLabel = (slice) => t(`notifications_filter_${slice}`, ...FILTER_LABELS[slice])

// The unread tally rides on every response, so it is right even on an older server that
// sends no `filter_counts` at all.
const countFor = (slice) => {
  if (slice === 'all') return 0
  if (slice === 'unread') return unreadCount.value
  return filterCounts.value?.[slice] ?? 0
}

/**
 * With no counts — an older server, or the first load — every tab shows and none carries
 * a number. Offering a tab that turns out to be empty is better than hiding them all,
 * because an empty tab says so when it is opened.
 */
const tabs = computed(() => NOTIFICATION_FILTERS.filter((slice) => (
  slice === 'all' || slice === filter.value || !filterCounts.value || countFor(slice) > 0
)))

const emptyTitle = computed(() => {
  if (filter.value === 'unread') return t('notifications_none_unread', 'You are all caught up', 'لا توجد إشعارات غير مقروءة')
  if (filter.value !== 'all') return t('notifications_none_in_filter', 'Nothing in this filter', 'لا يوجد شيء في هذا التصنيف')
  return t('notifications_none', 'No notifications yet', 'لا توجد إشعارات بعد')
})

const pageNumbers = computed(() => {
  const from = Math.max(1, currentPage.value - 2)
  const to = Math.min(lastPage.value, currentPage.value + 2)
  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

/**
 * The component itself, not its name. `nuxt-lucide-icons` registers each icon as an
 * auto-import, which Nuxt resolves by rewriting the NAME where it appears literally in a
 * template or in `resolveComponent('LucideX')`. A name held in a variable is never
 * rewritten, so the icon is never bundled and `<component :is>` silently renders nothing.
 */
const iconFor = (n) => {
  const type = String(n.data?.type ?? n.type ?? '')
  if (type.startsWith('shop_order')) return ShoppingBag
  if (type.startsWith('workshop_')) return CalendarDays
  if (type.startsWith('gift_')) return Gift
  if (type.startsWith('wallet_')) return Wallet
  return Bell
}

// "3 hours ago" for anything inside the last week, the full date after that.
const relative = (value) => {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const seconds = Math.round((date.getTime() - Date.now()) / 1000)
  const abs = Math.abs(seconds)
  if (abs > 7 * 86400) return formatDate(value)
  const rtf = new Intl.RelativeTimeFormat(code.value, { numeric: 'auto' })
  if (abs < 60) return rtf.format(seconds, 'second')
  if (abs < 3600) return rtf.format(Math.round(seconds / 60), 'minute')
  if (abs < 86400) return rtf.format(Math.round(seconds / 3600), 'hour')
  return rtf.format(Math.round(seconds / 86400), 'day')
}

const open = async (n) => {
  const target = notificationRoute(n)
  if (!n.is_read) {
    try {
      await markRead(n.id)
    } catch {
      // Someone else's or a vanished notification — the list refresh is the answer.
      await refresh()
    }
  }
  if (target) navigateTo(target)
}

const markingAll = ref(false)
const onMarkAll = async () => {
  markingAll.value = true
  try {
    await markAllRead()
    toast.success(t('notifications_all_read', 'All notifications marked as read.', 'تم تحديد كل الإشعارات كمقروءة.'))
  } catch (e) {
    toast.error(normalizeApiError(e).message)
  } finally {
    markingAll.value = false
  }
}
</script>
