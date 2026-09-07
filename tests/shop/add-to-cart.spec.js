// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang, sanctum, toast, navigate } = await vi.hoisted(async () => {
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/shop/cart': () => envelope({ items: [], total_price: '0.00' }),
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

const product = (over = {}) => ({ id: 11, title: 'Cup', in_stock: true, stock: 40, max_quantity: 40, ...over })

const mount = (over) => mountSuspended(ShopAddToCart, { props: { product: product(over) } })
const addButton = (wrapper) => wrapper.findAll('button').find((b) => b.text() === 'Add' || b.text() === 'Adding…')

beforeEach(() => {
  api.calls.length = 0
  navigate.mockClear()
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
  it('sends a guest to log in rather than to a 401', async () => {
    sanctum.user.value = { data: { id: 2, is_guest: true } }
    const wrapper = await mount()

    await addButton(wrapper).trigger('click')
    await flushPromises()

    expect(navigate).toHaveBeenCalledWith({ path: '/login', query: { redirect: '/shop/11' } })
    expect(api.calls.some((call) => call.method === 'POST')).toBe(false)
  })

  it('sends an anonymous visitor to log in too', async () => {
    sanctum.user.value = null
    const wrapper = await mount()

    await addButton(wrapper).trigger('click')
    await flushPromises()

    expect(navigate).toHaveBeenCalledWith({ path: '/login', query: { redirect: '/shop/11' } })
  })

  it('adds the chosen quantity for a registered customer, then offers the cart', async () => {
    const wrapper = await mount()

    await addButton(wrapper).trigger('click')
    await flushPromises()

    const post = api.calls.find((call) => call.method === 'POST' && call.url === '/api/shop/cart')
    expect(post.body).toEqual({ shop_product_id: 11, quantity: 1 })
    expect(navigate).not.toHaveBeenCalled()
    expect(wrapper.find('a[href="/cart"]').exists()).toBe(true)
  })

  it("shows the server's stock refusal verbatim", async () => {
    const { apiError } = await import('../helpers/mockApi')
    globalThis.__add = () => apiError(422, { cart: ['Only 2 of “Cup” are left.'] })

    const wrapper = await mount()
    await addButton(wrapper).trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('Only 2 of “Cup” are left.')
    expect(wrapper.find('a[href="/cart"]').exists()).toBe(false)
  })
})
