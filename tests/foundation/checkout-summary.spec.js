// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const lang = await vi.hoisted(async () => (await import('../helpers/mockApi')).createLang('en'))
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))

const CheckoutSummary = (await import('~/components/checkout/CheckoutSummary.vue')).default

const shopQuote = {
  subtotal: '200.00', discount_amount: '20.00', discount_code: 'TEN', delivery_fee: '15.00', delivery_zone: 'Riyadh',
  total_price: '195.00', vat_rate: '15.00', vat_amount: '25.43', wallet_applied: '50.00', amount_due: '145.00',
}

describe('CheckoutSummary', () => {
  it('renders the seven quoted fields exactly as they arrived', async () => {
    const wrapper = await mountSuspended(CheckoutSummary, { props: { quote: shopQuote } })
    const text = wrapper.text()
    expect(text).toContain('200.00 SAR')
    expect(text).toContain('−20.00 SAR')
    expect(text).toContain('TEN')
    expect(text).toContain('15.00 SAR')
    expect(text).toContain('195.00 SAR')
    expect(text).toContain('−50.00 SAR')
    expect(text).toContain('145.00 SAR')
    expect(text).toContain('Includes VAT 25.43 SAR (15%)')
  })

  it('shows the delivery fee the server quoted, never one netted against the discount', async () => {
    const wrapper = await mountSuspended(CheckoutSummary, {
      props: { quote: { ...shopQuote, discount_amount: '100.00', total_price: '115.00', wallet_applied: '0.00', amount_due: '115.00' } },
    })
    const rows = wrapper.findAll('div').map((row) => row.text())
    expect(rows.some((row) => row.startsWith('Discount TEN−100.00 SAR'))).toBe(true)
    // A 100 discount against a 15 fee: the delivery line is still the quoted 15, not 0 or free.
    expect(rows.some((row) => row.startsWith('Delivery (Riyadh)15.00 SAR'))).toBe(true)
    expect(wrapper.text()).not.toContain('Free')
  })

  it('hides delivery for a workshop quote and VAT when the rate is zero', async () => {
    const wrapper = await mountSuspended(CheckoutSummary, {
      props: { quote: { subtotal: '95.00', discount_amount: '0.00', discount_code: null, delivery_fee: null, total_price: '95.00', vat_rate: '0.00', vat_amount: '0.00', wallet_applied: '0.00', amount_due: '95.00' } },
    })
    expect(wrapper.text()).not.toContain('Delivery')
    expect(wrapper.text()).not.toContain('VAT')
    expect(wrapper.text()).not.toContain('Discount')
  })

  it('shows free delivery and the settled note when amount_due is 0.00', async () => {
    const wrapper = await mountSuspended(CheckoutSummary, {
      props: { quote: { ...shopQuote, delivery_fee: '0.00', wallet_applied: '195.00', amount_due: '0.00' } },
    })
    expect(wrapper.text()).toContain('Free')
    expect(wrapper.text()).toContain('Nothing left to pay')
  })
})
