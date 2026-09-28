// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { h, ref } from 'vue'

const { api, lang, sanctum, toast, navigate, addressId, walletRefresh } = await vi.hoisted(async () => {
  const { ref: r } = await import('vue')
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/workshops/bookings/{id}': () => envelope(globalThis.__booking),
      'GET /api/workshops/bookings/{id}/delivery/quote': () => globalThis.__quote(),
      'POST /api/workshops/bookings/{id}/delivery': () => envelope(globalThis.__booking, 'Saved.'),
      'GET /api/wallet/transactions': () => envelope({ balance: '125.00', transactions: [] }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState({ id: 1, name: 'Sara', is_guest: false, wallet_balance: '100.00' }),
    toast: { success: v.fn(), error: v.fn(), info: v.fn() },
    navigate: v.fn(),
    addressId: r(null),
    walletRefresh: v.fn(),
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
mockNuxtImport('useWallet', () => () => ({ balance: ref('125.00'), transactions: ref([]), refresh: walletRefresh }))
// Most tests arrive from the booking page's Delivery button; the switching tests arrive
// with no choice made, which is when the page offers both.
mockNuxtImport('useRoute', () => () => ({ params: { id: '55' }, query: globalThis.__query ?? { method: 'delivery' } }))

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
  delivery_fee: null, delivery_fee_wallet_applied: null,
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
  walletRefresh.mockClear()
  sanctum.refreshIdentity.mockClear()
  globalThis.__booking = booking()
  globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote() })
  globalThis.__query = undefined
})

/** Arrive with no choice made and pick delivery by hand, so the pickup button is there too. */
const mountUndecided = async () => {
  globalThis.__query = {}
  const wrapper = await mount()
  await flushPromises()
  await wrapper.findAll('button').find((b) => b.text() === 'Have it delivered').trigger('click')
  await flushPromises()
  return wrapper
}

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
    const wrapper = await mountUndecided()
    const before = quoteCalls().length

    await wrapper.findAll('button').find((b) => b.text() === 'Pick it up').trigger('click')
    await flushPromises()

    expect(quoteCalls().length).toBe(before)
    expect(wrapper.text()).toContain('Come by the studio with your booking code')
  })
})

describe('piece delivery — confirming pays', () => {
  it('says confirming pays the fee, with no pay step after', async () => {
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('The 25.00 SAR delivery fee is paid now. Nothing is due on delivery.')
    // The copy that shipped before promised the fee was owed at handover (QA WEB-03).
    expect(wrapper.text()).not.toContain('settled at handover')
    expect(wrapper.text()).not.toContain('paid on the next screen')
  })

  it('drops the note once the wallet covers the fee in full', async () => {
    globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote({ wallet_applied: '25.00', amount_due: '0.00' }) })

    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).not.toContain('is paid now')
  })

  it('says nothing more is due when the fee was already charged', async () => {
    globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote({ already_paid: true, amount_due: '0.00' }) })

    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('The delivery fee was already charged')
    expect(wrapper.text()).not.toContain('is paid now')
  })
})

describe('piece delivery — switching to pickup hands the fee back', () => {
  const pickUp = async (wrapper) => {
    await wrapper.findAll('button').find((b) => b.text() === 'Pick it up').trigger('click')
    await flushPromises()
  }

  /**
   * A booking already on delivery opens on the only move left — pickup. Offering delivery
   * again read as the choice not having registered, and confirming it re-quotes a fee that
   * is already paid.
   */
  it('opens on pickup, and does not offer the delivery already in effect', async () => {
    globalThis.__booking = booking({ delivery_method: 'delivery', delivery_fee: '25.00', delivery_payment_status: 'paid' })
    globalThis.__query = {}
    const wrapper = await mount()
    await flushPromises()

    const labels = wrapper.findAll('button').map((b) => b.text())
    expect(labels).not.toContain('Have it delivered')
    expect(labels).not.toContain('Pick it up')
    expect(wrapper.text()).toContain('Your piece is set for delivery')
    expect(wrapper.findAll('button').some((b) => b.text() === 'Confirm pickup')).toBe(true)
  })

  // The page does not promise the fee back any more, on either screen: the switch is made
  // here and the refund shows up in the wallet, which is where the customer reads it.
  it('promises nothing back when switching to pickup', async () => {
    globalThis.__booking = booking({ delivery_method: 'delivery', delivery_fee: '25.00', delivery_fee_wallet_applied: '0.00', delivery_payment_status: 'paid' })
    globalThis.__query = {}
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-test="pickup-refund"]').exists()).toBe(false)
    expect(wrapper.text()).not.toContain('goes back to your Terracotta balance')
  })

  it('refreshes the balance after the choice, rather than leaving a stale number', async () => {
    globalThis.__booking = booking({ delivery_method: 'delivery', delivery_fee: '25.00' })
    globalThis.__query = {}
    const wrapper = await mount()
    await flushPromises()

    await wrapper.findAll('button').find((b) => b.text() === 'Confirm pickup').trigger('click')
    await flushPromises()

    expect(walletRefresh).toHaveBeenCalled()
    expect(sanctum.refreshIdentity).toHaveBeenCalled()
    expect(navigate).toHaveBeenCalledWith('/bookings/55')
  })
})

describe('piece delivery — the choice already made', () => {
  it('shows only the option the customer picked on the booking page', async () => {
    // Arriving from the booking page's Delivery button (QA WEB-03): the pair again read as
    // the choice not having registered.
    const wrapper = await mount()
    await flushPromises()

    const labels = wrapper.findAll('button').map((b) => b.text())
    expect(labels).not.toContain('Pick it up')
    expect(labels).not.toContain('Have it delivered')
    expect(labels).toContain('Confirm the delivery')
    expect(wrapper.text()).toContain('Choose the address your piece should be delivered to.')
    expect(wrapper.text()).not.toContain('Pick it up from the studio, or')
  })

  it('offers both when the customer arrives without choosing', async () => {
    globalThis.__query = {}
    const wrapper = await mount()
    await flushPromises()

    const labels = wrapper.findAll('button').map((b) => b.text())
    expect(labels).toContain('Pick it up')
    expect(labels).toContain('Have it delivered')
  })

})
