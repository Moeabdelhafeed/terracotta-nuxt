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

  it('hides the strip once a code is applied, keeping the manual box for private codes', async () => {
    const wrapper = await mountSuspended(DiscountCodeInput, { props: { modelValue: 'HALFCAP' } })
    await vi.waitFor(() => expect(wrapper.text()).toContain('HALFCAP'))
    expect(wrapper.find('[data-test="advertised-codes"]').exists()).toBe(false)
  })
})
