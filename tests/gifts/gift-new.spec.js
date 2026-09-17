// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang, sanctum, navigate } = await vi.hoisted(async () => {
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/gifts/package': envelope({ amount: '200.00', is_active: true }),
      'POST /api/gifts/quote': (opts) => envelope({
        subtotal: '200.00',
        discount_amount: opts.body.discount_code ? '20.00' : '0.00',
        discount_code: opts.body.discount_code ?? null,
        delivery_fee: '0.00',
        total_price: opts.body.discount_code ? '180.00' : '200.00',
        vat_rate: '0.00',
        vat_amount: '0.00',
        wallet_applied: opts.body.use_wallet ? '100.00' : '0.00',
        amount_due: '200.00',
        gift_value: '200.00',
      }),
      'POST /api/gifts': (opts) => envelope({
        id: 9,
        recipient_name: opts.body.recipient_name,
        recipient_phone: opts.body.recipient_phone,
        amount: '200.00',
        subtotal: '200.00',
        discount_amount: '0.00',
        discount_code: null,
        total_price: '200.00',
        wallet_applied: '200.00',
        amount_due: '0.00',
        payment_status: 'paid',
        status: 'paid',
        token: 'tok',
        share_url: 'https://terracotta-ksa.com/gift/tok',
        payment_expires_at: null,
      }),
      'POST /api/gifts/{id}/pay': envelope({ id: 10, payment_status: 'paid', amount_due: '0.00' }),
      'GET /api/wallet/transactions': envelope({ balance: '300.00', transactions: [] }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState({ id: 1, name: 'Buyer', is_guest: false, wallet_balance: '500.00' }),
    navigate: v.fn(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useAuthConfig', () => () => ({ allowedPhoneCountries: ref('all'), appUsers: ref(true) }))
mockNuxtImport('navigateTo', () => navigate)

const GiftNew = (await import('~/pages/gifts/new.vue')).default

const mount = () => mountSuspended(GiftNew, { global: { stubs: { PageBar: true } } })

const quoteCalls = () => api.calls.filter((c) => c.url === '/api/gifts/quote')

describe('/gifts/new', () => {
  beforeEach(() => {
    api.calls.length = 0
    navigate.mockClear()
    sanctum.refreshIdentity.mockClear()
    api.table['GET /api/gifts/package'] = { success: true, message: 'ok', errors: null, data: { amount: '200.00', is_active: true } }
  })

  it('quotes on arrival and shows the package amount and gift value', async () => {
    const wrapper = await mount()
    await flushPromises()

    expect(quoteCalls()).toHaveLength(1)
    expect(wrapper.text()).toContain('Gift 200.00 SAR of credit')
    expect(wrapper.text()).toContain('They receive 200.00 SAR in wallet credit.')
    // Gift VAT is always 0.00, so the summary must not print a VAT line at all.
    expect(wrapper.text()).not.toContain('Includes VAT')
  })

  it('re-quotes whenever the wallet toggle or the discount code changes', async () => {
    const wrapper = await mount()
    await flushPromises()
    expect(quoteCalls()).toHaveLength(1)

    await wrapper.findComponent({ name: 'CheckoutWalletToggle' }).vm.$emit('update:modelValue', true)
    await flushPromises()
    expect(quoteCalls()).toHaveLength(2)
    expect(quoteCalls()[1].body.use_wallet).toBe(true)

    await wrapper.findComponent({ name: 'CheckoutDiscountCodeInput' }).vm.$emit('update:modelValue', 'WELCOME10')
    await flushPromises()
    expect(quoteCalls()).toHaveLength(3)
    expect(quoteCalls()[2].body.discount_code).toBe('WELCOME10')
  })

  it('a gift settled at create skips the pay step entirely', async () => {
    const wrapper = await mount()
    await flushPromises()

    wrapper.find('#recipient_name').setValue('Sara')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(api.calls.some((c) => c.method === 'POST' && c.url === '/api/gifts')).toBe(true)
    expect(api.calls.some((c) => c.url.endsWith('/pay'))).toBe(false)
    expect(wrapper.findComponent({ name: 'CheckoutPaymentHold' }).exists()).toBe(false)
    expect(navigate).toHaveBeenCalledWith({ path: '/gifts/9', query: { new: '1' } })
  })

  it('holds the gift and shows the pay step when there is money left to pay', async () => {
    const { envelope } = await import('../helpers/mockApi')
    api.table['POST /api/gifts'] = envelope({
      id: 10, recipient_name: 'Sara', amount: '200.00', subtotal: '200.00', discount_amount: '0.00',
      total_price: '200.00', wallet_applied: '0.00', amount_due: '200.00', payment_status: 'unpaid',
      status: 'awaiting_payment', token: 'tok', share_url: 'https://terracotta-ksa.com/gift/tok',
      payment_expires_at: new Date(Date.now() + 14 * 60000).toISOString(),
    })

    const wrapper = await mount()
    await flushPromises()
    wrapper.find('#recipient_name').setValue('Sara')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.findComponent({ name: 'CheckoutPaymentHold' }).exists()).toBe(true)
    expect(navigate).not.toHaveBeenCalled()
  })

  /**
   * The buyer paid, went to their profile, and read the balance they had before. Both
   * surfaces the site reads one from have to be refetched the moment the gift settles.
   */
  it('refetches the identity and the wallet ledger once the gift is paid', async () => {
    const { envelope } = await import('../helpers/mockApi')
    api.table['POST /api/gifts'] = envelope({
      id: 10, recipient_name: 'Sara', amount: '200.00', subtotal: '200.00', discount_amount: '0.00',
      total_price: '200.00', wallet_applied: '0.00', amount_due: '200.00', payment_status: 'unpaid',
      status: 'awaiting_payment', token: 'tok', share_url: 'https://terracotta-ksa.com/gift/tok',
      payment_expires_at: new Date(Date.now() + 14 * 60000).toISOString(),
    })

    const wrapper = await mount()
    await flushPromises()
    wrapper.find('#recipient_name').setValue('Sara')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    const walletReadsBefore = api.calls.filter((c) => c.url === '/api/wallet/transactions').length
    await wrapper.findAll('button').find((b) => b.text().includes('Pay now')).trigger('click')
    await flushPromises()

    expect(api.calls.some((c) => c.url === '/api/gifts/10/pay')).toBe(true)
    expect(sanctum.refreshIdentity).toHaveBeenCalled()
    expect(api.calls.filter((c) => c.url === '/api/wallet/transactions').length).toBeGreaterThan(walletReadsBefore)
    expect(navigate).toHaveBeenCalledWith({ path: '/gifts/10', query: { new: '1' } })
  })

  it('refetches them for a gift the wallet covered in full, which has no pay step', async () => {
    const { envelope } = await import('../helpers/mockApi')
    api.table['POST /api/gifts'] = envelope({
      id: 9, recipient_name: 'Sara', amount: '200.00', subtotal: '200.00', discount_amount: '0.00',
      total_price: '200.00', wallet_applied: '200.00', amount_due: '0.00', payment_status: 'paid',
      status: 'paid', token: 'tok', share_url: 'https://terracotta-ksa.com/gift/tok', payment_expires_at: null,
    })

    const wrapper = await mount()
    await flushPromises()
    const walletReadsBefore = api.calls.filter((c) => c.url === '/api/wallet/transactions').length

    wrapper.find('#recipient_name').setValue('Sara')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(sanctum.refreshIdentity).toHaveBeenCalled()
    expect(api.calls.filter((c) => c.url === '/api/wallet/transactions').length).toBeGreaterThan(walletReadsBefore)
  })

  it('offers a retry when the quote cannot be had, instead of an endless skeleton', async () => {
    const { apiError, envelope } = await import('../helpers/mockApi')
    api.table['POST /api/gifts/quote'] = apiError(500, {}, 'Server error')

    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.find('[data-test="quote-failed"]').exists()).toBe(true)

    api.table['POST /api/gifts/quote'] = envelope({
      subtotal: '200.00', discount_amount: '0.00', discount_code: null, delivery_fee: '0.00',
      total_price: '200.00', vat_rate: '0.00', vat_amount: '0.00', wallet_applied: '0.00',
      amount_due: '200.00', gift_value: '200.00',
    })
    await wrapper.findAll('button').find((b) => b.text().includes('Try again')).trigger('click')
    await flushPromises()

    expect(wrapper.find('[data-test="quote-failed"]').exists()).toBe(false)
    expect(wrapper.text()).toContain('200.00 SAR')
  })

  it('renders the server 422 for recipient_name and message next to their fields', async () => {
    const { apiError } = await import('../helpers/mockApi')
    api.table['POST /api/gifts'] = apiError(422, {
      recipient_name: ['HTML tags are not allowed here.'],
      message: ['HTML tags are not allowed here.'],
    }, 'HTML tags are not allowed here. (and 1 more error)')

    const wrapper = await mount()
    await flushPromises()
    wrapper.find('#recipient_name').setValue('<b>x</b>')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    const name = wrapper.find('#recipient_name').element.parentElement
    const message = wrapper.find('#gift_message').element.parentElement
    expect(name.textContent).toContain('HTML tags are not allowed here.')
    expect(message.textContent).toContain('HTML tags are not allowed here.')
  })

  it('shows the gifting-off state when the package is inactive', async () => {
    api.table['GET /api/gifts/package'] = { success: true, message: 'ok', errors: null, data: { amount: '200.00', is_active: false } }
    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('Gift credit is unavailable')
    expect(wrapper.find('form').exists()).toBe(false)
  })

  it('a 422 gift_unavailable on the quote flips the page to the off state', async () => {
    const { apiError } = await import('../helpers/mockApi')
    api.table['POST /api/gifts/quote'] = apiError(422, { gift: ['Gift purchases are unavailable right now.'] }, 'Gift purchases are unavailable right now.')

    const wrapper = await mount()
    await flushPromises()

    expect(wrapper.text()).toContain('Gift purchases are unavailable right now.')
    expect(wrapper.find('form').exists()).toBe(false)
  })
})
