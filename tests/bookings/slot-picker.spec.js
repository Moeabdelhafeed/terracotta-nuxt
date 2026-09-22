// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Riyadh' }).format(new Date())
const plusDays = (n) => {
  const [y, m, d] = today.split('-').map(Number)
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10)
}

const api = await vi.hoisted(async () => {
  const { createApiMock, envelope } = await import('../helpers/mockApi')
  const start = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Riyadh' }).format(new Date())
  const day = (n) => {
    const [y, m, d] = start.split('-').map(Number)
    return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10)
  }
  return createApiMock({
    // One route, two modes: `date` present switches to the day's slots.
    'GET /api/workshops/1/availability': (opts) => {
      const query = opts.query ?? {}
      if (query.date) {
        return envelope([
          { workshop_slot_id: 13, start_time: '10:00', end_time: '11:00', capacity: 8, booked: 2, remaining: 6, is_full: false, has_conflict: false },
          { workshop_slot_id: 14, start_time: '13:00', end_time: '14:00', capacity: 8, booked: 7, remaining: 1, is_full: true, has_conflict: false },
          { workshop_slot_id: 15, start_time: '16:00', end_time: '17:00', capacity: 8, booked: 0, remaining: 8, is_full: false, has_conflict: true },
        ])
      }
      // The blocked set is relative to the party size: three people fit on fewer days.
      return envelope(Number(query.people_count) > 1
        ? { max_available_seats: 4, blocked_dates: [day(0), day(1), day(2)] }
        : { max_available_seats: 2, blocked_dates: [day(0), day(1)] })
    },
  })
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
const lang = await vi.hoisted(async () => (await import('../helpers/mockApi')).createLang('en'))
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))

const BookingSlotPicker = (await import('~/components/booking/BookingSlotPicker.vue')).default

const workshop = { id: 1, max_people_per_booking: 4, type: 'make_your_piece' }

const mount = () => mountSuspended(BookingSlotPicker, { props: { workshop } })

describe('BookingSlotPicker', () => {
  it('caps the party size at the seats the server says are available', async () => {
    const wrapper = await mount()
    await flushPromises()
    // max_people_per_booking is 4, but no date in the window fits more than 2.
    expect(wrapper.findAll('[data-people]')).toHaveLength(2)
  })

  /**
   * Blocked days are dropped from the strip, not dimmed in it: it is a list of choices,
   * and dates the customer cannot pick are noise to read past. (The SLOTS below are the
   * opposite — see the full/clash case, where the reason is worth saying.)
   */
  it('leaves the blocked dates out and lands on the first open one', async () => {
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find(`[data-date="${plusDays(1)}"]`).exists()).toBe(false)
    expect(wrapper.find(`[data-date="${plusDays(2)}"]`).exists()).toBe(true)
    expect(wrapper.find(`[data-date="${plusDays(2)}"]`).classes()).toContain('bg-primary')
    expect(wrapper.emitted('update:date').at(-1)).toEqual([plusDays(2)])
  })

  it('refetches the calendar when the party size changes', async () => {
    const wrapper = await mount()
    await flushPromises()
    const calendarCalls = () => api.calls.filter((call) => call.url.includes('availability') && !call.query?.date).length
    const before = calendarCalls()

    await wrapper.find('[data-people="2"]').trigger('click')
    await flushPromises()

    expect(calendarCalls()).toBeGreaterThan(before)
    // The day that was open for one person is blocked for more of them, so it goes.
    expect(wrapper.find(`[data-date="${plusDays(2)}"]`).exists()).toBe(false)
  })

  it('disables a full slot and one that clashes with an existing booking', async () => {
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-slot="13"]').attributes('disabled')).toBeUndefined()
    expect(wrapper.find('[data-slot="14"]').attributes('disabled')).toBeDefined()
    expect(wrapper.find('[data-slot="15"]').attributes('disabled')).toBeDefined()
    expect(wrapper.text()).toContain('You are already booked then')
  })

  it('says the studio times in 12 hours', async () => {
    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.text()).toContain('Session 10:00 AM to 11:00 AM')
  })
})
