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
  images: [], pieces: [], paintable_at: [], ...over,
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
  const attach = async (wrapper, count = 1) => {
    const input = wrapper.find('input[type="file"]')
    const files = Array.from({ length: count }, (_, i) => new File(['x'], `piece-${i}.png`, { type: 'image/png' }))
    Object.defineProperty(input.element, 'files', { value: files, configurable: true })
    await input.trigger('change')
  }

  it('is offered only while the session is running', async () => {
    for (const status of ['confirmed', 'preparing', 'completed', 'absent']) {
      globalThis.__booking = booking({ status })
      const wrapper = await mount()
      await flushPromises()
      expect(wrapper.find('[data-test="upload"]').exists()).toBe(false)
    }

    globalThis.__booking = booking({ status: 'attending' })
    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.find('[data-test="upload"]').exists()).toBe(true)
  })

  it('allows four photos per person, less whatever is already up', async () => {
    globalThis.__booking = booking({ status: 'attending', people_count: 2, images: [{ id: 1 }, { id: 2 }, { id: 3 }] })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-test="upload"]').text()).toContain('5 left')
  })

  it('never offers more than are left, however many are picked', async () => {
    globalThis.__booking = booking({ status: 'attending', people_count: 1, images: [{ id: 1 }, { id: 2 }, { id: 3 }] })
    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.find('[data-test="upload"]').text()).toContain('1 left')

    await attach(wrapper, 3)
    // Only the one remaining slot is taken up, not all three files.
    expect(wrapper.findAll('input[list="piece-labels"]')).toHaveLength(1)
  })

  it('surfaces a refusal whose body carries a message but no field errors', async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__booking = booking({ status: 'attending', people_count: 2, pieces: [{ id: 3, label: 'Mug', images: [] }] })
    globalThis.__upload = () => apiError(422, null, 'You can only upload photos while you are attending the workshop.')

    const wrapper = await mount()
    await flushPromises()
    await attach(wrapper, 1)

    await byText(wrapper, 'Upload').trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('You can only upload photos while you are attending the workshop.')
  })

  it('sends one image and its label per picked file', async () => {
    globalThis.__booking = booking({ status: 'attending', people_count: 2, pieces: [{ id: 3, label: 'Mug', images: [] }] })
    const wrapper = await mount()
    await flushPromises()
    await attach(wrapper, 2)

    await byText(wrapper, 'Upload').trigger('click')
    await flushPromises()

    const post = api.calls.find((call) => call.url === '/api/workshops/bookings/55/images')
    expect(post.body.getAll('images[]')).toHaveLength(2)
    expect(post.body.getAll('piece_labels[]')).toEqual(['Mug', 'Mug'])
  })
})
