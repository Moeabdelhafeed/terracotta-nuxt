// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const api = await vi.hoisted(async () => {
  const { createApiMock, envelope, apiError, bareError } = await import('../helpers/mockApi')
  return createApiMock({
    'POST /api/shop/cart': envelope({ id: 9, quantity: 2 }, 'Product added to cart.'),
    'POST /api/shop/cart/checkout': apiError(422, { cart: ['You already have an order waiting for payment. Pay or cancel it first.'] }, 'You already have an order waiting for payment. Pay or cancel it first.'),
    'POST /api/shop/orders/{id}/pay': bareError(422, { order: ['This payment window has closed. Please start again.'] }, 'This payment window has closed. Please start again.'),
    'GET /api/shop/orders': envelope({ current_page: 2, last_page: 5, total: 42, data: [{ id: 1 }, { id: 2 }] }),
    'GET /api/addresses': envelope([{ id: 1 }, { id: 2 }, { id: 3 }]),
  })
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)

const { useSubmit, normalizeApiError, fieldError, unwrapList, useApiList } = await import('~/composables/useSubmit')

describe('useSubmit', () => {
  it('resolves { data, message } from the envelope', async () => {
    const { submit, pending, message } = useSubmit()
    const res = await submit(() => api.useApi()('/api/shop/cart', { method: 'POST', body: { shop_product_id: 1 } }))
    expect(res.data).toEqual({ id: 9, quantity: 2 })
    expect(res.message).toBe('Product added to cart.')
    expect(message.value).toBe('Product added to cart.')
    expect(pending.value).toBe(false)
  })

  it('exposes field-keyed errors from the envelope shape', async () => {
    const { submit, errors, error, fieldError: field } = useSubmit()
    await expect(submit(() => api.useApi()('/api/shop/cart/checkout', { method: 'POST' }))).rejects.toMatchObject({ status: 422 })
    expect(errors.value.cart[0]).toMatch(/waiting for payment/)
    expect(field('cart')).toMatch(/waiting for payment/)
    expect(error.value).toMatch(/waiting for payment/)
  })

  it('reads the bare Laravel shape that /pay returns', async () => {
    const { submit, errors } = useSubmit()
    await expect(submit(() => api.useApi()('/api/shop/orders/4/pay', { method: 'POST' }))).rejects.toMatchObject({ status: 422 })
    expect(fieldError(errors.value, 'order')).toBe('This payment window has closed. Please start again.')
  })

  it('normalizes an error without a body', () => {
    const normalized = normalizeApiError(new Error('Network'))
    expect(normalized.errors).toEqual({})
    expect(normalized.message).toBe('Network')
  })
})

describe('unwrapList', () => {
  it('accepts an array or a paginator', () => {
    expect(unwrapList([{ id: 1 }])).toEqual({ items: [{ id: 1 }], page: 1, lastPage: 1, total: 1 })
    expect(unwrapList({ current_page: 3, last_page: 4, total: 40, data: [{ id: 9 }] })).toEqual({ items: [{ id: 9 }], page: 3, lastPage: 4, total: 40 })
    expect(unwrapList(null).items).toEqual([])
  })
})

describe('useApiList', () => {
  it('normalizes a paginated endpoint', async () => {
    const list = useApiList('/api/shop/orders', { key: 'orders', query: { page: 2, per_page: 10 } })
    await vi.waitFor(() => expect(list.items.value.length).toBe(2))
    expect(list.page.value).toBe(2)
    expect(list.lastPage.value).toBe(5)
    expect(list.total.value).toBe(42)
    expect(api.calls.at(-1).query).toEqual({ page: 2, per_page: 10 })
  })

  it('normalizes a plain-array endpoint', async () => {
    const list = useApiList('/api/addresses', { key: 'addresses' })
    await vi.waitFor(() => expect(list.items.value.length).toBe(3))
    expect(list.lastPage.value).toBe(1)
  })
})
