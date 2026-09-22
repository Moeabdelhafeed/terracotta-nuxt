// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    lang: createLang('en'),
    api: createApiMock({
      // The booking payload carries no type and no colour: the catalogue answers both.
      'GET /api/workshops': envelope([
        { id: 3, title: 'Wheel throwing', type: 'make_your_piece', color: '#3A7F6A' },
      ]),
      'GET /api/media': envelope({ group: 'web', media: {} }),
    }),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)

const BookingCard = (await import('~/components/booking/BookingCard.vue')).default

const booking = (over = {}) => ({
  id: 7,
  workshop_id: 3,
  workshop_title: 'Wheel throwing',
  workshop_image: null,
  status: 'confirmed',
  people_count: 2,
  booking_date: '2026-07-04',
  start_time: '13:00',
  end_time: '15:00',
  total_price: '190.00',
  has_celebration: false,
  ...over,
})

const mount = (over) =>
  mountSuspended(BookingCard, {
    props: { booking: booking(over) },
    global: { stubs: { NuxtLink: { template: '<a><slot /></a>' } } },
  })

describe('BookingCard', () => {
  it('takes the band from the catalogue, matched on workshop_id', async () => {
    const card = await mount()
    await flushPromises()
    expect(card.find('a').attributes('style')).toContain('#3A7F6A')
  })

  it('bands the lifecycle across the foot of the well', async () => {
    const card = await mount()
    await flushPromises()
    const band = card.find('[data-state]')
    expect(band.text()).toBe('Confirmed')
    expect(band.classes()).toContain('bg-success')
  })

  // The chip's colour is the one thing on the card that is not the workshop's own.
  it('a cancelled booking reads as cancelled whatever family it belongs to', async () => {
    const card = await mount({ status: 'cancelled' })
    await flushPromises()
    expect(card.find('[data-state]').classes()).toContain('bg-destructive')
  })

  it('marks a party across the head of the well', async () => {
    const plain = await mount()
    expect(plain.text()).not.toContain('with a celebration')

    const party = await mount({ has_celebration: true })
    expect(party.text()).toContain('with a celebration')
  })
})
