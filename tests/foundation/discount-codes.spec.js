// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const { api, lang, sanctum } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/discount-codes': envelope([
        { code: 'WELCOME10', type: 'percent', value: '10.00', max_discount: '50.00', min_order_total: null },
        { code: 'BIGORDER', type: 'fixed', value: '40.00', min_order_total: '500.00' },
      ]),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${Number(v)} SAR`, currency: 'SAR' }))

const { envelope: wrap } = await import('../helpers/mockApi')
const DiscountCodeInput = (await import('~/components/checkout/CheckoutDiscountCodeInput.vue')).default

describe('advertised discount codes', () => {
  it('offers the codes this customer can still use, with what each one asks for', async () => {
    const wrapper = await mountSuspended(DiscountCodeInput)
    await vi.waitFor(() => expect(wrapper.find('[data-test="advertised-codes"]').exists()).toBe(true))

    const text = wrapper.find('[data-test="advertised-codes"]').text()
    expect(text).toContain('WELCOME10')
    expect(text).toContain('10% off')
    // Listed even though the basket may not reach it yet — so say what it needs.
    expect(text).toContain('BIGORDER')
    expect(text).toContain('on orders over 500 SAR')
  })

  it('applies a code when its chip is tapped', async () => {
    const wrapper = await mountSuspended(DiscountCodeInput)
    await vi.waitFor(() => expect(wrapper.findAll('[data-test="advertised-codes"] button').length).toBe(2))

    await wrapper.findAll('[data-test="advertised-codes"] button')[0].trigger('click')
    expect(wrapper.emitted('update:modelValue').at(-1)).toEqual(['WELCOME10'])
  })

  it('hides the strip once a code is applied, keeping the box to remove it with', async () => {
    const wrapper = await mountSuspended(DiscountCodeInput, { props: { modelValue: 'HALFCAP' } })
    await vi.waitFor(() => expect(wrapper.text()).toContain('HALFCAP'))
    expect(wrapper.find('[data-test="advertised-codes"]').exists()).toBe(false)
  })

  // Asking for a code while the studio is advertising none is a question the customer
  // cannot answer, and it sits in the middle of paying. Every screen that takes a coupon
  // gets this from the component, so they all behave the same.
  it('draws nothing at all when there are no codes to be had', async () => {
    const previous = api.table['GET /api/discount-codes']
    api.table['GET /api/discount-codes'] = wrap([])

    try {
      const wrapper = await mountSuspended(DiscountCodeInput)
      await vi.waitFor(() => expect(api.calls.some((c) => c.url === '/api/discount-codes')).toBe(true))

      expect(wrapper.text()).toBe('')
      expect(wrapper.find('input').exists()).toBe(false)
    } finally {
      api.table['GET /api/discount-codes'] = previous
    }
  })

  // A code already in play keeps the box, whether the studio advertises any or not: a
  // refusal has to be editable and an accepted one removable.
  it('keeps the box for a code already applied even with nothing advertised', async () => {
    const previous = api.table['GET /api/discount-codes']
    api.table['GET /api/discount-codes'] = wrap([])

    try {
      const wrapper = await mountSuspended(DiscountCodeInput, { props: { modelValue: 'PRIVATE20' } })
      await vi.waitFor(() => expect(wrapper.text()).toContain('PRIVATE20'))
    } finally {
      api.table['GET /api/discount-codes'] = previous
    }
  })
})
