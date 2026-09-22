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
      // The local basket refetches its products from the public catalogue; without this
      // the mock 404s and the guest's line is pruned as "gone" the moment it is added.
      'GET /api/shop/products/{id}': () => envelope({ id: 11, title: 'Cup', price: '45.00', in_stock: true, stock: 40, max_quantity: 40 }),
      'POST /api/shop/cart': () => globalThis.__add(),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
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
mockNuxtImport('navigateTo', () => navigate)
mockNuxtImport('useRoute', () => () => ({ params: { id: '11' }, query: {}, fullPath: '/shop/11' }))

const ShopAddToCart = (await import('~/components/shop/ShopAddToCart.vue')).default
// The storage ref is a module singleton and this env's `localStorage` is a stub whose
// `clear` is not a function — the ref has to be emptied by hand between cases.
const { localCartIds } = await import('~/composables/useLocalShop')

const product = (over = {}) => ({ id: 11, title: 'Cup', in_stock: true, stock: 40, max_quantity: 40, ...over })

const mount = (over, props) => mountSuspended(ShopAddToCart, { props: { product: product(over), ...props } })
const addButton = (wrapper) => wrapper.findAll('button').find((b) => b.text() === 'Add' || b.text() === 'Adding…')

beforeEach(() => {
  globalThis.__cart = { items: [], total_price: '0.00' }
  api.calls.length = 0
  navigate.mockClear()
  localCartIds.value = []
  sanctum.user.value = { data: { id: 1, name: 'Sara', is_guest: false } }
  globalThis.__add = () => ({ success: true, message: 'Added.', errors: null, data: { id: 1 } })
})

describe('ShopAddToCart — what the stock says', () => {
  it('claims no number for untracked stock', async () => {
    const wrapper = await mount({ stock: null, max_quantity: 100 })
    expect(wrapper.text()).not.toContain('left')
    expect(addButton(wrapper).attributes('disabled')).toBeUndefined()
  })

  it('stays quiet while there is plenty', async () => {
    const wrapper = await mount({ stock: 40 })
    expect(wrapper.text()).not.toContain('left')
  })

  it('warns once the shelf is nearly empty', async () => {
    const wrapper = await mount({ stock: 3, max_quantity: 3 })
    expect(wrapper.text()).toContain('Only 3 left')
  })

  it('refuses a sold-out product', async () => {
    const wrapper = await mount({ in_stock: false, stock: 0, max_quantity: 0 })
    expect(wrapper.text()).toContain('Sold out')
    expect(addButton(wrapper).attributes('disabled')).toBeDefined()

    await addButton(wrapper).trigger('click')
    await flushPromises()
    expect(api.calls.some((call) => call.method === 'POST')).toBe(false)
  })
})

describe('ShopAddToCart — who may add', () => {
  it('drops a guest\u2019s pick into the local basket instead of bouncing them to log in', async () => {
    sanctum.user.value = { data: { id: 2, is_guest: true } }
    const wrapper = await mount()

    await addButton(wrapper).trigger('click')
    await flushPromises()

    expect(navigate).not.toHaveBeenCalled()
    expect(api.calls.some((call) => call.method === 'POST')).toBe(false)
    expect(localCartIds.value).toEqual([{ id: 11, quantity: 1 }])
  })

  it('does the same for an anonymous visitor', async () => {
    sanctum.user.value = null
    const wrapper = await mount()

    await addButton(wrapper).trigger('click')
    await flushPromises()

    expect(navigate).not.toHaveBeenCalled()
    expect(localCartIds.value).toEqual([{ id: 11, quantity: 1 }])
  })

  it('adds the chosen quantity for a registered customer, then offers the cart', async () => {
    const wrapper = await mount()

    await addButton(wrapper).trigger('click')
    await flushPromises()

    const post = api.calls.find((call) => call.method === 'POST' && call.url === '/api/shop/cart')
    expect(post.body).toEqual({ shop_product_id: 11, quantity: 1 })
    expect(navigate).not.toHaveBeenCalled()
    expect(wrapper.find('a[href$="/cart"]').exists()).toBe(true)
  })

  it("shows the server's stock refusal verbatim", async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__add = () => apiError(422, { cart: ['Only 2 of “Cup” are left.'] })

    const wrapper = await mount()
    await addButton(wrapper).trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('Only 2 of “Cup” are left.')
    expect(wrapper.find('a[href$="/cart"]').exists()).toBe(false)
  })
})

describe('ShopAddToCart — the colours are a legend, not a variant', () => {
  it('sends the product and the quantity, with no colour on the line', async () => {
    const wrapper = await mount({ colors: ['#81341a', '#345a4a'] })

    await addButton(wrapper).trigger('click')
    await flushPromises()

    const post = api.calls.find((call) => call.method === 'POST' && call.url === '/api/shop/cart')
    expect(post.body).toEqual({ shop_product_id: 11, quantity: 1 })
  })

  /**
   * The colourway is display metadata on the product: the cart table has no colour
   * column and the endpoint takes none, so two glazes of one piece are one basket line.
   * Keeping them apart locally invented a line the account could never hold, and gave
   * each its own stock ceiling.
   */
  it('folds two glazes of one piece into a single guest basket line', async () => {
    sanctum.user.value = null

    const first = await mount({}, { colour: '#81341a' })
    await addButton(first).trigger('click')
    await flushPromises()

    const second = await mount({}, { colour: '#345a4a' })
    await addButton(second).trigger('click')
    await flushPromises()

    expect(localCartIds.value).toEqual([{ id: 11, quantity: 2 }])
  })
})

describe('ShopAddToCart — what the cart already holds', () => {
  it('counts it, and takes it off what the stepper may ask for', async () => {
    globalThis.__cart = {
      items: [{ id: 1, product: { id: 11, max_quantity: 4 }, quantity: 3, unit_price: '45.00', line_total: '135.00', in_stock: true }],
      total_price: '135.00',
    }
    const wrapper = await mount({ stock: 4, max_quantity: 4 })
    await flushPromises()

    expect(wrapper.text()).toContain('3 of this already in your cart')
    // One left of the four the server will take, so the plus is already at its ceiling.
    expect(wrapper.findAll('button').find((b) => b.attributes('aria-label') === 'Increase quantity').attributes('disabled')).toBeDefined()
    expect(addButton(wrapper).attributes('disabled')).toBeUndefined()
  })

  it('goes dead, and says why, once the cart holds the cap', async () => {
    globalThis.__cart = {
      items: [{ id: 1, product: { id: 11, max_quantity: 4 }, quantity: 4, unit_price: '45.00', line_total: '180.00', in_stock: true }],
      total_price: '180.00',
    }
    const wrapper = await mount({ stock: 4, max_quantity: 4 })
    await flushPromises()

    expect(wrapper.text()).toContain('you already have 4 of this in your cart')
    expect(addButton(wrapper).attributes('disabled')).toBeDefined()
  })
})
