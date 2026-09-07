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
const ShopFavoriteButton = (await import('~/components/shop/ShopFavoriteButton.vue')).default

beforeEach(() => {
  globalThis.__favorites = [product()]
  globalThis.__unfavorite = () => ({ success: true, message: 'Removed from favorites.', errors: null, data: null })
  api.$fetch.mockClear()
  toast.error.mockClear()
  navigate.mockClear()
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

  it('a guest is sent to log in instead of hitting a 401', async () => {
    sanctum.user.value = { data: { id: 2, is_guest: true } }
    const favorites = useFavorites()
    await flushPromises()

    await favorites.toggle(product({ id: 15, is_favorited: false }))

    expect(navigate).toHaveBeenCalledWith({ path: '/login', query: { redirect: '/shop/11' } })
    expect(api.calls.some((c) => c.url === '/api/shop/favorites/15')).toBe(false)
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
