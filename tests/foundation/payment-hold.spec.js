// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const lang = await vi.hoisted(async () => (await import('../helpers/mockApi')).createLang('en'))
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))

const PaymentHold = (await import('~/components/checkout/PaymentHold.vue')).default

const inMinutes = (m) => new Date(Date.now() + m * 60000).toISOString()

describe('PaymentHold', () => {
  beforeEach(() => { vi.useFakeTimers({ shouldAdvanceTime: true }) })
  afterEach(() => { vi.useRealTimers() })

  it('amount_due 0.00 renders the settled state — no pay button, no countdown', async () => {
    const pay = vi.fn()
    const wrapper = await mountSuspended(PaymentHold, {
      props: { amountDue: '0.00', paymentStatus: 'paid', expiresAt: null, pay },
    })
    expect(wrapper.text()).toContain('All paid')
    expect(wrapper.find('button').exists()).toBe(false)
    expect(pay).not.toHaveBeenCalled()
  })

  it('a held purchase shows the countdown and pays once even on a double click', async () => {
    let resolvePay
    const pay = vi.fn(() => new Promise((resolve) => { resolvePay = resolve }))
    const wrapper = await mountSuspended(PaymentHold, {
      props: { amountDue: '145.00', paymentStatus: 'unpaid', expiresAt: inMinutes(14), pay },
    })
    expect(wrapper.text()).toContain('Reserved for you')
    expect(wrapper.text()).toMatch(/13:5\d|14:00/)

    const button = wrapper.find('button')
    await button.trigger('click')
    await button.trigger('click')
    expect(pay).toHaveBeenCalledTimes(1)

    resolvePay({ data: { payment_status: 'paid' } })
    await flushPromises()
    expect(wrapper.emitted('paid')).toHaveLength(1)
  })

  it('a lapsed hold shows the expired state and a way back', async () => {
    const wrapper = await mountSuspended(PaymentHold, {
      props: { amountDue: '145.00', paymentStatus: 'unpaid', expiresAt: inMinutes(-1), pay: vi.fn(), restartTo: '/cart' },
    })
    expect(wrapper.text()).toContain('Payment window closed')
    expect(wrapper.find('a').attributes('href')).toBe('/cart')
  })

  it('the server refusing the hold flips to expired with its message', async () => {
    const err = new Error('closed')
    err.status = 422
    err.data = { message: 'This payment window has closed. Please start again.', errors: { order: ['This payment window has closed. Please start again.'] } }
    const pay = vi.fn(() => Promise.reject(err))
    const wrapper = await mountSuspended(PaymentHold, {
      props: { amountDue: '145.00', paymentStatus: 'unpaid', expiresAt: inMinutes(10), pay },
    })
    await wrapper.find('button').trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('This payment window has closed')
    expect(wrapper.emitted('expired')).toHaveLength(1)
  })

  it('emits expired when the clock runs out', async () => {
    const wrapper = await mountSuspended(PaymentHold, {
      props: { amountDue: '145.00', paymentStatus: 'unpaid', expiresAt: new Date(Date.now() + 1500).toISOString(), pay: vi.fn() },
    })
    expect(wrapper.text()).toContain('Reserved for you')
    await vi.advanceTimersByTimeAsync(3000)
    expect(wrapper.emitted('expired')).toHaveLength(1)
    expect(wrapper.text()).toContain('Payment window closed')
  })
})
