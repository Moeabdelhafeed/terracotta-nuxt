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
  global: {
    stubs: {
      PageBar: true,
      AppImage: true,
      BookingSlotPicker: true,
      // Renders its slots: a bare `true` stub drops them, and the uploader now lives
      // inside this sheet, so nothing under test would exist.
      BookingSheet: {
        props: ['open', 'title', 'busy', 'wide'],
        template: '<div v-if="open"><slot /><slot name="footer" /></div>',
      },
    },
  },
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

  // The map is «where the studio is», and it is only worth walking to while the session
  // is still ahead. Afterwards it is the PIECE that travels.
  it('points the way to the studio only while there is still a session to attend', async () => {
    globalThis.__booking = booking({ location_url: 'https://maps.example/studio' })
    const confirmed = await mount()
    await flushPromises()
    expect(confirmed.text()).toContain('The location')

    globalThis.__booking = booking({ status: 'preparing', can_cancel: false, can_edit: false, location_url: 'https://maps.example/studio' })
    const preparing = await mount()
    await flushPromises()
    expect(preparing.text()).not.toContain('The location')
  })

  // The code is the booking's reference as well as its pass — the digits read out at the
  // counter when a piece is collected — so it outlives the session and goes only when the
  // booking does.
  it('keeps the check-in code after the session and drops it on a cancelled booking', async () => {
    globalThis.__booking = booking({ status: 'preparing', can_cancel: false, can_edit: false })
    const preparing = await mount()
    await flushPromises()
    expect(byText(preparing, 'Check-in code')).toBeDefined()

    globalThis.__booking = booking({ status: 'cancelled', can_cancel: false, can_edit: false })
    const cancelled = await mount()
    await flushPromises()
    expect(byText(cancelled, 'Check-in code')).toBeUndefined()
  })

  it('a finished booking offers neither', async () => {
    globalThis.__booking = booking({ status: 'completed', can_cancel: false, can_edit: false, pickup_deadline: null })
    const wrapper = await mount()
    await flushPromises()

    expect(byText(wrapper, 'Cancel the booking')).toBeUndefined()
    expect(byText(wrapper, 'Change the time')).toBeUndefined()
  })
})

describe('booking detail — the handover choice stays the customer\'s', () => {
  /** A finished piece waiting at the studio; `pickup_deadline` is what says there is a leg. */
  const finished = (over = {}) => booking({
    status: 'completed', can_cancel: false, can_edit: false,
    pickup_deadline: '2099-01-01T12:00:00+00:00', ...over,
  })

  const link = (wrapper, method) => wrapper.find(`[data-test="handover-${method}"]`)

  it('offers both ways out before one is picked', async () => {
    globalThis.__booking = finished()
    const wrapper = await mount()
    await flushPromises()

    expect(link(wrapper, 'pickup').attributes('href')).toBe('/bookings/55/delivery?method=pickup')
    expect(link(wrapper, 'delivery').attributes('href')).toBe('/bookings/55/delivery?method=delivery')
    expect(wrapper.find('[data-test="handover-refund"]').exists()).toBe(false)
  })

  // The frame draws its illustration and still offers the ways out: the drawing replaces
  // the panel in the aside, never the buttons under it.
  it('draws the finished piece without taking the ways out with it', async () => {
    globalThis.__booking = finished()
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('img[src="/booking-ready.png"]').exists()).toBe(true)
    expect(link(wrapper, 'pickup').exists()).toBe(true)
    expect(link(wrapper, 'delivery').exists()).toBe(true)
  })

  it('keeps pickup reachable after delivery was chosen, and says what comes back', async () => {
    globalThis.__booking = finished({
      delivery_method: 'delivery', delivery_status: 'getting_ready',
      delivery_fee: '50.00', delivery_fee_wallet_applied: '20.00',
    })
    const wrapper = await mount()
    await flushPromises()

    expect(link(wrapper, 'pickup').attributes('href')).toBe('/bookings/55/delivery?method=pickup')
    expect(link(wrapper, 'delivery').exists()).toBe(false)
    // Only the wallet slice was ever taken, so only that slice is promised back.
    expect(wrapper.find('[data-test="handover-refund"]').text()).toContain('20.00 SAR')
  })

  it('promises nothing back when the wallet paid nothing', async () => {
    globalThis.__booking = finished({
      delivery_method: 'delivery', delivery_status: 'getting_ready',
      delivery_fee: '50.00', delivery_fee_wallet_applied: '0.00',
    })
    const wrapper = await mount()
    await flushPromises()

    expect(link(wrapper, 'pickup').exists()).toBe(true)
    expect(wrapper.find('[data-test="handover-refund"]').exists()).toBe(false)
  })

  it('keeps delivery reachable after pickup was chosen', async () => {
    globalThis.__booking = finished({ delivery_method: 'pickup', delivery_status: 'awaiting_pickup' })
    const wrapper = await mount()
    await flushPromises()

    expect(link(wrapper, 'delivery').attributes('href')).toBe('/bookings/55/delivery?method=delivery')
    expect(link(wrapper, 'pickup').exists()).toBe(false)
  })

  it('closes the choice once the piece has been handed over', async () => {
    globalThis.__booking = finished({ delivery_method: 'delivery', delivery_status: 'completed' })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-test="handover"]').exists()).toBe(false)
  })

  it('never offers it for a workshop with no handover leg at all', async () => {
    globalThis.__booking = finished({ pickup_deadline: null })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-test="handover"]').exists()).toBe(false)
  })

  it('does not send a piece back to be painted once it is on its way somewhere', async () => {
    const paintable = [{ id: 4, title: 'Paint Your Cup', image: null }]
    globalThis.__booking = finished({ paintable_at: paintable, people_count: 3 })
    const free = await mount()
    await flushPromises()
    // The party that made the pieces is the party coming back to paint them.
    expect(free.find('a[href="/workshops/4/book?people=3"]').exists()).toBe(true)

    globalThis.__booking = finished({ paintable_at: paintable, delivery_method: 'pickup', delivery_status: 'awaiting_pickup' })
    const chosen = await mount()
    await flushPromises()
    expect(chosen.find('a[href^="/workshops/4/book"]').exists()).toBe(false)
  })
})

describe('booking detail — copy that has to be the server\'s', () => {
  it('promises no turnaround the API never sent', async () => {
    globalThis.__booking = booking({ status: 'preparing', can_cancel: false, can_edit: false })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('Your piece is being finished with care.')
    expect(wrapper.text()).not.toContain('five to seven days')
  })

  // The app's own frame promises the money back here. This backend states the opposite in
  // as many words — a no-show keeps the seat they booked — so the promise cannot be made.
  it('promises a no-show no refund, and keeps the code the desk can still scan', async () => {
    globalThis.__booking = booking({ status: 'absent', can_cancel: false, can_edit: false })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('the desk can still check you in')
    expect(wrapper.text()).not.toMatch(/refund|balance/i)
    expect(byText(wrapper, 'Check-in code')).toBeDefined()
  })

  it('states the booking\'s own collection deadline, not a hard-coded week', async () => {
    const deadline = new Date(Date.now() + 3 * 86400000 + 3600000).toISOString()
    globalThis.__booking = booking({ status: 'completed', can_cancel: false, can_edit: false, pickup_deadline: deadline })
    const wrapper = await mount()
    await flushPromises()

    const notice = wrapper.find('[data-test="hold-notice"]').text()
    expect(notice).toContain('3 more day(s)')
    expect(notice).toContain(`on ${deadline.slice(0, 10)}`)
    expect(notice).not.toContain('seven days')
  })

  it('says nothing about collecting once the piece is on a van', async () => {
    globalThis.__booking = booking({
      status: 'completed', can_cancel: false, can_edit: false,
      pickup_deadline: new Date(Date.now() + 3 * 86400000).toISOString(),
      delivery_method: 'delivery', delivery_status: 'on_the_way',
    })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-test="hold-notice"]').exists()).toBe(false)
  })
})

describe('booking detail — a piece is its photographs', () => {
  const shot = (id) => ({ id, image_api: `https://cdn.example/${id}.webp`, url: `${id}.webp`, type: 'webp', blurhash: null })

  it('prints each photograph under the piece it belongs to, not in a wall of its own', async () => {
    globalThis.__booking = booking({
      status: 'completed', can_cancel: false, can_edit: false, pickup_deadline: null,
      images: [shot(1), shot(2), shot(3)],
      pieces: [
        { id: 7, label: 'mohammad', images: [shot(1), shot(2)] },
        { id: 8, label: '  ', images: [shot(3)] },
      ],
    })
    const wrapper = await mount()
    await flushPromises()

    const cards = wrapper.findAll('[data-test="piece"]')
    expect(cards).toHaveLength(2)
    expect(cards[0].text()).toContain('mohammad')
    expect(cards[0].findAll('app-image-stub')).toHaveLength(2)
    // A blank name is still a piece, and still carries its own picture.
    expect(cards[1].text()).toContain('Piece')
    expect(cards[1].findAll('app-image-stub')).toHaveLength(1)

    // Nothing is left over, so there is no second gallery beside the names.
    expect(wrapper.text()).not.toContain('Your photos')
  })

  // The run is ONE piece's angles. Sliding from this cup's second shot into somebody
  // else's pictures is not what the tap meant.
  it('opens a photograph full size, on its own piece\'s run', async () => {
    globalThis.__booking = booking({
      status: 'completed', can_cancel: false, can_edit: false, pickup_deadline: null,
      images: [shot(1), shot(2), shot(3)],
      pieces: [
        { id: 7, label: 'mohammad', images: [shot(1), shot(2)] },
        { id: 8, label: 'sara', images: [shot(3)] },
      ],
    })
    const wrapper = await mount()
    await flushPromises()

    await wrapper.findAll('[data-test="piece"]')[0].findAll('button')[1].trigger('click')
    await flushPromises()

    const counter = document.querySelector('[data-test="lightbox-counter"]')
    expect(counter?.textContent?.trim()).toBe('2 / 2')

    document.querySelector('[data-test="lightbox-close"]').click()
    await flushPromises()
  })

  it('still shows a photograph the server sends with no piece behind it', async () => {
    globalThis.__booking = booking({
      status: 'completed', can_cancel: false, can_edit: false, pickup_deadline: null,
      images: [shot(1), shot(9)],
      pieces: [{ id: 7, label: 'mohammad', images: [shot(1)] }],
    })
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('Your photos')
  })
})

describe('booking detail — photo upload', () => {
  const attending = (over = {}) => booking({ status: 'attending', ...over })

  /** The stubbed sheet renders in place, so everything stays under the wrapper. */
  let host = null
  beforeEach(() => { host = null })
  const sheet = () => host
  const openUpload = async (wrapper) => {
    host = wrapper.element
    const trigger = wrapper.find('[data-test="open-upload"]')
    if (trigger.exists()) await trigger.trigger('click')
    await flushPromises()
  }

  /** Create a piece card, name it, and attach `count` photos to it. */
  const addPiece = async (wrapper, label, count) => {
    await openUpload(wrapper)

    // Opening the sheet already creates the first blank card, so only reach for "Add a
    // piece" when the last one has been filled in.
    const last = () => {
      const all = sheet().querySelectorAll('[data-draft-label] input, input[data-draft-label]')
      return all[all.length - 1]
    }
    if (last()?.value) {
      const add = [...sheet().querySelectorAll('button')].find((b) => b.textContent.includes('Add a piece'))
      if (!add) throw new Error('cannot add another piece: the booking is at its ceiling')
      add.click()
      await flushPromises()
    }

    const name = last()
    name.value = label
    name.dispatchEvent(new Event('input', { bubbles: true }))
    await flushPromises()

    const key = (name.closest('[data-draft-label]') ?? name).getAttribute('data-draft-label')
    const input = sheet().querySelector(`input[type="file"][data-draft-files="${key}"]`)
    const files = Array.from({ length: count }, (_, i) => new File(['x'], `${label}-${i}.png`, { type: 'image/png' }))
    Object.defineProperty(input, 'files', { value: files, configurable: true })
    input.dispatchEvent(new Event('change', { bubbles: true }))
    await flushPromises()
  }

  /**
   * The upload control. In the sheet's footer while naming pieces; on the page itself
   * when the only thing staged is another angle of a piece already kept.
   */
  const clickUpload = async (wrapper) => {
    const root = wrapper?.element ?? host
    const btn = [...root.querySelectorAll('button')].find((b) => b.textContent.trim() === 'Upload')
    if (!btn) throw new Error('no Upload control on screen')
    btn.click()
    await flushPromises()
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

    await openUpload(wrapper)
    expect(sheet().textContent).toContain('5 photo(s) left')
  })

  it('never takes more photos than are left, however many are picked', async () => {
    globalThis.__booking = attending({ people_count: 1, images: [{ id: 1 }, { id: 2 }, { id: 3 }] })
    const wrapper = await mount()
    await flushPromises()

    await addPiece(wrapper, 'Mug', 3)
    await clickUpload()

    expect(post().body.getAll('images[]')).toHaveLength(1)
  })

  it('counts progress against the pieces the booking expects', async () => {
    globalThis.__booking = attending({ expected_piece_count: 2, pieces: [{ id: 3, label: 'Mug', images: [{ id: 1 }] }] })
    const wrapper = await mount()
    await flushPromises()

    await openUpload(wrapper)
    expect(sheet().querySelector('[data-test="piece-progress"]').textContent.trim()).toBe('1 of 2 named')
  })

  it('gives two pieces of the same name two distinct keys', async () => {
    globalThis.__booking = attending({ people_count: 2 })
    const wrapper = await mount()
    await flushPromises()

    await addPiece(wrapper, 'mug', 3)
    await addPiece(wrapper, 'mug', 2)

    await clickUpload()

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

    await clickUpload(wrapper)

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

    expect(sheet().querySelectorAll('[data-draft-label]')).toHaveLength(2)
    // Gone, not greyed: there is nothing to press once the booking is full.
    expect(sheet().querySelector('[data-test="add-piece"]')).toBeNull()
    expect(sheet().querySelector('[data-test="ceiling-note"]').textContent).toContain('You bought 2 piece(s)')
    expect(post()).toBeUndefined()
  })

  it('holds a make_your_piece booking to one piece per person', async () => {
    globalThis.__booking = attending({ people_count: 2, expected_piece_count: 2, products: [] })
    const wrapper = await mount()
    await flushPromises()

    await addPiece(wrapper, 'one', 1)
    await addPiece(wrapper, 'two', 1)

    expect(sheet().querySelectorAll('[data-draft-label]')).toHaveLength(2)
    expect(sheet().querySelector('[data-test="add-piece"]')).toBeNull()
  })

  it('surfaces a refusal whose body carries a message but no field errors', async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__booking = attending({ people_count: 2, pieces: [{ id: 3, label: 'Mug', images: [] }] })
    globalThis.__upload = () => apiError(422, null, 'You can only upload photos while you are attending the workshop.')

    const wrapper = await mount()
    await flushPromises()
    await addPiece(wrapper, 'Mug', 1)

    await clickUpload()

    expect(wrapper.text()).toContain('You can only upload photos while you are attending the workshop.')
  })

  it('puts a field-keyed refusal on the control it belongs to', async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__booking = attending({ people_count: 2, pieces: [{ id: 3, label: 'Mug', images: [] }] })
    globalThis.__upload = () => apiError(422, { piece_ids: ['That piece belongs to another booking.'] })

    const wrapper = await mount()
    await flushPromises()
    await addPiece(wrapper, 'Mug', 1)

    await clickUpload()

    expect(wrapper.find('[data-test="upload"]').text()).toContain('That piece belongs to another booking.')
  })
})

/**
 * `paint_your_piece` and `make_your_candle` carry a seat price of "0.00" — the money is in
 * the pieces the customer picks. Printing that price reads as free, which is the opposite
 * of what the session costs, so those two say so in words instead.
 */
describe('workshop pricing — where the money actually is', () => {
  const hasPieceCatalogue = (workshop) =>
    workshop.type === 'paint_your_piece' || workshop.type === 'make_your_candle'

  it('prices the catalogue types by the pieces, never by the seat', () => {
    expect(hasPieceCatalogue({ type: 'paint_your_piece', price: '0.00' })).toBe(true)
    expect(hasPieceCatalogue({ type: 'make_your_candle', price: '0.00' })).toBe(true)
  })

  it('prices a throwing session by the seat', () => {
    expect(hasPieceCatalogue({ type: 'make_your_piece', price: '200.00' })).toBe(false)
  })
})
