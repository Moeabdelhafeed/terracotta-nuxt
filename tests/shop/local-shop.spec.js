// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang, refreshNuxtData } = await vi.hoisted(async () => {
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/shop/products/11': () => globalThis.__product(11),
      'GET /api/shop/products/12': () => globalThis.__product(12),
      'GET /api/shop/products/{id}': () => notFound(),
      'POST /api/shop/cart': (opts) => envelope({ id: 1, quantity: opts.body.quantity }, 'Added to cart.'),
      'POST /api/shop/favorites/{id}': envelope(null, 'Added to favorites.'),
    }),
    lang: createLang('en'),
    refreshNuxtData: v.fn(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('refreshNuxtData', () => refreshNuxtData)

const { localCartIds, localFavoriteIds, useLocalCart, useLocalFavorites, pushLocalShopToServer } = await import('~/composables/useLocalShop')

const catalogue = {
  11: { id: 11, title: 'Cup', price: '65.00', sale_price: '50.50', in_stock: true, stock: 1, max_quantity: 12 },
  12: { id: 12, title: 'Bowl', price: '120.00', sale_price: null, in_stock: true, stock: null, max_quantity: null },
}

const notFound = (message = 'Shop product not found.') => ({ error: { status: 404, body: { success: false, message, errors: null, data: null } } })
const exploded = { error: { status: 500, body: { success: false, message: 'Server exploded.', errors: null, data: null } } }

beforeEach(async () => {
  globalThis.__product = (id) => ({ success: true, message: 'ok', errors: null, data: catalogue[id] })
  localCartIds.value = []
  localFavoriteIds.value = []
  await useLocalCart().refresh()
  api.calls.length = 0
  refreshNuxtData.mockClear()
})

describe('local cart hydration', () => {
  it('builds a line in the server presenter shape, on the sale price and exact halalas', async () => {
    localCartIds.value = [{ id: 11, quantity: 3 }]
    await flushPromises()

    const cart = useLocalCart()
    expect(cart.items.value).toHaveLength(1)
    expect(cart.items.value[0]).toMatchObject({
      id: 11,
      quantity: 3,
      unit_price: '50.50',
      line_total: '151.50',
      in_stock: false, // only 1 left of the 3 asked for
      available_stock: 1,
    })
    expect(cart.items.value[0].product.title).toBe('Cup')
    expect(cart.total.value).toBe('151.50')
    expect(cart.count.value).toBe(3)
    expect(cart.canCheckout.value).toBe(false)
  })

  it('an untracked product is in stock at any quantity and totals across lines', async () => {
    localCartIds.value = [{ id: 12, quantity: 2 }]
    await flushPromises()

    const cart = useLocalCart()
    expect(cart.items.value[0]).toMatchObject({ unit_price: '120.00', line_total: '240.00', in_stock: true, available_stock: null })
    expect(cart.total.value).toBe('240.00')
    expect(cart.canCheckout.value).toBe(true)
  })

  it('fetches each stored id once, through the public catalogue route', async () => {
    localCartIds.value = [{ id: 12, quantity: 1 }]
    localFavoriteIds.value = [12]
    await flushPromises()

    expect(api.calls.filter((call) => call.url === '/api/shop/products/12')).toHaveLength(1)
  })

  it('drops a product the catalogue no longer has, for good', async () => {
    localCartIds.value = [{ id: 12, quantity: 1 }, { id: 99, quantity: 1 }]
    localFavoriteIds.value = [99]
    await flushPromises()

    expect(localCartIds.value).toEqual([{ id: 12, quantity: 1 }])
    expect(localFavoriteIds.value).toEqual([])
    expect(useLocalCart().items.value).toHaveLength(1)
  })

  it('keeps the id when the fetch failed for any other reason', async () => {
    globalThis.__product = () => exploded
    localCartIds.value = [{ id: 11, quantity: 1 }]
    await flushPromises()

    expect(localCartIds.value).toEqual([{ id: 11, quantity: 1 }])
    expect(useLocalCart().items.value).toHaveLength(0)
  })
})

describe('local cart writes', () => {
  it('add increments an existing line the way the server does', async () => {
    const cart = useLocalCart()
    await cart.add(11, 2)
    await cart.add(11, 1)
    await flushPromises()

    expect(localCartIds.value).toEqual([{ id: 11, quantity: 3 }])
    expect(cart.items.value[0].quantity).toBe(3)
  })

  it('never goes past the product cap', async () => {
    const cart = useLocalCart()
    await cart.add(11, 5)
    await flushPromises() // the cap is only known once the product is hydrated
    const res = await cart.add(11, 40)

    expect(localCartIds.value).toEqual([{ id: 11, quantity: 12 }])
    expect(res).toMatchObject({ success: true, data: { id: 11, quantity: 12 } })
  })

  it('an untracked product still cannot exceed the hard 100', async () => {
    const cart = useLocalCart()
    await cart.add(12, 1)
    await flushPromises()
    await cart.update(12, 500)

    expect(localCartIds.value).toEqual([{ id: 12, quantity: 100 }])
  })

  it('the same piece in another glaze is another line, keyed by the hex', async () => {
    const cart = useLocalCart()
    await cart.add(11, 1, '#81341a')
    await cart.add(11, 2, '#345a4a')
    await cart.add(11, 1, '#81341a')
    await flushPromises()

    expect(localCartIds.value).toEqual([
      { id: 11, quantity: 2, color: '#81341a' },
      { id: 11, quantity: 2, color: '#345a4a' },
    ])
    expect(cart.items.value.map((line) => line.id)).toEqual(['11::#81341a', '11::#345a4a'])
    expect(cart.items.value[0].color).toBe('#81341a')

    await cart.update('11::#345a4a', 5)
    expect(localCartIds.value[1]).toEqual({ id: 11, quantity: 5, color: '#345a4a' })

    await cart.remove('11::#81341a')
    expect(localCartIds.value).toEqual([{ id: 11, quantity: 5, color: '#345a4a' }])
  })

  it('update sets the quantity outright and remove drops the line', async () => {
    const cart = useLocalCart()
    await cart.add(12, 1)
    await cart.update(12, 4)
    expect(localCartIds.value).toEqual([{ id: 12, quantity: 4 }])

    await cart.remove(12)
    expect(localCartIds.value).toEqual([])
  })

  it('writes nothing to the server', async () => {
    const cart = useLocalCart()
    await cart.add(11, 1)
    await cart.update(11, 2)
    await cart.remove(11)

    expect(api.calls.every((call) => call.method === 'GET')).toBe(true)
  })
})

describe('local favorites', () => {
  it('toggle flips the id and answers the new state, newest first', async () => {
    const favorites = useLocalFavorites()

    expect(await favorites.toggle(catalogue[11])).toBe(true)
    expect(await favorites.toggle(catalogue[12])).toBe(true)
    await flushPromises()

    expect(favorites.isFavorited(catalogue[11])).toBe(true)
    expect(favorites.favorites.value.map((product) => product.id)).toEqual([12, 11])

    expect(await favorites.toggle(catalogue[11])).toBe(false)
    expect(localFavoriteIds.value).toEqual([12])
  })
})

describe('pushLocalShopToServer', () => {
  it('replays every line and heart, then empties the local stores', async () => {
    localCartIds.value = [{ id: 11, quantity: 2 }, { id: 12, quantity: 1 }]
    localFavoriteIds.value = [12]
    await flushPromises()

    const result = await pushLocalShopToServer(api.useApi())

    expect(result).toEqual({ pushedLines: 2, pushedFavorites: 1, dropped: 0 })
    expect(api.calls.filter((call) => call.url === '/api/shop/cart').map((call) => call.body)).toEqual([
      { shop_product_id: 11, quantity: 2 },
      { shop_product_id: 12, quantity: 1 },
    ])
    expect(api.calls.some((call) => call.method === 'POST' && call.url === '/api/shop/favorites/12')).toBe(true)
    expect(localCartIds.value).toEqual([])
    expect(localFavoriteIds.value).toEqual([])
    expect(refreshNuxtData).toHaveBeenCalledWith(['cart', 'favorites'])
  })

  it('a refused line is dropped without taking the rest with it', async () => {
    api.table['POST /api/shop/cart'] = (opts) => (opts.body.shop_product_id === 11
      ? notFound()
      : { success: true, message: 'ok', errors: null, data: { id: 1 } })
    localCartIds.value = [{ id: 11, quantity: 2 }, { id: 12, quantity: 1 }]
    localFavoriteIds.value = [11]
    api.table['POST /api/shop/favorites/{id}'] = { error: { status: 422, body: { success: false, message: 'Already there.', errors: {}, data: null } } }
    await flushPromises()

    const result = await pushLocalShopToServer(api.useApi())

    expect(result).toEqual({ pushedLines: 1, pushedFavorites: 0, dropped: 2 })
    expect(localCartIds.value).toEqual([])

    api.table['POST /api/shop/cart'] = (opts) => ({ success: true, message: 'ok', errors: null, data: { id: 1, quantity: opts.body.quantity } })
    api.table['POST /api/shop/favorites/{id}'] = { success: true, message: 'ok', errors: null, data: null }
  })

  it('replays the glaze with the line', async () => {
    localCartIds.value = [{ id: 11, quantity: 1, color: '#81341a' }]
    await flushPromises()

    await pushLocalShopToServer(api.useApi())

    expect(api.calls.filter((call) => call.url === '/api/shop/cart').map((call) => call.body)).toEqual([
      { shop_product_id: 11, quantity: 1, color: '#81341a' },
    ])
  })

  it('keeps the stores when there is nothing to replay', async () => {
    const result = await pushLocalShopToServer(api.useApi())

    expect(result).toEqual({ pushedLines: 0, pushedFavorites: 0, dropped: 0 })
    expect(refreshNuxtData).not.toHaveBeenCalled()
  })
})
