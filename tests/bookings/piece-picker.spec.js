// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

const lang = await vi.hoisted(async () => (await import('../helpers/mockApi')).createLang('en'))
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))

const BookingPiecePicker = (await import('~/components/booking/BookingPiecePicker.vue')).default

const workshop = {
  id: 2,
  type: 'paint_your_piece',
  min_products_per_person: 1,
  max_products_per_person: 3,
  categories: [{
    id: 1,
    title: 'Cups',
    sub_categories: [{
      id: 1,
      title: 'Abbasid',
      products: [
        { id: 1, title: 'Abbasi Cup', subtitle: '300 g of clay', price: '65.00', images: [] },
        { id: 2, title: 'Abbasi Mug', subtitle: null, price: '75.00', images: [] },
      ],
    }],
  }],
  own_pieces: { price: '20.00', count: 1, pieces: [{ id: 7, label: 'My cup', made_on: '2026-07-04', images: [] }] },
}

const mount = (peopleCount = 1, lines = ref([]), over = workshop) =>
  mountSuspended(BookingPiecePicker, { props: { workshop: over, peopleCount, modelValue: lines.value, 'onUpdate:modelValue': (value) => { lines.value = value } } })

/** The same workshop, with its own-pieces rail replaced. */
const withOwnPieces = (pieces) => ({ ...workshop, own_pieces: { price: '20.00', count: pieces.length, pieces } })

describe('BookingPiecePicker', () => {
  it('states the bounds for the current party size', async () => {
    const one = await mount(1)
    expect(one.text()).toContain('Choose between 1 and 3 pieces in total.')

    const two = await mount(2)
    expect(two.text()).toContain('Choose between 2 and 6 pieces in total.')
  })

  it('refuses to go past the maximum for one person', async () => {
    const lines = ref([])
    const wrapper = await mount(1, lines)

    for (let i = 0; i < 5; i += 1) {
      await wrapper.find('[data-add-product="1"]').trigger('click')
      await wrapper.setProps({ modelValue: lines.value })
      await flushPromises()
    }

    expect(lines.value.reduce((sum, line) => sum + line.quantity, 0)).toBe(3)
  })

  it('adds an own piece once, at quantity one', async () => {
    const lines = ref([])
    const wrapper = await mount(1, lines)

    await wrapper.find('[data-add-piece="7"]').trigger('click')
    await wrapper.setProps({ modelValue: lines.value })
    await flushPromises()
    expect(lines.value).toEqual([{ workshop_booking_piece_id: 7, quantity: 1, title: 'My cup', subtitle: null, price: '20.00' }])

    // Already chosen: the button is disabled rather than stacking a second copy.
    expect(wrapper.find('[data-add-piece="7"]').attributes('disabled')).toBeDefined()
  })

  it('refuses a piece that has already been painted, and says so', async () => {
    const lines = ref([])
    const wrapper = await mount(1, lines, withOwnPieces([
      { id: 7, label: 'My cup', made_on: '2026-07-04', images: [], is_available_to_paint: false, painting_session: { booking_id: 90, date: '2026-08-01', workshop_title: 'Paint Your Cup', is_upcoming: false } },
    ]))

    expect(wrapper.find('[data-add-piece="7"]').attributes('disabled')).toBeDefined()
    expect(wrapper.find('[data-piece-unavailable="7"]').text()).toBe('This piece has already been painted.')

    // The server would answer 422; nothing reaches the basket from here.
    await wrapper.find('[data-add-piece="7"]').trigger('click')
    await flushPromises()
    expect(lines.value).toEqual([])
  })

  it('names the session a piece is already booked into', async () => {
    const wrapper = await mount(1, ref([]), withOwnPieces([
      { id: 8, label: 'Sara mug', made_on: '2026-07-04', images: [], is_available_to_paint: false, painting_session: { booking_id: 91, date: '2026-09-20', workshop_title: 'Paint Your Cup', is_upcoming: true } },
    ]))

    expect(wrapper.find('[data-add-piece="8"]').attributes('disabled')).toBeDefined()
    expect(wrapper.find('[data-piece-unavailable="8"]').text()).toBe('Already booked in to be painted at Paint Your Cup on 2026-09-20.')
  })

  it('leaves a free piece alone — an absent flag is not an unavailable piece', async () => {
    const wrapper = await mount(1, ref([]), withOwnPieces([
      { id: 9, label: 'Plain bowl', made_on: '2026-07-04', images: [], is_available_to_paint: true, painting_session: null },
      { id: 10, label: 'Old row', made_on: '2026-07-04', images: [] },
    ]))

    expect(wrapper.find('[data-add-piece="9"]').attributes('disabled')).toBeUndefined()
    expect(wrapper.find('[data-add-piece="10"]').attributes('disabled')).toBeUndefined()
    expect(wrapper.find('[data-piece-unavailable="9"]').exists()).toBe(false)
  })
})
