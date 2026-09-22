// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

const product = (over = {}) => ({ id: 11, title: 'Cup', price: '65.00', sale_price: null, image: null, is_featured: true, is_favorited: true, in_stock: true, stock: 12, max_quantity: 12, ...over })

const { api, lang, sanctum, toast, navigate } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  const { vi: v } = await import('vitest')
  return {
    api: createApiMock({
      'GET /api/shop/favorites': () => envelope(globalThis.__favorites),
      'GET /api/shop/products/{id}': () => envelope({ id: 15, title: 'Jug', price: '80.00', sale_price: null, in_stock: true, stock: 3, max_quantity: 3 }),
      'POST /api/shop/favorites/{id}': envelope(null, 'Added to favorites.'),
      'DELETE /api/shop/favorites/{id}': () => globalThis.__unfavorite(),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
    toast: { success: v.fn(), error: v.fn(), info: v.fn(), toasts: { value: [] }, dismiss: v.fn() },
    navigate: v.fn(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useToast', () => () => toast)
mockNuxtImport('navigateTo', () => navigate)
mockNuxtImport('useRoute', () => () => ({ fullPath: '/shop/11', params: {}, query: {} }))

const { useFavorites } = await import('~/composables/useFavorites')
const { localFavoriteIds } = await import('~/composables/useLocalShop')
const ShopFavoriteButton = (await import('~/components/shop/ShopFavoriteButton.vue')).default

beforeEach(() => {
  globalThis.__favorites = [product()]
  globalThis.__unfavorite = () => ({ success: true, message: 'Removed from favorites.', errors: null, data: null })
  api.$fetch.mockClear()
  toast.error.mockClear()
  navigate.mockClear()
  localFavoriteIds.value = []
  // A registered session again for every test — the guest case must not leak forward.
  sanctum.user.value = { data: { id: 1, name: 'Test', is_guest: false, wallet_balance: '100.00' } }
})

describe('useFavorites', () => {
  it('a tap flips the heart before the call and posts the right verb', async () => {
    const favorites = useFavorites()
    await flushPromises()
    const cold = product({ id: 12, is_favorited: false })

    const promise = favorites.toggle(cold)
    expect(favorites.isFavorited(cold)).toBe(true) // optimistic, before the round trip
    await promise

    expect(api.calls.at(-1)).toMatchObject({ method: 'POST', url: '/api/shop/favorites/12' })
  })

  it('a DELETE that 404s means it was already gone — the heart stays off', async () => {
    globalThis.__unfavorite = () => {
      const err = new Error('Favorite not found.')
      err.status = 404
      err.statusCode = 404
      err.data = { success: false, message: 'Favorite not found.', errors: null, data: null }
      throw err
    }
    const favorites = useFavorites()
    await flushPromises()
    const hot = product({ id: 13 })

    await favorites.toggle(hot)

    expect(favorites.isFavorited(hot)).toBe(false)
    expect(toast.error).not.toHaveBeenCalled()
  })

  it('any other failure rolls the heart back and says so', async () => {
    globalThis.__unfavorite = () => {
      const err = new Error('Server exploded.')
      err.status = 500
      err.statusCode = 500
      err.data = { success: false, message: 'Server exploded.', errors: null, data: null }
      throw err
    }
    const favorites = useFavorites()
    await flushPromises()
    const hot = product({ id: 14 })

    await favorites.toggle(hot)

    expect(favorites.isFavorited(hot)).toBe(true)
    expect(toast.error).toHaveBeenCalledWith('Server exploded.')
  })

  it('the list drops an unhearted entry without a refetch', async () => {
    const favorites = useFavorites()
    await flushPromises()
    expect(favorites.favorites.value).toHaveLength(1)

    await favorites.toggle(favorites.favorites.value[0])
    expect(favorites.favorites.value).toHaveLength(0)
  })

  it('a guest hearts into the browser rather than being sent to log in', async () => {
    sanctum.user.value = { data: { id: 2, is_guest: true } }
    const favorites = useFavorites()
    await flushPromises()
    const cold = product({ id: 15, is_favorited: false })

    expect(await favorites.toggle(cold)).toBe(true)
    await flushPromises()

    expect(navigate).not.toHaveBeenCalled()
    expect(api.calls.some((c) => c.url === '/api/shop/favorites/15')).toBe(false)
    expect(localFavoriteIds.value).toEqual([15])
    expect(favorites.isFavorited(cold)).toBe(true)
    expect(favorites.favorites.value.map((p) => p.id)).toEqual([15])
  })

  it('a guest un-hearts back out of the browser', async () => {
    sanctum.user.value = null
    const favorites = useFavorites()
    const hot = product({ id: 15, is_favorited: false })

    await favorites.toggle(hot)
    expect(await favorites.toggle(hot)).toBe(false)

    expect(localFavoriteIds.value).toEqual([])
    expect(favorites.favorites.value).toHaveLength(0)
  })
})

describe('ShopFavoriteButton', () => {
  it('reflects is_favorited and flips on click', async () => {
    const wrapper = await mountSuspended(ShopFavoriteButton, { props: { product: product({ id: 21, is_favorited: false }) } })
    expect(wrapper.attributes('aria-pressed')).toBe('false')

    await wrapper.find('button').trigger('click')
    await flushPromises()
    expect(wrapper.attributes('aria-pressed')).toBe('true')
  })
})

/**
 * The two storefronts share one products table and one favourites endpoint, so a hearted
 * bag of clay comes back in the same list as a hearted mug. Only `section` says which
 * shelf it belongs to — and `/api/shop/products/{id}` 404s for a material, so a card that
 * ignores it sends the customer to an error page.
 */
describe('ProductCard — which shelf a favourite links back to', () => {
  const ProductCard = () => import('~/components/ProductCard.vue').then((m) => m.default)

  const card = async (product, props = {}) =>
    mountSuspended(await ProductCard(), { props: { product, ...props } })

  it('links a material to the materials shelf, whatever the list default is', async () => {
    const wrapper = await card({ id: 7, title: 'Stoneware clay', price: '30.00', section: 'materials' })
    expect(wrapper.find('a').attributes('href')).toMatch(/\/materials\/7$/)
  })

  it('links a shop piece to the shop', async () => {
    const wrapper = await card({ id: 7, title: 'Mug', price: '30.00', section: 'shop' })
    expect(wrapper.find('a').attributes('href')).toMatch(/\/shop\/7$/)
  })

  it('falls back to the list it was given when the API sends no section', async () => {
    const wrapper = await card({ id: 7, title: 'Mug', price: '30.00' }, { base: '/materials' })
    expect(wrapper.find('a').attributes('href')).toMatch(/\/materials\/7$/)
  })
})
