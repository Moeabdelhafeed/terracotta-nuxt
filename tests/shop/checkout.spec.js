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

const mount = () => mountSuspended(CheckoutPage, {
  global: { stubs: { PageBar: true, AddressPicker: true, AppImage: true } },
})

const placeButton = (wrapper) => wrapper.findAll('button').find((b) => b.text().includes('Confirm payment') || b.text().includes('Placing'))
const byText = (wrapper, text) => wrapper.findAll('button').find((b) => b.text().includes(text))
/** The cancel confirmation is teleported to the body, outside the page wrapper. */
const inBody = (text) => [...document.querySelectorAll('button')].find((b) => b.textContent.includes(text))

beforeEach(() => {
  api.calls.length = 0
  toast.success.mockClear()
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
    expect(wrapper.find('a[href="/orders/9"]').exists()).toBe(true)
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
