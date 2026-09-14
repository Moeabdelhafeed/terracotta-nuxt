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
          <h1 class="font-display text-lg font-semibold text-foreground">{{ t('notifications_title', 'Notifications', 'الإشعارات') }}</h1>
          <span class="size-10" />
        </div>

        <div class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex flex-wrap gap-2">
            <Button as-child size="sm" class="rounded-xl" :variant="unreadOnly ? 'outline' : 'default'">
              <NuxtLink :to="linkTo(1, false)">{{ t('notifications_all', 'All', 'الكل') }}</NuxtLink>
            </Button>
            <Button as-child size="sm" class="rounded-xl" :variant="unreadOnly ? 'default' : 'outline'">
              <NuxtLink :to="linkTo(1, true)">
                {{ t('notifications_unread_only', 'Unread only', 'غير المقروءة فقط') }}
                <span v-if="unreadCount > 0" class="ms-1 rounded-full bg-brand-blush px-1.5 text-[10px] font-semibold text-brand-ink" dir="ltr">{{ unreadCount }}</span>
              </NuxtLink>
            </Button>
          </div>
          <button
            type="button"
            class="text-sm font-medium text-brand-rust underline-offset-4 hover:underline disabled:opacity-50 disabled:no-underline"
            :disabled="markingAll || unreadCount === 0"
            data-test="mark-all"
            @click="onMarkAll"
          >
            {{ markingAll ? t('working', 'Working...', 'لحظة...') : t('notifications_mark_all_read', 'Mark all as read', 'تحديد الكل كمقروء') }}
          </button>
        </div>

        <div v-if="pending && !notifications.length" class="grid gap-3 lg:grid-cols-2" aria-busy="true">
          <AppSkeleton v-for="n in 4" :key="n" class="h-20 w-full !rounded-2xl" />
        </div>

        <div v-else-if="!notifications.length" class="mx-auto flex w-full max-w-xl flex-col items-center gap-3 rounded-2xl border bg-card p-10 text-center">
          <span class="flex size-12 items-center justify-center rounded-full bg-brand-rust/10 text-brand-rust">
            <LucideBellOff class="size-5" />
          </span>
          <h2 class="font-display text-lg font-semibold text-foreground">
            {{ unreadOnly ? t('notifications_none_unread', 'You are all caught up', 'لا توجد إشعارات غير مقروءة') : t('notifications_none', 'No notifications yet', 'لا توجد إشعارات بعد') }}
          </h2>
          <p class="text-sm text-muted-foreground">
            {{ t('notifications_none_note', 'Order and workshop updates will show up here.', 'ستظهر هنا تحديثات طلباتك وورشاتك.') }}
          </p>
        </div>

        <ul v-else class="grid gap-3 lg:grid-cols-2">
          <li v-for="n in notifications" :key="n.id">
            <button
              type="button"
              class="group flex h-full w-full items-start gap-3 rounded-2xl border bg-card p-4 text-start transition-colors hover:bg-brand-mist/40"
              :class="n.is_read ? '' : 'border-brand-rust/30 bg-brand-mist/30'"
              :aria-label="notificationTitle(n, t)"
              @click="open(n)"
            >
              <span
                class="mt-1 flex size-9 shrink-0 items-center justify-center rounded-xl"
                :class="n.is_read ? 'bg-brand-mist/70 text-foreground/60' : 'bg-brand-rust text-white'"
              >
                <component :is="iconFor(n)" class="size-4" />
              </span>
              <span class="min-w-0 flex-1">
                <span class="flex items-center gap-2">
                  <span class="truncate text-sm text-foreground" :class="n.is_read ? 'font-medium' : 'font-semibold'">{{ notificationTitle(n, t) }}</span>
                  <span v-if="!n.is_read" class="size-2 shrink-0 rounded-full bg-brand-rust" aria-hidden="true" />
                </span>
                <span class="mt-0.5 block text-sm break-words text-muted-foreground">{{ n.body }}</span>
                <time class="mt-1 block text-xs text-muted-foreground" :datetime="n.created_at" :title="formatDate(n.created_at)">{{ relative(n.created_at) }}</time>
              </span>
              <LucideChevronRight v-if="notificationRoute(n)" class="mt-1 size-4 shrink-0 text-muted-foreground rtl:-scale-x-100 group-hover:text-foreground" />
            </button>
          </li>
        </ul>

        <nav v-if="lastPage > 1" class="flex flex-wrap items-center justify-center gap-2">
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
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered'],
  name: 'notifications',
})

const route = useRoute()
const { t, code } = useLang('web', 'account')
const { formatDate } = useDateFormat()
const toast = useToast()

const currentPage = computed(() => Math.max(1, Number(route.query.page ?? 1)))
const unreadOnly = computed(() => route.query.unread === '1')

const { notifications, unreadCount, lastPage, pending, markRead, markAllRead, refresh } = useNotifications({ page: currentPage, unreadOnly })

const linkTo = (page, unread = unreadOnly.value) => ({
  query: { page: page > 1 ? page : undefined, unread: unread ? '1' : undefined },
})

const pageNumbers = computed(() => {
  const from = Math.max(1, currentPage.value - 2)
  const to = Math.min(lastPage.value, currentPage.value + 2)
  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

// Lucide icons are globally registered by nuxt-lucide-icons, so `:is` resolves the name.
const iconFor = (n) => {
  const type = String(n.data?.type ?? n.type ?? '')
  if (type.startsWith('shop_order')) return 'LucideShoppingBag'
  if (type.startsWith('workshop_')) return 'LucideCalendarDays'
  if (type.startsWith('gift_')) return 'LucideGift'
  if (type.startsWith('wallet_')) return 'LucideWallet'
  return 'LucideBell'
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
