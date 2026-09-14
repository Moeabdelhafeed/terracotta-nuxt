/**
 * The notification inbox: `GET /api/notifications`, `POST /api/notifications/{id}/read`,
 * `POST /api/notifications/read-all`. There is no delete route and no separate unread
 * count — `unread_count` rides on every response and is always the whole-inbox total.
 *
 * `title`/`body` arrive already translated for the user's language; render them as-is.
 */
const unreadCount = ref(0)

/** Which website route a notification's `data` points at. `null` = not clickable. */
export const notificationRoute = (notification) => {
  const data = notification?.data ?? {}
  if (data.workshop_booking_id) return `/bookings/${data.workshop_booking_id}`
  if (data.shop_order_id) return `/orders/${data.shop_order_id}`
  const type = String(data.type ?? notification?.type ?? '')
  if (type.startsWith('gift_')) return '/gifts'
  if (type.startsWith('wallet_')) return '/wallet'
  return null
}

/** A title that is still an `api.*` key had no template seeded — fall back to something readable. */
export const notificationTitle = (notification, t) => {
  const title = notification?.title ?? ''
  if (!title.startsWith('api.')) return title
  return t('notification_fallback_title', 'Update from Terracotta', 'تحديث من تيراكوتا')
}

export const useNotifications = ({ page = ref(1), perPage = 20, unreadOnly = ref(false) } = {}) => {
  const api = useApi()
  const { user } = useSanctumAuth()
  const isRegistered = computed(() => !!user.value && !(user.value?.data?.is_guest ?? user.value?.is_guest))

  const query = computed(() => ({
    page: toValue(page),
    per_page: perPage,
    ...(toValue(unreadOnly) ? { unread_only: 1 } : {}),
  }))

  const { data, pending, error, refresh } = useApiFetch('/api/notifications', {
    key: 'notifications',
    query,
    immediate: isRegistered.value,
    transform: (res) => {
      const payload = res?.data ?? {}
      return { unread: payload.unread_count ?? 0, ...unwrapList(payload.notifications) }
    },
    default: () => ({ unread: 0, items: [], page: 1, lastPage: 1, total: 0 }),
  })

  watch(data, (value) => { if (value) unreadCount.value = value.unread ?? 0 }, { immediate: true })

  const markRead = async (id) => {
    const res = await api(`/api/notifications/${id}/read`, { method: 'POST' })
    unreadCount.value = res?.data?.unread_count ?? unreadCount.value
    await refresh()
  }

  const markAllRead = async () => {
    const res = await api('/api/notifications/read-all', { method: 'POST' })
    unreadCount.value = res?.data?.unread_count ?? 0
    await refresh()
  }

  return {
    notifications: computed(() => asList(data.value?.items)),
    unreadCount,
    lastPage: computed(() => data.value?.lastPage ?? 1),
    total: computed(() => data.value?.total ?? 0),
    pending,
    error,
    refresh,
    markRead,
    markAllRead,
    isRegistered,
  }
}

/**
 * Badge-only polling for the nav bell. Opt-in: only a registered user has an inbox, and
 * the request is one cheap page. Polls every `interval` ms while the tab is visible.
 */
export const useUnreadCount = (interval = 60000) => {
  const api = useApi()
  const { user } = useSanctumAuth()
  const isRegistered = computed(() => !!user.value && !(user.value?.data?.is_guest ?? user.value?.is_guest))

  const poll = async () => {
    if (!isRegistered.value || (import.meta.client && document.hidden)) return
    try {
      const res = await api('/api/notifications', { query: { per_page: 1 } })
      unreadCount.value = res?.data?.unread_count ?? 0
    } catch {
      // A failed poll just keeps the last badge.
    }
  }

  if (import.meta.client) {
    const { pause, resume } = useIntervalFn(poll, interval, { immediate: false })
    watch(isRegistered, (registered) => {
      if (registered) { poll(); resume() } else { pause(); unreadCount.value = 0 }
    }, { immediate: true })
  }

  return { unreadCount, poll, isRegistered }
}
