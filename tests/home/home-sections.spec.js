// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang, sanctum } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/home': envelope({
        banners: [],
        categories: [],
        current_booking: {
          id: 10,
          workshop_id: 3,
          workshop_title: 'Make Your Own Cup',
          booking_date: '2026-07-04',
          start_time: '13:00',
          end_time: '15:00',
          people_count: 2,
          has_celebration: true,
          total_price: '95.00',
          status: 'confirmed',
        },
        featured_products: [],
        offers: [],
      }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState({ id: 1, name: 'Sara', is_guest: false }),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)

const HomeBooking = (await import('~/components/home/HomeBooking.vue')).default
const HomeIntro = (await import('~/components/home/HomeIntro.vue')).default

describe('HomeBooking', () => {
  it('shows the nearest booking with the API\'s own studio-time strings', async () => {
    const wrapper = await mountSuspended(HomeBooking)
    await flushPromises()
    const text = wrapper.text()

    // Neither the date nor the times may be re-derived through `new Date()` in the
    // viewer's zone — 13:00 in Riyadh is 13:00 on the card, wherever the browser is.
    expect(text).toContain('13:00')
    expect(text).toContain('15:00')
    expect(text).toContain('2 people')
    expect(text).toContain('Make Your Own Cup')
    expect(text).toContain('with a celebration')
    expect(text).toContain('95 SAR')
    expect(text).toContain('Confirmed')
    expect(text).toContain('Resume your workshop')

    expect(wrapper.find('a').attributes('href')).toBe('/bookings/10')
  })

  it('greets the signed-in visitor by the hour on their own clock', async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 6, 4, 8, 0, 0))
    const morning = await mountSuspended(HomeBooking)
    await flushPromises()
    expect(morning.text()).toContain('Good morning, Sara')

    vi.setSystemTime(new Date(2026, 6, 4, 19, 0, 0))
    const evening = await mountSuspended(HomeBooking)
    await flushPromises()
    expect(evening.text()).toContain('Good evening, Sara')
    vi.useRealTimers()
  })
})

describe('HomeIntro', () => {
  // The Nuxt test environment hands over a `localStorage` that is not a real Storage, so
  // the flag is backed by a plain map for the duration of these tests.
  beforeEach(() => {
    const store = new Map()
    vi.stubGlobal('localStorage', {
      getItem: (key) => store.get(key) ?? null,
      setItem: (key, value) => store.set(key, String(value)),
      removeItem: (key) => store.delete(key),
    })
  })

  it('shows the three lines on a first visit and never again once dismissed', async () => {
    const first = await mountSuspended(HomeIntro)
    await flushPromises()
    expect(first.findAll('li')).toHaveLength(3)
    expect(first.text()).toContain('Shape your own piece')
    expect(first.text()).toContain('The workshop experience')
    expect(first.text()).toContain('Follow your order step by step')

    await first.find('button').trigger('click')
    expect(first.findAll('li')).toHaveLength(0)

    const second = await mountSuspended(HomeIntro)
    await flushPromises()
    expect(second.findAll('li')).toHaveLength(0)
  })
})
