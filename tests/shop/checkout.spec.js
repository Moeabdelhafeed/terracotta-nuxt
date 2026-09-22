// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang, sanctum, toast, navigate } = await vi.hoisted(async () => {
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/shop/cart': () => envelope(globalThis.__cart),
      'POST /api/shop/cart/quote': () => globalThis.__quote(),
      'POST /api/shop/cart/checkout': () => globalThis.__checkout(),
      'GET /api/shop/orders': () => envelope({ data: globalThis.__orders, current_page: 1, last_page: 1, total: globalThis.__orders.length }),
      'POST /api/shop/orders/{id}/pay': () => envelope({ ...globalThis.__order, payment_status: 'paid', amount_due: '0.00' }),
      'DELETE /api/shop/orders/{id}': () => envelope({ ...globalThis.__order, status: 'cancelled' }),
      'GET /api/wallet/transactions': () => envelope({ balance: '100.00', transactions: [] }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState({ id: 1, name: 'Sara', is_guest: false, wallet_balance: '100.00' }),
    toast: { success: v.fn(), error: v.fn(), info: v.fn() },
    navigate: v.fn(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useToast', () => () => toast)
mockNuxtImport('useDateFormat', () => () => ({ formatDate: (v) => `on ${v}`, formatTime: (v) => v }))
mockNuxtImport('navigateTo', () => navigate)
mockNuxtImport('useRoute', () => () => ({ params: {}, query: {}, fullPath: '/checkout' }))

const CheckoutPage = (await import('~/pages/checkout.vue')).default

const line = (over = {}) => ({
  id: 1, quantity: 2, unit_price: '100.00', line_total: '200.00', in_stock: true, available_stock: 9,
  product: { id: 11, title: 'Cup', image: null, max_quantity: 9 }, ...over,
})

const quote = (over = {}) => ({
  subtotal: '200.00', discount_amount: '0.00', discount_code: null, delivery_fee: '15.00', delivery_zone: 'Riyadh',
  total_price: '215.00', vat_rate: '15.00', vat_amount: '28.04', wallet_applied: '0.00', amount_due: '215.00', ...over,
})

const order = (over = {}) => ({
  id: 9, status: 'awaiting_payment', ...quote(), payment_status: 'unpaid',
  payment_expires_at: new Date(Date.now() + 14 * 60000).toISOString(),
  can_cancel: true, items: [line()], created_at: '2026-09-01T10:00:00+00:00', ...over,
})

/**
 * The real picker selects the customer's default address as soon as it has the book, and
 * the page will not place an order without one. A bare `true` stub never emits, so it
 * stands in for a customer with no saved address — which is its own test below.
 */
const addressPickerStub = {
  props: ['modelValue'],
  emits: ['update:modelValue'],
  template: '<div />',
  mounted() { this.$emit('update:modelValue', 4) },
}

const mount = ({ address = true } = {}) => mountSuspended(CheckoutPage, {
  global: {
    stubs: {
      PageBar: true,
      AppImage: true,
      AddressPicker: address ? addressPickerStub : true,
    },
  },
})

const placeButton = (wrapper) => wrapper.findAll('button').find((b) => b.text().includes('Confirm payment') || b.text().includes('Placing'))
const byText = (wrapper, text) => wrapper.findAll('button').find((b) => b.text().includes(text))
/** The cancel confirmation is teleported to the body, outside the page wrapper. */
const inBody = (text) => [...document.querySelectorAll('button')].find((b) => b.textContent.includes(text))

beforeEach(() => {
  api.calls.length = 0
  toast.success.mockClear()
  sanctum.refreshIdentity.mockClear()
  globalThis.__cart = { items: [line()], total_price: '200.00' }
  globalThis.__order = order()
  globalThis.__orders = [order()]
  globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote() })
  globalThis.__checkout = () => ({ success: true, message: 'ok', errors: null, data: order() })
})

describe('checkout — when the order may be placed', () => {
  it('will not place while the quote is still in flight', async () => {
    let release
    globalThis.__quote = () => new Promise((resolve) => { release = () => resolve({ success: true, message: 'ok', errors: null, data: quote() }) })

    const wrapper = await mount()
    await flushPromises()
    expect(placeButton(wrapper).attributes('disabled')).toBeDefined()

    release()
    await flushPromises()
    expect(placeButton(wrapper).attributes('disabled')).toBeUndefined()
  })

  it('will not place while any line is out of stock', async () => {
    globalThis.__cart = { items: [line(), line({ id: 2, in_stock: false, available_stock: 0 })], total_price: '400.00' }

    const wrapper = await mount()
    await flushPromises()

    expect(placeButton(wrapper).attributes('disabled')).toBeDefined()
  })

  it('places once however many times the button is pressed', async () => {
    let release
    globalThis.__checkout = () => new Promise((resolve) => { release = () => resolve({ success: true, message: 'ok', errors: null, data: order() }) })

    const wrapper = await mount()
    await flushPromises()

    const button = placeButton(wrapper)
    await button.trigger('click')
    await button.trigger('click')
    await button.trigger('click')

    expect(api.calls.filter((call) => call.url === '/api/shop/cart/checkout')).toHaveLength(1)

    release()
    await flushPromises()
  })
})

describe('checkout — with no saved address', () => {
  it('holds the order back rather than letting the server answer with a raw field error', async () => {
    const wrapper = await mount({ address: false })
    await flushPromises()

    expect(placeButton(wrapper).attributes('disabled')).toBeDefined()
    expect(wrapper.text()).toContain('Choose a delivery address to continue.')

    await placeButton(wrapper).trigger('click')
    await flushPromises()

    expect(api.calls.filter((c) => c.path === '/api/shop/cart/checkout')).toHaveLength(0)
  })
})

describe('checkout — an order already awaiting payment', () => {
  beforeEach(async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__checkout = () => apiError(422, { cart: ['You already have an order awaiting payment.'] }, 'You already have an order awaiting payment.')
  })

  it('offers the open hold to be paid or cancelled', async () => {
    const wrapper = await mount()
    await flushPromises()
    await placeButton(wrapper).trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('An order is already waiting for payment')
    expect(wrapper.text()).toContain('You already have an order awaiting payment.')
    expect(wrapper.find('a[href$="/orders/9"]').exists()).toBe(true)
    expect(byText(wrapper, 'Pay now')).toBeDefined()
    expect(byText(wrapper, 'Cancel order')).toBeDefined()
  })

  it('paying the open hold sends the customer to the order', async () => {
    const wrapper = await mount()
    await flushPromises()
    await placeButton(wrapper).trigger('click')
    await flushPromises()

    await byText(wrapper, 'Pay now').trigger('click')
    await flushPromises()

    expect(api.calls.some((call) => call.url === '/api/shop/orders/9/pay')).toBe(true)
    expect(navigate).toHaveBeenCalledWith('/orders/9')
  })

  it('cancelling the open hold puts the customer back on a fresh quote', async () => {
    const wrapper = await mount()
    await flushPromises()
    await placeButton(wrapper).trigger('click')
    await flushPromises()

    await byText(wrapper, 'Cancel order').trigger('click')
    inBody('Yes, cancel').click()
    await flushPromises()

    expect(api.calls.some((call) => call.method === 'DELETE' && call.url === '/api/shop/orders/9')).toBe(true)
    expect(wrapper.text()).not.toContain('An order is already waiting for payment')
    expect(placeButton(wrapper)).toBeDefined()
  })
})

describe('checkout — the balance after paying', () => {
  /**
   * The customer paid, went to their profile, and read the number they had before. Both
   * surfaces the site reads a balance from — the ledger and the identity every other
   * screen shows it off — have to be refetched the moment the payment lands.
   */
  const walletReads = () => api.calls.filter((call) => call.url === '/api/wallet/transactions').length

  it('refetches the identity and the wallet ledger once the order is paid', async () => {
    const wrapper = await mount()
    await flushPromises()
    await placeButton(wrapper).trigger('click')
    await flushPromises()

    const before = walletReads()
    await byText(wrapper, 'Pay now').trigger('click')
    await flushPromises()

    expect(sanctum.refreshIdentity).toHaveBeenCalled()
    expect(walletReads()).toBeGreaterThan(before)
  })

  it('does the same for an order the wallet covered in full, which has no pay step', async () => {
    globalThis.__checkout = () => ({ success: true, message: 'ok', errors: null, data: order({ payment_status: 'paid', amount_due: '0.00', wallet_applied: '215.00' }) })

    const wrapper = await mount()
    await flushPromises()
    const before = walletReads()

    await placeButton(wrapper).trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('Your order is placed')
    expect(sanctum.refreshIdentity).toHaveBeenCalled()
    expect(walletReads()).toBeGreaterThan(before)
  })
})

describe('checkout — when the quote cannot be had', () => {
  it('offers a retry instead of leaving the summary waiting on nothing', async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__quote = () => apiError(500, {}, 'Server error')

    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.find('[data-test="quote-failed"]').exists()).toBe(true)
    expect(wrapper.find('[aria-busy="true"]').exists()).toBe(false)

    globalThis.__quote = () => ({ success: true, message: 'ok', errors: null, data: quote() })
    await byText(wrapper, 'Try again').trigger('click')
    await flushPromises()

    expect(wrapper.find('[data-test="quote-failed"]').exists()).toBe(false)
    expect(wrapper.text()).toContain('215.00 SAR')
  })
})
