// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const { api, lang, sanctum, navigate, server } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  const { vi: v } = await import('vitest')
  // The server owns the badge. Every response — list, read, read-all — reports this one
  // number, so a test can prove the client mirrors it rather than doing its own maths.
  const server = { unread: 3 }
  return {
    server,
    api: createApiMock({
      'GET /api/notifications': () => ({
        ...envelope({
        unread_count: server.unread,
        notifications: [
          { id: 5, type: 'shop_order_out_for_delivery', title: 'Your order is on the way', body: 'Order #12 left the shop.', data: { shop_order_id: 12, type: 'shop_order_out_for_delivery' }, is_read: false, created_at: '2026-08-16T12:00:00+00:00' },
          { id: 4, type: 'workshop_booking_confirmed', title: 'api.notification_booking_confirmed', body: 'Booking confirmed.', data: { workshop_booking_id: 7, type: 'workshop_booking_confirmed' }, is_read: false, created_at: '2026-08-15T12:00:00+00:00' },
          { id: 3, type: 'wallet_credited', title: 'Credit added', body: '50 SAR added.', data: { type: 'wallet_credited' }, is_read: true, created_at: '2026-08-14T12:00:00+00:00' },
        ],
        }),
        // A SIBLING of `data`, counting the whole inbox rather than the slice on screen.
        meta: { filter_counts: { all: 9, unread: 3, bookings: 4, reminders: 0, pieces: 0, orders: 5, gifts: 0, wallet: 1 } },
      }),
      'POST /api/notifications/{id}/read': () => envelope({ unread_count: server.unread }),
      'POST /api/notifications/read-all': () => envelope({ unread_count: (server.unread = 0) }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
    navigate: v.fn(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('navigateTo', () => navigate)

const { notificationRoute, notificationTitle, useNotifications } = await import('~/composables/useNotifications')
const NotificationsPage = (await import('~/pages/notifications.vue')).default

describe('notificationRoute', () => {
  it('routes a shop order and a workshop booking from the deep-link id', () => {
    expect(notificationRoute({ data: { shop_order_id: 12, type: 'shop_order_confirmed' } })).toBe('/orders/12')
    expect(notificationRoute({ data: { workshop_booking_id: 7, type: 'workshop_booking_confirmed' } })).toBe('/bookings/7')
  })

  it('routes gift and wallet types that carry no id, and leaves unknown types unclickable', () => {
    expect(notificationRoute({ data: { type: 'gift_redeemed' } })).toBe('/gifts')
    expect(notificationRoute({ data: { type: 'wallet_credited' } })).toBe('/wallet')
    expect(notificationRoute({ data: { type: 'something_new' } })).toBeNull()
  })
})

describe('notificationTitle', () => {
  it('falls back when the server sent an unseeded api.* key, and passes real titles through', () => {
    expect(notificationTitle({ title: 'api.notification_booking_confirmed' }, lang.t)).toBe('Update from Terracotta')
    expect(notificationTitle({ title: 'Your order is on the way' }, lang.t)).toBe('Your order is on the way')
  })
})

describe('useNotifications', () => {
  it('takes the badge from the response and never decrements it locally', async () => {
    const { unreadCount, markRead, markAllRead } = useNotifications()
    await vi.waitFor(() => expect(unreadCount.value).toBe(3))

    // Row 3 is already read — mark-read is idempotent and the server's count is unchanged.
    // A client that decremented locally would drop to 2 here.
    await markRead(3)
    expect(unreadCount.value).toBe(3)

    // Now the server really does clear one; the badge follows it.
    server.unread = 2
    await markRead(5)
    expect(unreadCount.value).toBe(2)

    await markAllRead()
    expect(unreadCount.value).toBe(0)
  })

  it('sends the category filter, and sends nothing at all for "all"', async () => {
    const filter = ref('bookings')
    useNotifications({ filter })
    await vi.waitFor(() => expect(api.calls.some((c) => c.query?.filter === 'bookings')).toBe(true))

    const everything = ref('all')
    useNotifications({ filter: everything })
    await vi.waitFor(() => expect(api.calls.some((c) => c.query && !('filter' in c.query))).toBe(true))
  })

  it('reads the whole-inbox tallies out of meta rather than counting the loaded page', async () => {
    const { filterCounts, notifications } = useNotifications()
    await vi.waitFor(() => expect(notifications.value.length).toBe(3))
    expect(filterCounts.value.orders).toBe(5)
  })

  it('sends unread_only=1 only when the filter is on', async () => {
    const unreadOnly = ref(true)
    useNotifications({ unreadOnly })
    await vi.waitFor(() => expect(api.calls.some((c) => c.query?.unread_only === 1)).toBe(true))
  })
})

describe('/notifications page', () => {
  const mount = () => mountSuspended(NotificationsPage, {
    global: { stubs: { AppSkeleton: true, NuxtLink: { template: '<a><slot /></a>' } } },
  })

  it('marks a notification read and then routes to its deep link', async () => {
    navigate.mockClear()
    const page = await mount()
    await vi.waitFor(() => expect(page.findAll('li').length).toBe(3))

    await page.findAll('li')[0].find('button').trigger('click')
    await vi.waitFor(() => expect(navigate).toHaveBeenCalledWith('/orders/12'))
    expect(api.calls.some((c) => c.method === 'POST' && c.url === '/api/notifications/5/read')).toBe(true)

    navigate.mockClear()
    await page.findAll('li')[1].find('button').trigger('click')
    await vi.waitFor(() => expect(navigate).toHaveBeenCalledWith('/bookings/7'))
  })

  it('renders the api.* fallback title rather than the raw key', async () => {
    const page = await mount()
    await vi.waitFor(() => expect(page.text()).toContain('Update from Terracotta'))
    expect(page.text()).not.toContain('api.notification_booking_confirmed')
  })

  it('labels each tab from the whole inbox and leaves out the categories with nothing in them', async () => {
    const page = await mount()
    await vi.waitFor(() => expect(page.find('[data-test="filter-bookings"]').exists()).toBe(true))

    expect(page.find('[data-test="filter-bookings"]').text()).toContain('4')
    expect(page.find('[data-test="filter-orders"]').text()).toContain('5')
    expect(page.find('[data-test="filter-wallet"]').exists()).toBe(true)

    // Nothing behind them, so a chip for either only asks the reader to work out which apply.
    expect(page.find('[data-test="filter-reminders"]').exists()).toBe(false)
    expect(page.find('[data-test="filter-pieces"]').exists()).toBe(false)
  })

  it('offers mark-all-read but no delete control — the API has no delete route', async () => {
    const page = await mount()
    await vi.waitFor(() => expect(page.find('[data-test="mark-all"]').exists()).toBe(true))
    expect(page.html()).not.toMatch(/LucideTrash|data-test="delete/)
  })
})
