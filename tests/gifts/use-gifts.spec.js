// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api } = await vi.hoisted(async () => {
  const { createApiMock, envelope, apiError } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/gifts/package': envelope({ amount: '200.00', is_active: true }),
      'GET /api/gifts': envelope({
        current_page: 1,
        last_page: 2,
        total: 12,
        data: [{ id: 3, recipient_name: 'Sara', status: 'paid' }],
      }),
      'POST /api/gifts/quote': (opts) => envelope({
        subtotal: '200.00',
        discount_amount: opts.body.discount_code ? '20.00' : '0.00',
        discount_code: opts.body.discount_code ?? null,
        delivery_fee: '0.00',
        total_price: opts.body.discount_code ? '180.00' : '200.00',
        vat_rate: '0.00',
        vat_amount: '0.00',
        wallet_applied: '0.00',
        amount_due: opts.body.discount_code ? '180.00' : '200.00',
        gift_value: '200.00',
      }),
      'POST /api/gifts': (opts) => envelope({ id: 9, ...opts.body }),
      'POST /api/gifts/{id}/pay': envelope({ id: 9, payment_status: 'paid', amount_due: '0.00' }),
      'POST /api/gifts/{token}/redeem': envelope({ amount: '200.00', wallet_balance: '200.00' }),
    }),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)

const { useGifts, rememberPendingGift, takePendingGift } = await import('~/composables/useGifts')

describe('useGifts', () => {
  it('reads the package and exposes its amount and active flag', async () => {
    const { packageAmount, packageActive } = useGifts()
    await flushPromises()
    expect(packageAmount.value).toBe('200.00')
    expect(packageActive.value).toBe(true)
  })

  it('quotes, creates, pays and redeems against the documented paths', async () => {
    const { quote, create, pay, redeem } = useGifts()

    const quoted = await quote({ use_wallet: false, discount_code: 'WELCOME10' })
    expect(quoted.data.gift_value).toBe('200.00')
    expect(quoted.data.amount_due).toBe('180.00')

    const created = await create({ recipient_name: 'Sara' })
    expect(created.data.id).toBe(9)

    await pay(9)
    await redeem('18d08cb9-0843-4865-9c40-11a470b183db')

    const paths = api.calls.map((c) => `${c.method} ${c.url}`)
    expect(paths).toContain('POST /api/gifts/quote')
    expect(paths).toContain('POST /api/gifts')
    expect(paths).toContain('POST /api/gifts/9/pay')
    expect(paths).toContain('POST /api/gifts/18d08cb9-0843-4865-9c40-11a470b183db/redeem')
  })

  it('unwraps the buyer list paginator', async () => {
    const { list } = useGifts()
    const { items, lastPage, total } = list({ page: 1, per_page: 10 })
    await flushPromises()
    expect(items.value).toHaveLength(1)
    expect(lastPage.value).toBe(2)
    expect(total.value).toBe(12)
  })

  it('a parked gift is handed back once, and only for its own token', () => {
    rememberPendingGift('abc')
    expect(takePendingGift('xyz')).toBe(false)
    expect(takePendingGift('abc')).toBe(true)
    expect(takePendingGift('abc')).toBe(false)
  })
})

describe('useGifts — gifting switched off', () => {
  it('a 422 gift_unavailable on the quote comes back keyed to `gift`', async () => {
    const { apiError } = await import('../helpers/mockApi')
    api.table['POST /api/gifts/quote'] = apiError(422, { gift: ['Gift purchases are unavailable right now.'] }, 'Gift purchases are unavailable right now.')

    const { quote } = useGifts()
    const err = await quote({ use_wallet: false }).catch((e) => e)
    const { normalizeApiError, fieldError } = await import('~/composables/useSubmit')
    expect(fieldError(normalizeApiError(err), 'gift')).toBe('Gift purchases are unavailable right now.')
  })
})
