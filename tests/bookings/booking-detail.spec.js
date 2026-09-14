// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang, toast } = await vi.hoisted(async () => {
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/workshops/bookings/{id}': () => envelope(globalThis.__booking),
      'POST /api/workshops/bookings/{id}/images': () => globalThis.__upload(),
    }),
    lang: createLang('en'),
    toast: { success: v.fn(), error: v.fn(), info: v.fn() },
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useDateFormat', () => () => ({ formatDate: (v) => `on ${String(v).slice(0, 10)}`, formatTime: (v) => v }))
mockNuxtImport('useToast', () => () => toast)
mockNuxtImport('showError', () => vi.fn())
mockNuxtImport('useRoute', () => () => ({ params: { id: '55' }, query: {} }))

const BookingPage = (await import('~/pages/bookings/[id]/index.vue')).default

const booking = (over = {}) => ({
  id: 55, workshop_id: 1, workshop_title: 'Wheel throwing',
  status: 'confirmed', booking_date: '2026-10-01', start_time: '10:00', end_time: '11:00',
  people_count: 2, has_celebration: false, checkin_code: 'TC-4821',
  total_price: '190.00', amount_due: '0.00', payment_status: 'paid', payment_expires_at: null,
  can_cancel: true, can_edit: true, editable_until: null, location_url: null,
  delivery_status: null, delivery_method: null, pickup_deadline: null, delivery_fee_amount_due: null,
  images: [], pieces: [], products: [], expected_piece_count: 2, paintable_at: [], ...over,
})

const mount = () => mountSuspended(BookingPage, {
  global: { stubs: { PageBar: true, AppImage: true, BookingSheet: true, BookingSlotPicker: true } },
})

const byText = (wrapper, text) => wrapper.findAll('button').find((b) => b.text().includes(text))

beforeEach(() => {
  api.calls.length = 0
  globalThis.__booking = booking()
  globalThis.__upload = () => ({ success: true, message: 'Photos uploaded.', errors: null, data: globalThis.__booking })
})

describe('booking detail — what the server permits', () => {
  it('a held booking may be cancelled but never rescheduled', async () => {
    globalThis.__booking = booking({ status: 'pending_payment', payment_status: 'unpaid', amount_due: '190.00', can_cancel: true, can_edit: false })
    const wrapper = await mount()
    await flushPromises()

    expect(byText(wrapper, 'Cancel the booking')).toBeDefined()
    expect(byText(wrapper, 'Change the time')).toBeUndefined()
  })

  it('a confirmed booking the server marks editable offers both', async () => {
    const wrapper = await mount()
    await flushPromises()

    expect(byText(wrapper, 'Cancel the booking')).toBeDefined()
    expect(byText(wrapper, 'Change the time')).toBeDefined()
  })

  it('a finished booking offers neither', async () => {
    globalThis.__booking = booking({ status: 'completed', can_cancel: false, can_edit: false, pickup_deadline: null })
    const wrapper = await mount()
    await flushPromises()

    expect(byText(wrapper, 'Cancel the booking')).toBeUndefined()
    expect(byText(wrapper, 'Change the time')).toBeUndefined()
  })
})

describe('booking detail — photo upload', () => {
  const attending = (over = {}) => booking({ status: 'attending', ...over })

  /** Create a piece card, name it, and attach `count` photos to it. */
  const addPiece = async (wrapper, label, count) => {
    await wrapper.find('[data-test="add-piece"]').trigger('click')
    const card = wrapper.findAll('[data-test="draft-piece"]').at(-1)
    await card.find('input[type="text"], input:not([type])').setValue(label)
    const input = card.find('input[type="file"]')
    const files = Array.from({ length: count }, (_, i) => new File(['x'], `${label}-${i}.png`, { type: 'image/png' }))
    Object.defineProperty(input.element, 'files', { value: files, configurable: true })
    await input.trigger('change')
  }

  const post = () => api.calls.find((call) => call.url === '/api/workshops/bookings/55/images')

  it('is offered only while the session is running', async () => {
    for (const status of ['confirmed', 'preparing', 'completed', 'absent']) {
      globalThis.__booking = booking({ status })
      const wrapper = await mount()
      await flushPromises()
      expect(wrapper.find('[data-test="upload"]').exists()).toBe(false)
    }

    globalThis.__booking = attending()
    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.find('[data-test="upload"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="upload"]').text()).toContain('Once the studio finishes it nothing can ever be added')
  })

  it('says the door is shut once the session has moved on', async () => {
    globalThis.__booking = booking({ status: 'preparing', pieces: [{ id: 3, label: 'Mug', images: [] }] })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('The session is over, so no more photos can be added')
  })

  it('allows four photos per person, less whatever is already up', async () => {
    globalThis.__booking = attending({ people_count: 2, images: [{ id: 1 }, { id: 2 }, { id: 3 }] })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-test="upload"]').text()).toContain('5 photo(s) left')
  })

  it('never takes more photos than are left, however many are picked', async () => {
    globalThis.__booking = attending({ people_count: 1, images: [{ id: 1 }, { id: 2 }, { id: 3 }] })
    const wrapper = await mount()
    await flushPromises()

    await addPiece(wrapper, 'Mug', 3)
    await byText(wrapper, 'Upload').trigger('click')
    await flushPromises()

    expect(post().body.getAll('images[]')).toHaveLength(1)
  })

  it('counts progress against the pieces the booking expects', async () => {
    globalThis.__booking = attending({ expected_piece_count: 2, pieces: [{ id: 3, label: 'Mug', images: [{ id: 1 }] }] })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-test="piece-progress"]').text()).toBe('1 of 2 named')
  })

  it('gives two pieces of the same name two distinct keys', async () => {
    globalThis.__booking = attending({ people_count: 2 })
    const wrapper = await mount()
    await flushPromises()

    await addPiece(wrapper, 'mug', 3)
    await addPiece(wrapper, 'mug', 2)

    await byText(wrapper, 'Upload').trigger('click')
    await flushPromises()

    const body = post().body
    expect(body.getAll('images[]')).toHaveLength(5)
    expect(body.getAll('piece_labels[]')).toEqual(['mug', 'mug', 'mug', 'mug', 'mug'])

    const keys = body.getAll('piece_keys[]')
    expect(new Set(keys).size).toBe(2)
    expect(keys.slice(0, 3).every((k) => k === keys[0])).toBe(true)
    expect(keys.slice(3).every((k) => k === keys[3])).toBe(true)
    expect(keys[0]).not.toBe(keys[3])
    expect(body.getAll('piece_ids[]')).toEqual(['', '', '', '', ''])
  })

  it('adds another angle to an existing piece by its id, not a new key', async () => {
    globalThis.__booking = attending({ people_count: 2, pieces: [{ id: 7, label: 'Moe', images: [{ id: 1 }] }] })
    const wrapper = await mount()
    await flushPromises()

    const input = wrapper.find('[data-add-to="7"]')
    Object.defineProperty(input.element, 'files', { value: [new File(['x'], 'angle.png', { type: 'image/png' })], configurable: true })
    await input.trigger('change')

    await byText(wrapper, 'Upload').trigger('click')
    await flushPromises()

    const body = post().body
    expect(body.getAll('piece_ids[]')).toEqual(['7'])
    expect(body.getAll('piece_keys[]')).toEqual([''])
    expect(body.getAll('piece_labels[]')).toEqual(['Moe'])
  })

  it('stops a catalog booking at the pieces it paid for, before any request', async () => {
    globalThis.__booking = attending({
      people_count: 2,
      expected_piece_count: 2,
      products: [{ workshop_product_id: 1, quantity: 2, title: 'Bowl', unit_price: '40.00' }],
    })
    const wrapper = await mount()
    await flushPromises()

    await addPiece(wrapper, 'one', 1)
    await addPiece(wrapper, 'two', 1)

    expect(wrapper.findAll('[data-test="draft-piece"]')).toHaveLength(2)
    expect(wrapper.find('[data-test="add-piece"]').attributes('disabled')).toBeDefined()
    expect(wrapper.find('[data-test="ceiling-note"]').text()).toContain('You bought 2 piece(s)')

    await wrapper.find('[data-test="add-piece"]').trigger('click')
    expect(wrapper.findAll('[data-test="draft-piece"]')).toHaveLength(2)
    expect(post()).toBeUndefined()
  })

  it('lets a make_your_piece booking go past its guide', async () => {
    globalThis.__booking = attending({ people_count: 2, expected_piece_count: 2, products: [] })
    const wrapper = await mount()
    await flushPromises()

    await addPiece(wrapper, 'one', 1)
    await addPiece(wrapper, 'two', 1)
    await addPiece(wrapper, 'three', 1)

    expect(wrapper.findAll('[data-test="draft-piece"]')).toHaveLength(3)
    expect(wrapper.find('[data-test="add-piece"]').attributes('disabled')).toBeUndefined()
  })

  it('surfaces a refusal whose body carries a message but no field errors', async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__booking = attending({ people_count: 2, pieces: [{ id: 3, label: 'Mug', images: [] }] })
    globalThis.__upload = () => apiError(422, null, 'You can only upload photos while you are attending the workshop.')

    const wrapper = await mount()
    await flushPromises()
    await addPiece(wrapper, 'Mug', 1)

    await byText(wrapper, 'Upload').trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('You can only upload photos while you are attending the workshop.')
  })

  it('puts a field-keyed refusal on the control it belongs to', async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__booking = attending({ people_count: 2, pieces: [{ id: 3, label: 'Mug', images: [] }] })
    globalThis.__upload = () => apiError(422, { piece_ids: ['That piece belongs to another booking.'] })

    const wrapper = await mount()
    await flushPromises()
    await addPiece(wrapper, 'Mug', 1)

    await byText(wrapper, 'Upload').trigger('click')
    await flushPromises()

    expect(wrapper.find('[data-test="upload"]').text()).toContain('That piece belongs to another booking.')
  })
})
