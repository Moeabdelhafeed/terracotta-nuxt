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
      'GET /api/workshops/bookings': envelope({
        data: [
          {
            id: 11, workshop_title: 'Wheel throwing', status: 'attending',
            booking_date: '2026-07-04', start_time: '09:00', end_time: '11:00', checkin_code: 'AB12',
          },
          {
            id: 10, workshop_title: 'Make Your Own Cup', status: 'confirmed',
            booking_date: '2026-07-04', start_time: '13:00', end_time: '15:00',
          },
        ],
        current_page: 1, last_page: 1, total: 2,
      }),
      'GET /api/shop/orders': envelope({ data: [], current_page: 1, last_page: 1, total: 0 }),
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
const HomeLiveStrip = (await import('~/components/home/HomeLiveStrip.vue')).default

describe('HomeLiveStrip', () => {
  // One list answers both rows, the way the app reads it: the session they are sitting in,
  // and the soonest seat still to be sat in. `current_booking` is deliberately unused —
  // it answered only this page, and drew the same booking twice.
  it('separates the session happening now from the next one', async () => {
    const wrapper = await mountSuspended(HomeLiveStrip)
    await flushPromises()

    const live = wrapper.find('[data-test="live-workshop"]')
    expect(live.text()).toContain('Wheel throwing')
    expect(live.text()).toContain('11:00 AM')

    const next = wrapper.find('[data-test="live-next"]')
    expect(next.text()).toContain('Your next workshop')
    expect(next.text()).toContain('Make Your Own Cup')
    expect(next.text()).toContain('1:00 PM')
    expect(next.attributes('href')).toMatch(/\/bookings\/10$/)
  })
})

describe('HomeBooking', () => {
  it('is the greeting and nothing else — the booking row lives in the strip', async () => {
    const wrapper = await mountSuspended(HomeBooking)
    await flushPromises()
    expect(wrapper.text()).not.toContain('Resume your workshop')
    expect(wrapper.text()).not.toContain('Make Your Own Cup')
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


/**
 * A workshop without a photograph falls back to its family's line drawing — per family,
 * not per workshop, exactly as the app does it. Getting the mapping wrong shows a candle
 * beside a throwing session, which no test of the colour alone would catch.
 */
describe('workshopArt', () => {
  it('gives each family its own drawing', async () => {
    const { workshopArt } = await import('~/utils/workshopColour')

    expect(workshopArt({ type: 'make_your_piece' })).toContain('make-your-cup')
    expect(workshopArt({ type: 'paint_your_piece' })).toContain('color-your-cup')
    expect(workshopArt({ type: 'make_your_candle' })).toContain('make-your-wax')
  })

  it('has nothing to draw for a family it does not know', async () => {
    const { workshopArt } = await import('~/utils/workshopColour')

    expect(workshopArt({ type: 'something_new' })).toBeNull()
    expect(workshopArt(undefined)).toBeNull()
  })

  it('prefers the studio\'s own colour over the family default', async () => {
    const { workshopColour } = await import('~/utils/workshopColour')

    expect(workshopColour({ type: 'make_your_piece', color: '#123456' })).toBe('#123456')
    expect(workshopColour({ type: 'make_your_piece' })).toBe('#3A7F6A')
    expect(workshopColour({ type: 'paint_your_piece' })).toBe('#A85724')
    expect(workshopColour({ type: 'make_your_candle' })).toBe('#AE9353')
  })
})

/**
 * The drawings live in dynamic storage so the studio can swap one without a deploy. The
 * key has to be stable per family — change it and the CMS row is orphaned, and the site
 * quietly seeds a second copy under the new name.
 */
describe('workshopArtKey', () => {
  it('names a stable key per family, paired with its seed file', async () => {
    const { workshopArtKey, workshopArt } = await import('~/utils/workshopColour')

    expect(workshopArtKey({ type: 'make_your_piece' })).toBe('art_make_your_piece')
    expect(workshopArtKey({ type: 'paint_your_piece' })).toBe('art_paint_your_piece')
    expect(workshopArtKey({ type: 'make_your_candle' })).toBe('art_make_your_candle')

    // A key with no seed file behind it can never provision itself.
    for (const type of ['make_your_piece', 'paint_your_piece', 'make_your_candle']) {
      expect(workshopArt({ type })).toMatch(/^\/[\w-]+\.png$/)
    }
  })

  it('has no key for a family it does not know', async () => {
    const { workshopArtKey } = await import('~/utils/workshopColour')
    expect(workshopArtKey({ type: 'something_new' })).toBeNull()
  })
})
