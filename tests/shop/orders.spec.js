// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

const order = (over = {}) => ({
  id: 9,
  status: 'preparing',
  subtotal: '200.00', discount_amount: '20.00', discount_code: 'WELCOME10',
  total_price: '195.00', vat_rate: '15.00', vat_amount: '25.43',
  wallet_applied: '50.00', refunded_amount: null, amount_due: '145.00',
  payment_expires_at: null, payment_status: 'unpaid',
  delivery_fee: '15.00', delivery_zone: 'Riyadh',
  can_cancel: true, created_at: '2026-07-04T12:00:00+00:00', cancelled_at: null,
  items: [{ id: 1, product: { id: 11, title: 'Cup', image: null }, quantity: 2, unit_price: '100.00', line_total: '200.00' }],
  ...over,
})

const { api, lang } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/shop/orders': () => envelope({ data: globalThis.__orders, current_page: 1, last_page: 2, total: 12 }),
      'GET /api/shop/orders/{id}': () => envelope(globalThis.__order),
      'DELETE /api/shop/orders/{id}': () => globalThis.__cancel(),
    }),
    lang: createLang('en'),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: ref('SAR') }))
mockNuxtImport('useDateFormat', () => () => ({ formatDate: (v) => `on ${String(v).slice(0, 10)}`, formatTime: (v) => v }))

const { useOrders, useOrder, ORDER_STEPS } = await import('~/composables/useOrders')
const ShopOrderItems = (await import('~/components/shop/ShopOrderItems.vue')).default
const ShopOrderTimeline = (await import('~/components/shop/ShopOrderTimeline.vue')).default
const ShopOrderCancelButton = (await import('~/components/shop/ShopOrderCancelButton.vue')).default

beforeEach(() => {
  globalThis.__order = order()
  globalThis.__orders = [order()]
  globalThis.__cancel = () => ({ success: true, message: 'Order cancelled.', errors: null, data: order({ status: 'cancelled', can_cancel: false, payment_status: 'refunded', refunded_amount: '50.00', amount_due: '0.00' }) })
  api.$fetch.mockClear()
})

describe('useOrders', () => {
  it('unwraps the paginator', async () => {
    const { items, lastPage, total } = useOrders({ page: ref(1), perPage: 10 })
    await flushPromises()
    expect(items.value).toHaveLength(1)
    expect(lastPage.value).toBe(2)
    expect(total.value).toBe(12)
  })
})

describe('useOrder', () => {
  it('cancel DELETEs and replaces the order with the server answer', async () => {
    const one = useOrder(() => 9)
    await flushPromises()

    await one.cancel()
    expect(api.calls.at(-1)).toMatchObject({ method: 'DELETE', url: '/api/shop/orders/9' })
    expect(one.order.value.status).toBe('cancelled')
    expect(one.order.value.refunded_amount).toBe('50.00')
  })

  it('pay is a bare POST — the endpoint takes no body', async () => {
    api.table['POST /api/shop/orders/{id}/pay'] = { success: true, message: 'Payment completed successfully.', errors: null, data: order({ status: 'pending', payment_status: 'paid', amount_due: '0.00' }) }
    const one = useOrder(() => 9)
    await flushPromises()

    await one.pay()
    const call = api.calls.at(-1)
    expect(call).toMatchObject({ method: 'POST', url: '/api/shop/orders/9/pay' })
    expect(call.body).toBeUndefined()
    expect(one.order.value.payment_status).toBe('paid')
  })
})

describe('ShopOrderItems', () => {
  it('renders a line whose product was deleted without blowing up', async () => {
    const wrapper = await mountSuspended(ShopOrderItems, {
      props: { items: [{ id: 1, product: null, quantity: 2, unit_price: '100.00', line_total: '200.00' }] },
    })
    expect(wrapper.text()).toContain('Product no longer available')
    expect(wrapper.text()).toContain('200.00 SAR')
    expect(wrapper.find('a').exists()).toBe(false)
  })

  it('links to the product when it still exists', async () => {
    const wrapper = await mountSuspended(ShopOrderItems, { props: { items: order().items } })
    expect(wrapper.find('a').attributes('href')).toBe('/shop/11')
  })
})

describe('ShopOrderTimeline', () => {
  it('walks pending → preparing → out_for_delivery → completed', async () => {
    const wrapper = await mountSuspended(ShopOrderTimeline, { props: { order: order({ status: 'preparing' }) } })
    const labels = wrapper.findAll('li').map((li) => li.text())
    expect(labels).toHaveLength(ORDER_STEPS.length)
    expect(labels[0]).toContain('Order confirmed')
    expect(labels[3]).toContain('Delivered')
  })

  it('shows the pay step ahead of the rest while the order is held', async () => {
    const wrapper = await mountSuspended(ShopOrderTimeline, { props: { order: order({ status: 'awaiting_payment' }) } })
    const items = wrapper.findAll('li')
    expect(items).toHaveLength(ORDER_STEPS.length + 1)
    expect(items[0].text()).toContain('Payment')
  })

  it('a cancelled order stops the timeline and names the refund', async () => {
    const wrapper = await mountSuspended(ShopOrderTimeline, {
      props: { order: order({ status: 'cancelled', payment_status: 'refunded', refunded_amount: '50.00', cancelled_at: '2026-07-05T09:00:00+00:00' }) },
    })
    const items = wrapper.findAll('li')
    expect(items.at(-1).text()).toContain('Cancelled')
    expect(items.at(-1).text()).toContain('50.00 SAR')
    expect(wrapper.text()).not.toContain('Out for delivery')
  })
})

describe('ShopOrderCancelButton', () => {
  it('renders nothing when the server says the order cannot be cancelled', async () => {
    const wrapper = await mountSuspended(ShopOrderCancelButton, {
      props: { order: order({ can_cancel: false }), cancel: vi.fn() },
    })
    expect(wrapper.find('button').exists()).toBe(false)
  })

  it('confirms first, warns that only the wallet part comes back, and cancels once', async () => {
    let resolveCancel
    const cancel = vi.fn(() => new Promise((resolve) => { resolveCancel = resolve }))
    const wrapper = await mountSuspended(ShopOrderCancelButton, { props: { order: order(), cancel } })

    await wrapper.find('button').trigger('click')
    await flushPromises()

    const dialog = document.querySelector('[role="dialog"]')
    expect(dialog.textContent).toContain('50.00 SAR')

    const confirm = [...dialog.querySelectorAll('button')].at(-1)
    confirm.click()
    confirm.click()
    await flushPromises()
    expect(cancel).toHaveBeenCalledTimes(1)

    resolveCancel({ success: true, message: 'ok', data: order({ status: 'cancelled' }) })
    await flushPromises()
    expect(wrapper.emitted('cancelled')).toHaveLength(1)
  })
})
