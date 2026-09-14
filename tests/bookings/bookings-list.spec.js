// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const booking = (over = {}) => ({
  id: 1,
  workshop_title: 'Make Your Own Cup',
  workshop_image: null,
  status: 'confirmed',
  people_count: 2,
  booking_date: '2026-07-04',
  start_time: '10:00',
  end_time: '11:00',
  total_price: '70.00',
  has_celebration: false,
  ...over,
})

const { api, lang, routeQuery } = await vi.hoisted(async () => {
  const { createApiMock, createLang } = await import('../helpers/mockApi')
  const query = { value: {} }
  return {
    routeQuery: query,
    lang: createLang('en'),
    api: createApiMock({
      'GET /api/workshops/bookings': () => ({
        success: true,
        message: 'ok',
        errors: null,
        data: { data: globalThis.__bookings, current_page: 1, last_page: 1, total: 1 },
        meta: { status_counts: globalThis.__counts },
      }),
    }),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useRoute', () => () => ({ path: '/bookings', params: {}, query: routeQuery.value }))

const BookingsPage = (await import('~/pages/bookings/index.vue')).default
const WorkshopAudienceBadge = (await import('~/components/workshop/WorkshopAudienceBadge.vue')).default

const mount = (query = {}) => {
  routeQuery.value = query
  return mountSuspended(BookingsPage, {
    global: { stubs: { PageBar: true, AppSkeleton: true, BookingCard: true, NuxtLink: { template: '<a><slot /></a>' } } },
  })
}

const lastQuery = () => api.calls.at(-1).query
const statuses = (page) => page.findAll('[data-status]').map((el) => el.attributes('data-status'))

beforeEach(() => {
  globalThis.__bookings = [booking()]
  globalThis.__counts = { all: 5, pending_payment: 0, confirmed: 2, attending: 0, preparing: 0, completed: 3, absent: 0, cancelled: 0 }
  api.calls.length = 0
})

/** The page pushes through the real router; spying on it reads the URL it asks for. */
const spyOnPush = (page) => vi.spyOn(page.vm.$router, 'push').mockImplementation(() => {})

describe('/bookings filters', () => {
  it('asks for no status or sort when the URL carries none — the API default is newest', async () => {
    await mount()
    await flushPromises()
    expect(lastQuery()).toMatchObject({ page: 1, per_page: 10 })
    expect(lastQuery().status).toBeUndefined()
    expect(lastQuery().sort).toBeUndefined()
  })

  it('sends the status and sort from the URL', async () => {
    await mount({ status: 'completed', sort: 'oldest', page: '2' })
    await flushPromises()
    expect(lastQuery()).toMatchObject({ status: 'completed', sort: 'oldest', page: 2 })
  })

  it('ignores a status or sort the API would reject', async () => {
    await mount({ status: 'nonsense', sort: 'cheapest' })
    await flushPromises()
    expect(lastQuery().status).toBeUndefined()
    expect(lastQuery().sort).toBeUndefined()
  })

  it('renders a tab per non-empty status, with its whole-history count', async () => {
    const page = await mount()
    await flushPromises()
    expect(statuses(page)).toEqual(['all', 'confirmed', 'completed'])
    expect(page.find('[data-status="completed"]').text()).toContain('3')
    expect(page.find('[data-status="all"]').text()).toContain('5')
  })

  it('keeps the active tab even once its count is zero', async () => {
    const page = await mount({ status: 'absent' })
    await flushPromises()
    expect(statuses(page)).toContain('absent')
  })

  it('a tab pushes the status into the URL and starts again at page one', async () => {
    const page = await mount({ page: '3' })
    await flushPromises()
    const push = spyOnPush(page)
    await page.find('[data-status="completed"]').trigger('click')
    expect(push).toHaveBeenCalledWith({ query: { status: 'completed' } })
  })

  it('the "all" tab clears the status rather than sending it', async () => {
    const page = await mount({ status: 'completed' })
    await flushPromises()
    const push = spyOnPush(page)
    await page.find('[data-status="all"]').trigger('click')
    expect(push).toHaveBeenCalledWith({ query: {} })
  })

  it('the sort control reflects the URL and pushes a change, dropping the default', async () => {
    const page = await mount({ sort: 'session_soonest' })
    await flushPromises()
    const select = page.find('[data-test="sort-select"]')
    expect(select.element.value).toBe('session_soonest')

    const push = spyOnPush(page)
    await select.setValue('newest')
    expect(push).toHaveBeenCalledWith({ query: {} })
  })
})

describe('WorkshopAudienceBadge', () => {
  it('names the audience a customer could be turned away by', async () => {
    const badge = await mountSuspended(WorkshopAudienceBadge, { props: { audience: 'women_only' } })
    expect(badge.text()).toContain('Women only')
  })

  it('renders nothing for mixed — the default rules nobody out', async () => {
    const badge = await mountSuspended(WorkshopAudienceBadge, { props: { audience: 'mixed' } })
    expect(badge.find('[data-audience]').exists()).toBe(false)
  })
})
