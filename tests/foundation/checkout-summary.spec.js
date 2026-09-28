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

  /**
   * The order from the bug report: a 10,000 SAR delivery, 424.50 off the wallet. A placed
   * purchase reports `amount_due: "0.00"` because nothing is still owed, and the box used to
   * read that as "0 SAR — covered in full".
   */
  it('shows what a placed order cost beyond the wallet, not "covered in full"', async () => {
    const placed = {
      subtotal: '80.00', discount_amount: '8.00', discount_code: 'WELCOME10', delivery_fee: '10000.00', delivery_zone: 'Riyadh',
      total_price: '10072.00', vat_rate: '15.00', vat_amount: '1313.74', wallet_applied: '424.50', amount_due: '0.00',
      payment_status: 'paid',
    }
    const wrapper = await mountSuspended(CheckoutSummary, { props: { quote: placed } })

    expect(wrapper.find('[data-test="summary-paid"]').text()).toBe('Paid9647.50 SAR')
    expect(wrapper.text()).not.toContain('Amount due')
    expect(wrapper.text()).not.toContain('covered in full')
  })

  it('says covered in full only when the wallet really paid all of it', async () => {
    const wrapper = await mountSuspended(CheckoutSummary, {
      props: { quote: { ...shopQuote, wallet_applied: '195.00', amount_due: '0.00', payment_status: 'paid' } },
    })

    expect(wrapper.find('[data-test="summary-paid"]').text()).toBe('Paid0.00 SAR')
    expect(wrapper.text()).toContain('covered in full')
  })

  it('shows what came back on a cancelled purchase', async () => {
    const wrapper = await mountSuspended(CheckoutSummary, {
      props: { quote: { ...shopQuote, amount_due: '0.00', payment_status: 'refunded', refunded_amount: '195.00' } },
    })

    expect(wrapper.find('[data-test="summary-refunded"]').text()).toBe('Refunded to your wallet195.00 SAR')
    expect(wrapper.text()).not.toContain('covered in full')
  })
})
