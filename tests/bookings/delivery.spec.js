// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { h, ref } from 'vue'

const { api, lang, sanctum, toast, navigate, addressId } = await vi.hoisted(async () => {
  const { ref: r } = await import('vue')
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/workshops/bookings/{id}': () => envelope(globalThis.__booking),
      'GET /api/workshops/bookings/{id}/delivery/quote': () => globalThis.__quote(),
      'POST /api/workshops/bookings/{id}/delivery': () => envelope(globalThis.__booking, 'Saved.'),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState({ id: 1, name: 'Sara', is_guest: false, wallet_balance: '100.00' }),
    toast: { success: v.fn(), error: v.fn(), info: v.fn() },
    navigate: v.fn(),
    addressId: r(null),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useToast', () => () => toast)
mockNuxtImport('navigateTo', () => navigate)
mockNuxtImport('showError', () => vi.fn())
mockNuxtImport('useRoute', () => () => ({ params: { id: '55' }, query: { method: 'delivery' } }))

const DeliveryPage = (await import('~/pages/bookings/[id]/delivery.vue')).default

/** Stands in for AddressPicker: a button per saved address, writing the model. */
const AddressPickerStub = {
  props: ['modelValue'],
  emits: ['update:modelValue'],
  setup(props, { emit }) {
    return () => [3, 4].map((id) => h('button', { 'data-address': id, onClick: () => emit('update:modelValue', id) }, `address ${id}`))
  },
}

const booking = (over = {}) => ({
  id: 55, workshop_id: 1, workshop_title: 'Wheel throwing',
  status: 'completed', delivery_status: null, delivery_method: null,
  pickup_deadline: '2026-10-08', ...over,
})

const quote = (over = {}) => ({
  subtotal: '25.00', discount_amount: '0.00', discount_code: null, delivery_fee: '25.00', delivery_zone: 'Riyadh',
  total_price: '25.00', vat_rate: '0.00', vat_amount: '0.00',
  wallet_applied: '0.00', amount_due: '25.00', already_paid: false, ...over,
})

const mount = () => mountSuspended(DeliveryPage, {
  global: { stubs: { PageBar: true, AddressPicker: AddressPickerStub } },
})

const quoteCalls = () => api.calls.filter((call) => call.url.endsWith('/delivery/quote'))

beforeEach(() => {
  api.calls.length = 0
  globalThis.__booking = booking()
  globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote() })
})

describe('piece delivery — the quote follows its inputs', () => {
  it('re-quotes when the address changes, and sends it', async () => {
    const wrapper = await mount()
    await flushPromises()
    const before = quoteCalls().length

    await wrapper.find('[data-address="4"]').trigger('click')
    await flushPromises()

    expect(quoteCalls().length).toBe(before + 1)
    expect(quoteCalls().at(-1).query).toMatchObject({ address_id: 4 })
  })

  it('re-quotes when the wallet toggle changes, and sends it', async () => {
    const wrapper = await mount()
    await flushPromises()
    expect(quoteCalls().at(-1).query.use_wallet).toBe(0)

    await wrapper.find('[role="checkbox"]').trigger('click')
    await flushPromises()

    expect(quoteCalls().at(-1).query.use_wallet).toBe(1)
  })

  it('does not quote at all for pickup — there is no fee to price', async () => {
    const wrapper = await mount()
    await flushPromises()
    const before = quoteCalls().length

    await wrapper.findAll('button').find((b) => b.text() === 'Pick it up').trigger('click')
    await flushPromises()

    expect(quoteCalls().length).toBe(before)
    expect(wrapper.text()).toContain('Come by the studio with your booking code')
  })
})

describe('piece delivery — what is still owed', () => {
  it('says the remainder is settled at handover, there being no online payment for it', async () => {
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('25.00 SAR stays owing and is settled at handover')
    expect(wrapper.text()).toContain('there is no online payment for the delivery fee')
    expect(wrapper.findAll('button').some((b) => b.text().includes('Pay now'))).toBe(false)
  })

  it('drops the note once the wallet covers the fee in full', async () => {
    globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote({ wallet_applied: '25.00', amount_due: '0.00' }) })

    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).not.toContain('stays owing')
  })

  it('says nothing more is due when the fee was already charged', async () => {
    globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote({ already_paid: true, amount_due: '0.00' }) })

    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('The delivery fee was already charged')
    expect(wrapper.text()).not.toContain('stays owing')
  })
})
