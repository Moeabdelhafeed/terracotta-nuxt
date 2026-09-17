// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { nextTick, ref } from 'vue'

const cartState = { items: [], total_price: '0.00' }

const line = (over = {}) => ({
  id: 1,
  product: { id: 11, title: 'Cup', price: '65.00', sale_price: null, image: null, in_stock: true, stock: 12, max_quantity: 12 },
  quantity: 2,
  unit_price: '65.00',
  line_total: '130.00',
  in_stock: true,
  available_stock: 12,
  ...over,
})

const { api, lang, sanctum } = await vi.hoisted(async () => {
  const { createApiMock, envelope, apiError, createLang, createSanctumState } = await import('../helpers/mockApi')
  const state = { items: [], total_price: '0.00' }
  return {
    state,
    api: createApiMock({
      'GET /api/shop/cart': () => envelope(globalThis.__cart),
      'GET /api/shop/products/{id}': () => envelope({ id: 11, title: 'Cup', price: '65.00', sale_price: null, in_stock: true, stock: 12, max_quantity: 12 }),
      'POST /api/shop/cart': (opts) => envelope({ id: 1, quantity: opts.body.quantity }, 'Added to cart.'),
      'PUT /api/shop/cart/{id}': (opts) => envelope({ id: 1, quantity: opts.body.quantity }, 'Cart updated.'),
      'DELETE /api/shop/cart/{id}': envelope(null, 'Removed.'),
      'POST /api/shop/cart/quote': () => envelope(globalThis.__quote),
      'POST /api/shop/cart/checkout': () => globalThis.__checkout(),
      'POST /api/shop/orders/{id}/pay': () => envelope({ id: 9, status: 'pending', payment_status: 'paid', amount_due: '0.00' }, 'Payment completed successfully.'),
      'GET /api/shop/orders': () => envelope({ data: globalThis.__orders ?? [], current_page: 1, last_page: 1, total: 0 }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: ref('SAR') }))
mockNuxtImport('useToast', () => () => ({ success: vi.fn(), error: vi.fn(), info: vi.fn(), toasts: ref([]), dismiss: vi.fn() }))

const { useCart, useCheckout, lineMax, HARD_MAX_QUANTITY } = await import('~/composables/useCart')
const { localCartIds } = await import('~/composables/useLocalShop')
const ShopCartLines = (await import('~/components/shop/ShopCartLines.vue')).default
const ShopQuantityStepper = (await import('~/components/shop/ShopQuantityStepper.vue')).default

beforeEach(() => {
  globalThis.__cart = { items: [], total_price: '0.00' }
  globalThis.__quote = { subtotal: '130.00', discount_amount: '0.00', discount_code: null, delivery_fee: '15.00', total_price: '145.00', vat_rate: '15.00', vat_amount: '18.91', wallet_applied: '0.00', amount_due: '145.00' }
  globalThis.__orders = []
  localCartIds.value = []
  sanctum.user.value = { data: { id: 1, name: 'Test', is_guest: false, wallet_balance: '100.00' } }
  globalThis.__checkout = () => ({ success: true, message: 'ok', errors: null, data: { id: 9, status: 'awaiting_payment', payment_status: 'unpaid', amount_due: '145.00', payment_expires_at: new Date(Date.now() + 900000).toISOString() } })
  api.$fetch.mockClear()
})

describe('lineMax', () => {
  it('caps at the product max_quantity', () => {
    expect(lineMax(line())).toBe(12)
  })

  it('an untracked product still cannot exceed the hard 100', () => {
    expect(lineMax(line({ product: { max_quantity: 100, stock: null } }))).toBe(HARD_MAX_QUANTITY)
  })
})

describe('useCart', () => {
  it('POST adds (the server increments), PUT sets the quantity outright', async () => {
    const cart = useCart()
    await flushPromises()
    api.$fetch.mockClear()

    await cart.add(11, 3)
    await cart.update(1, 5)

    const mutations = api.calls.filter((c) => c.url.startsWith('/api/shop/cart') && c.method !== 'GET')
    expect(mutations[0]).toMatchObject({ method: 'POST', url: '/api/shop/cart', body: { shop_product_id: 11, quantity: 3 } })
    expect(mutations[1]).toMatchObject({ method: 'PUT', url: '/api/shop/cart/1', body: { quantity: 5 } })
  })

  it('sends the chosen glaze as the variant id, and nothing when there is none', async () => {
    const cart = useCart()
    await flushPromises()
    await cart.add(11, 1)
    const plain = api.calls.find((c) => c.method === 'POST' && c.url === '/api/shop/cart')
    expect(Object.keys(plain.body)).toEqual(['shop_product_id', 'quantity'])

    await cart.add(11, 1, '#81341a')
    const glazed = api.calls.filter((c) => c.method === 'POST' && c.url === '/api/shop/cart').at(-1)
    expect(glazed.body).toEqual({ shop_product_id: 11, quantity: 1, color: '#81341a' })
  })

  it('blocks checkout while any line cannot be fulfilled', async () => {
    globalThis.__cart = { items: [line(), line({ id: 2, in_stock: false, available_stock: 0 })], total_price: '195.00' }
    const cart = useCart()
    await cart.refresh()
    expect(cart.hasOutOfStock.value).toBe(true)
    expect(cart.canCheckout.value).toBe(false)
  })

  it('allows checkout once every line is in stock', async () => {
    globalThis.__cart = { items: [line()], total_price: '130.00' }
    const cart = useCart()
    await cart.refresh()
    expect(cart.canCheckout.value).toBe(true)
    expect(cart.count.value).toBe(2)
  })
})

describe('useCart — the guest basket', () => {
  it('a visitor with no account keeps the basket in the browser', async () => {
    sanctum.user.value = null
    const cart = useCart()
    await flushPromises()
    const before = api.calls.length

    await cart.add(11, 2)
    await flushPromises()

    expect(api.calls.slice(before).some((c) => c.method !== 'GET')).toBe(false)
    expect(localCartIds.value).toEqual([{ id: 11, quantity: 2 }])
    expect(cart.count.value).toBe(2)
    expect(cart.items.value[0]).toMatchObject({ id: 11, quantity: 2, unit_price: '65.00', line_total: '130.00' })
    expect(cart.total.value).toBe('130.00')
    expect(cart.canCheckout.value).toBe(true)
  })

  it('a signed-in customer reads the server basket, never the local one', async () => {
    localCartIds.value = [{ id: 11, quantity: 9 }]
    globalThis.__cart = { items: [line()], total_price: '130.00' }
    const cart = useCart()
    await cart.refresh()
    await flushPromises()

    expect(cart.count.value).toBe(2)
    expect(cart.items.value[0].id).toBe(1)
  })
})

describe('ShopCartLines', () => {
  it('renders a sold-out line rather than hiding it, and explains why', async () => {
    globalThis.__cart = { items: [line({ in_stock: false, available_stock: 0 })], total_price: '130.00' }
    const wrapper = await mountSuspended(ShopCartLines)
    await flushPromises()
    expect(wrapper.findAll('li')).toHaveLength(1)
    expect(wrapper.text()).toContain('Sold out')
    expect(wrapper.find('li').classes().join(' ')).toContain('border-destructive/40')
  })

  it('shows the server stock refusal verbatim on the line that earned it', async () => {
    globalThis.__cart = { items: [line()], total_price: '130.00' }
    api.table['PUT /api/shop/cart/{id}'] = { error: { status: 422, body: { success: false, message: 'Only 2 left of "Cup".', errors: { cart: ['Only 2 left of "Cup".'] }, data: null } } }
    const wrapper = await mountSuspended(ShopCartLines)
    await flushPromises()

    await wrapper.findAll('button').at(-1).trigger('click') // the stepper's plus
    await flushPromises()
    expect(wrapper.text()).toContain('Only 2 left of "Cup".')

    api.table['PUT /api/shop/cart/{id}'] = (opts) => ({ success: true, message: 'ok', errors: null, data: { id: 1, quantity: opts.body.quantity } })
  })

  it('asks before taking a line out, and removes it only once confirmed', async () => {
    globalThis.__cart = { items: [line()], total_price: '130.00' }
    const wrapper = await mountSuspended(ShopCartLines)
    await flushPromises()

    await wrapper.find('button[aria-label="Remove from cart"]').trigger('click')
    expect(wrapper.text()).toContain('taken out of your cart')
    expect(api.calls.some((c) => c.method === 'DELETE')).toBe(false)

    await wrapper.findAll('button').find((b) => b.text() === 'Take it out').trigger('click')
    await flushPromises()
    expect(api.calls.some((c) => c.method === 'DELETE' && c.url === '/api/shop/cart/1')).toBe(true)
  })
})

describe('ShopQuantityStepper', () => {
  it('will not step past max', async () => {
    const wrapper = await mountSuspended(ShopQuantityStepper, { props: { modelValue: 3, max: 3 } })
    const plus = wrapper.findAll('button').at(1)
    expect(plus.attributes('disabled')).toBeDefined()
  })
})

describe('useCheckout', () => {
  it('re-quotes when the discount code, the wallet flag or the address changes', async () => {
    globalThis.__cart = { items: [line()], total_price: '130.00' }
    const flow = useCheckout()
    await flow.cart.refresh()
    await flushPromises()
    const before = api.calls.filter((c) => c.url === '/api/shop/cart/quote').length

    flow.discountCode.value = 'WELCOME10'
    await nextTick(); await flushPromises()
    flow.useWallet.value = true
    await nextTick(); await flushPromises()
    flow.addressId.value = 4
    await nextTick(); await flushPromises()

    const quotes = api.calls.filter((c) => c.url === '/api/shop/cart/quote')
    expect(quotes.length).toBe(before + 3)
    expect(quotes.at(-1).body).toEqual({ address_id: 4, use_wallet: true, discount_code: 'WELCOME10' })
  })

  it('a fully covered checkout settles on creation and clears the cart — no /pay', async () => {
    globalThis.__cart = { items: [line()], total_price: '130.00' }
    localCartIds.value = []
  sanctum.user.value = { data: { id: 1, name: 'Test', is_guest: false, wallet_balance: '100.00' } }
  globalThis.__checkout = () => ({ success: true, message: 'ok', errors: null, data: { id: 9, status: 'pending', payment_status: 'paid', amount_due: '0.00', payment_expires_at: null } })
    const flow = useCheckout()
    await flow.cart.refresh()
    await flushPromises()

    globalThis.__cart = { items: [], total_price: '0.00' }
    await flow.checkout()
    await flushPromises()

    expect(flow.settled.value).toBe(true)
    expect(api.calls.some((c) => c.url.includes('/pay'))).toBe(false)
    expect(flow.cart.items.value).toHaveLength(0)
  })

  it('the cart survives checkout and is only refetched after /pay', async () => {
    globalThis.__cart = { items: [line()], total_price: '130.00' }
    const flow = useCheckout()
    await flow.cart.refresh()
    await flushPromises()

    await flow.checkout()
    await flushPromises()
    // Still held: the server keeps the lines until the order is paid.
    expect(flow.settled.value).toBe(false)
    expect(flow.cart.items.value).toHaveLength(1)

    globalThis.__cart = { items: [], total_price: '0.00' }
    await flow.pay()
    await flushPromises()
    expect(flow.cart.items.value).toHaveLength(0)
  })

  it('a second checkout surfaces the open hold with the order it refers to', async () => {
    globalThis.__cart = { items: [line()], total_price: '130.00' }
    globalThis.__orders = [{ id: 7, status: 'awaiting_payment', amount_due: '145.00', payment_status: 'unpaid' }]
    globalThis.__checkout = () => {
      const err = new Error('You already have an order waiting for payment. Pay or cancel it first.')
      err.status = 422
      err.statusCode = 422
      err.data = { success: false, message: err.message, errors: { cart: ['You already have an order waiting for payment. Pay or cancel it first.'] }, data: null }
      throw err
    }
    const flow = useCheckout()
    await flow.cart.refresh()
    await flushPromises()

    await expect(flow.checkout()).rejects.toMatchObject({ status: 422 })
    await flushPromises()

    expect(flow.errors.value.cart?.[0]).toContain('already have an order waiting')
    expect(flow.resumed.value).toBe(true)
    expect(flow.order.value.id).toBe(7)
  })
})
