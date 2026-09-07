// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

/** The server builds this from GIFT_SHARE_BASE_URL — nothing may rebuild it from the token. */
const SHARE_URL = 'https://gifts.terracotta-ksa.com/g/18d08cb9-0843-4865-9c40-11a470b183db'

const paid = {
  id: 3, recipient_name: 'Sara', message: 'Happy birthday!', recipient_phone: '+962790000111',
  amount: '200.00', subtotal: '200.00', discount_amount: '0.00', discount_code: null,
  total_price: '200.00', wallet_applied: '0.00', amount_due: '0.00',
  payment_status: 'paid', status: 'paid', token: '18d08cb9-0843-4865-9c40-11a470b183db',
  share_url: SHARE_URL, payment_expires_at: null, is_redeemed: false, redeemed_at: null,
  created_at: '2026-09-07T17:48:20+00:00',
}

const { api, lang, rows } = await vi.hoisted(async () => {
  const { createApiMock, createLang } = await import('../helpers/mockApi')
  const rows = { value: [] }
  return {
    api: createApiMock({ 'GET /api/gifts': () => ({ success: true, message: 'ok', errors: null, data: rows.value }) }),
    lang: createLang('en'),
    rows,
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useDateFormat', () => () => ({ formatDate: (v) => `on ${v}`, formatDateOnly: (v) => `on ${v}` }))
mockNuxtImport('useRoute', () => () => ({ params: { id: '3' }, query: { new: '1' } }))

const GiftDetail = (await import('~/pages/gifts/[id].vue')).default

const mount = async (gift) => {
  rows.value = [gift]
  const wrapper = await mountSuspended(GiftDetail, { global: { stubs: { PageBar: true, AppConfetti: true } } })
  await flushPromises()
  return wrapper
}

describe('/gifts/[id]', () => {
  beforeEach(() => { api.calls.length = 0 })

  it('shows the success copy and the share link exactly as the server built it', async () => {
    const wrapper = await mount(paid)

    expect(wrapper.text()).toContain('Gift purchased!')
    expect(wrapper.text()).toContain(SHARE_URL)
    // Never rebuilt from the token, which would silently point at the wrong host.
    expect(wrapper.html()).not.toContain(`/gift/${paid.token}"`)

    const whatsapp = wrapper.find('a[href^="https://wa.me/"]')
    expect(whatsapp.attributes('href')).toContain('https://wa.me/962790000111?text=')
    expect(decodeURIComponent(whatsapp.attributes('href'))).toContain(SHARE_URL)
  })

  it('falls back to the WhatsApp chooser when there is no recipient phone', async () => {
    const wrapper = await mount({ ...paid, recipient_phone: null })
    expect(wrapper.find('a[href^="https://wa.me/"]').attributes('href')).toMatch(/^https:\/\/wa\.me\/\?text=/)
  })

  it('shows the pay step instead of the link while the hold is running', async () => {
    const wrapper = await mount({
      ...paid, status: 'awaiting_payment', payment_status: 'unpaid', amount_due: '200.00',
      payment_expires_at: new Date(Date.now() + 10 * 60000).toISOString(),
    })
    expect(wrapper.findComponent({ name: 'CheckoutPaymentHold' }).exists()).toBe(true)
    expect(wrapper.findComponent({ name: 'GiftShare' }).exists()).toBe(false)
  })

  it('a cancelled gift is gone — no link, no pay step', async () => {
    const wrapper = await mount({ ...paid, status: 'cancelled', payment_status: 'unpaid' })
    expect(wrapper.text()).toContain('This gift was cancelled')
    expect(wrapper.findComponent({ name: 'GiftShare' }).exists()).toBe(false)
    expect(wrapper.findComponent({ name: 'CheckoutPaymentHold' }).exists()).toBe(false)
  })

  it('a redeemed gift says so, with when', async () => {
    const wrapper = await mount({ ...paid, is_redeemed: true, redeemed_at: '2026-09-08T10:00:00+00:00' })
    expect(wrapper.text()).toContain('Redeemed')
    expect(wrapper.text()).toContain('on 2026-09-08T10:00:00+00:00')
    expect(wrapper.findComponent({ name: 'GiftShare' }).exists()).toBe(false)
  })

  it('a gift that is not the buyer\'s says so rather than rendering an empty shell', async () => {
    const wrapper = await mount({ ...paid, id: 99 })
    expect(wrapper.text()).toContain('Gift not found')
  })
})
