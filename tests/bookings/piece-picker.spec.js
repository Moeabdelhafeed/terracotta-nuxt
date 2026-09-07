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

const mount = (peopleCount = 1, lines = ref([])) =>
  mountSuspended(BookingPiecePicker, { props: { workshop, peopleCount, modelValue: lines.value, 'onUpdate:modelValue': (value) => { lines.value = value } } })

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
})
