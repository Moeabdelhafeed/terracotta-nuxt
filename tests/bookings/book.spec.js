// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { h } from 'vue'

const inMinutes = (m) => new Date(Date.now() + m * 60000).toISOString()

const { api, lang, sanctum, toast, showError, refreshNuxtData, picker } = await vi.hoisted(async () => {
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/workshops/{id}': () => envelope(globalThis.__workshop),
      'GET /api/workshops/{id}/price': () => globalThis.__quote(),
      'POST /api/workshops/{id}/bookings': () => globalThis.__create(),
      'POST /api/workshops/bookings/{id}/pay': () => envelope({ ...globalThis.__booking, payment_status: 'paid', amount_due: '0.00' }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState({ id: 1, name: 'Sara', is_guest: false, wallet_balance: '100.00' }),
    toast: { success: v.fn(), error: v.fn(), info: v.fn() },
    showError: v.fn(),
    refreshNuxtData: v.fn(),
    picker: { refreshCalendar: v.fn(), refreshSlots: v.fn() },
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useToast', () => () => toast)
mockNuxtImport('showError', () => showError)
mockNuxtImport('refreshNuxtData', () => refreshNuxtData)
mockNuxtImport('useRoute', () => () => ({ params: { id: '1' }, query: {}, fullPath: '/workshops/1/book' }))

const BookPage = (await import('~/pages/workshops/[id]/book.vue')).default

const SLOT = { workshop_slot_id: 13, start_time: '10:00', end_time: '11:00' }

/** Stands in for BookingSlotPicker: one button that picks a day + slot, plus the two
 *  refresh methods `book.vue` reaches for through its template ref. */
const PickerStub = {
  props: ['workshop', 'people', 'date', 'slotId', 'slot', 'errors'],
  emits: ['update:people', 'update:date', 'update:slotId', 'update:slot'],
  setup(props, { emit, expose }) {
    expose(picker)
    return () => h('div', [
      h('button', {
        'data-test': 'pick',
        onClick: () => {
          emit('update:date', '2026-10-01')
          emit('update:slotId', SLOT.workshop_slot_id)
          emit('update:slot', SLOT)
        },
      }, 'pick'),
      h('button', { 'data-test': 'people-3', onClick: () => emit('update:people', 3) }, 'three'),
      h('span', { 'data-test': 'picker-errors' }, Object.values(props.errors ?? {}).flat().join(' ')),
    ])
  },
}

const quote = (over = {}) => ({
  subtotal: '190.00', discount_amount: '0.00', discount_code: null, delivery_fee: null,
  total_price: '190.00', vat_rate: '15.00', vat_amount: '24.78',
  wallet_applied: '0.00', amount_due: '190.00', ...over,
})

const workshop = (over = {}) => ({
  id: 1, title: 'Wheel throwing', type: 'make_your_piece',
  price: '95.00', celebration_price: '60.00', cancellation_window_hours: 24,
  max_people_per_booking: 4, location_url: null, ...over,
})

const mount = () => mountSuspended(BookPage, {
  global: {
    stubs: {
      BookingSlotPicker: PickerStub,
      BookingSheet: { props: ['open', 'title'], template: '<div v-if="open"><slot /><slot name="footer" /></div>' },
      AppConfetti: true,
      PageBar: true,
    },
  },
})

const byText = (wrapper, text) => wrapper.findAll('button').find((b) => b.text().includes(text))

/** The highlighted chip in the step rail — where the customer actually is. */
const currentStep = (wrapper) => wrapper.find('.bg-brand-rust.text-white').text()

/** Walk the picker → pay step and settle the debounced quote. */
const toPayStep = async (wrapper) => {
  await wrapper.find('[data-test="pick"]').trigger('click')
  await byText(wrapper, 'Payment').trigger('click')
  await vi.advanceTimersByTimeAsync(400)
  await flushPromises()
}

const priceCalls = () => api.calls.filter((call) => call.url.endsWith('/price'))
const createCall = () => api.calls.find((call) => call.method === 'POST' && call.url.endsWith('/bookings'))

beforeEach(() => {
  api.calls.length = 0
  globalThis.__workshop = workshop()
  globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote() })
  globalThis.__booking = { id: 55, ...quote() }
  globalThis.__create = () => ({ success: true, message: 'ok', errors: null, data: globalThis.__booking })
  vi.useFakeTimers({ shouldAdvanceTime: true })
})

afterEach(() => { vi.useRealTimers() })

describe('workshop booking — create then pay', () => {
  it('a create that comes back settled skips the hold and lands on done', async () => {
    globalThis.__booking = { id: 55, ...quote({ wallet_applied: '190.00', amount_due: '0.00' }), payment_status: 'paid', payment_expires_at: null }

    const wrapper = await mount()
    await toPayStep(wrapper)
    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('Your booking is confirmed!')
    expect(wrapper.text()).not.toContain('Reserved for you')
    expect(api.calls.some((call) => call.url.endsWith('/pay'))).toBe(false)
    expect(wrapper.find('a[href="/bookings/55"]').exists()).toBe(true)
  })

  it('a create that still owes money renders the hold with its countdown', async () => {
    globalThis.__booking = { id: 55, ...quote({ amount_due: '190.00' }), payment_status: 'unpaid', payment_expires_at: inMinutes(14) }

    const wrapper = await mount()
    await toPayStep(wrapper)
    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('Reserved for you')
    expect(wrapper.text()).toMatch(/13:5\d|14:00/)
    expect(wrapper.text()).not.toContain('Your booking is confirmed!')
  })

  it('paying the hold finishes the booking', async () => {
    globalThis.__booking = { id: 55, ...quote({ amount_due: '190.00' }), payment_status: 'unpaid', payment_expires_at: inMinutes(14) }

    const wrapper = await mount()
    await toPayStep(wrapper)
    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()

    await byText(wrapper, 'Pay now').trigger('click')
    await flushPromises()

    expect(api.calls.some((call) => call.url === '/api/workshops/bookings/55/pay')).toBe(true)
    expect(wrapper.text()).toContain('Your booking is confirmed!')
  })
})

describe('workshop booking — the quote follows its inputs', () => {
  it('re-quotes for the party size, and sends the same flags to create', async () => {
    const wrapper = await mount()
    await toPayStep(wrapper)
    const before = priceCalls().length
    expect(before).toBeGreaterThan(0)

    await wrapper.find('[data-test="people-3"]').trigger('click')
    await vi.advanceTimersByTimeAsync(400)
    await flushPromises()

    expect(priceCalls().length).toBeGreaterThan(before)
    expect(priceCalls().at(-1).query).toMatchObject({ people_count: 3, workshop_slot_id: 13, booking_date: '2026-10-01' })

    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()
    expect(createCall().body).toMatchObject({ people_count: 3, workshop_slot_id: 13, booking_date: '2026-10-01' })
  })

  it('re-quotes when the celebration is added, and books with it', async () => {
    const wrapper = await mount()
    await toPayStep(wrapper)
    expect(priceCalls().at(-1).query.with_celebration).toBe(0)

    await byText(wrapper, 'Add a celebration').trigger('click')
    await byText(wrapper, 'Add 60.00 SAR').trigger('click')
    await vi.advanceTimersByTimeAsync(400)
    await flushPromises()

    expect(priceCalls().at(-1).query.with_celebration).toBe(1)

    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()
    expect(createCall().body.with_celebration).toBe(true)
  })

  it('re-quotes when the wallet is switched on, and books with it', async () => {
    const wrapper = await mount()
    await toPayStep(wrapper)
    expect(priceCalls().at(-1).query.use_wallet).toBe(0)

    await wrapper.find('[role="checkbox"]').trigger('click')
    await vi.advanceTimersByTimeAsync(400)
    await flushPromises()

    expect(priceCalls().at(-1).query.use_wallet).toBe(1)

    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()
    expect(createCall().body.use_wallet).toBe(true)
  })

  it('re-quotes when a discount code is applied, and books with it', async () => {
    const wrapper = await mount()
    await toPayStep(wrapper)
    expect(priceCalls().at(-1).query.discount_code).toBeUndefined()

    await wrapper.find('#discount_code').setValue('welcome10')
    await byText(wrapper, 'Apply').trigger('click')
    await vi.advanceTimersByTimeAsync(400)
    await flushPromises()

    expect(priceCalls().at(-1).query.discount_code).toBe('WELCOME10')

    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()
    expect(createCall().body.discount_code).toBe('WELCOME10')
  })

  it('one quote per settled burst — the debounce protects the shared throttle', async () => {
    const wrapper = await mount()
    await toPayStep(wrapper)
    const before = priceCalls().length

    await wrapper.find('[data-test="people-3"]').trigger('click')
    await wrapper.find('[role="checkbox"]').trigger('click')
    await vi.advanceTimersByTimeAsync(400)
    await flushPromises()

    expect(priceCalls().length).toBe(before + 1)
  })
})

describe('workshop booking — a seat that went while we were looking', () => {
  it('a people_count refusal returns to the slot step and refetches availability', async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__create = () => apiError(422, { people_count: ['Only 1 seat is left in this session.'] })

    const wrapper = await mount()
    await toPayStep(wrapper)
    picker.refreshCalendar.mockClear()
    picker.refreshSlots.mockClear()

    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()

    expect(picker.refreshCalendar).toHaveBeenCalled()
    expect(picker.refreshSlots).toHaveBeenCalled()
    expect(currentStep(wrapper)).toBe('1. Date and time')
    expect(wrapper.find('[data-test="picker-errors"]').text()).toContain('Only 1 seat is left in this session.')
  })

  it('a refusal that is not about capacity keeps the customer on the pay step', async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__create = () => apiError(422, { discount_code: ['This code has expired.'] })

    const wrapper = await mount()
    await toPayStep(wrapper)
    picker.refreshCalendar.mockClear()

    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()

    expect(picker.refreshCalendar).not.toHaveBeenCalled()
    expect(currentStep(wrapper)).toBe('2. Payment')
    expect(wrapper.text()).toContain('This code has expired.')
  })
})

describe('workshop booking — the hold lapsing', () => {
  it('clears the held booking and the quote and goes back to the slot step', async () => {
    globalThis.__booking = { id: 55, ...quote({ amount_due: '190.00' }), payment_status: 'unpaid', payment_expires_at: inMinutes(0.2) }

    const wrapper = await mount()
    await toPayStep(wrapper)
    await byText(wrapper, 'Confirm the booking and pay').trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('Reserved for you')

    picker.refreshCalendar.mockClear()
    picker.refreshSlots.mockClear()
    await vi.advanceTimersByTimeAsync(14000)
    await flushPromises()

    expect(wrapper.text()).not.toContain('Reserved for you')
    expect(currentStep(wrapper)).toBe('1. Date and time')
    expect(toast.error).toHaveBeenCalledWith(expect.stringContaining('the seat was released'))
    expect(picker.refreshCalendar).toHaveBeenCalled()
    expect(picker.refreshSlots).toHaveBeenCalled()
  })
})
