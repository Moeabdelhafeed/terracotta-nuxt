// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/gifts/history': () => globalThis.__history(),
    }),
    lang: createLang('en'),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useDateFormat', () => () => ({ formatDate: (v) => `on ${v}`, formatDateOnly: (v) => `on ${v}`, formatTime: (v) => v }))

const GiftsIndex = (await import('~/pages/gifts/index.vue')).default

const sent = (over = {}) => ({
  id: 3, direction: 'sent', recipient_name: 'Sara', amount: '200.00', status: 'paid',
  is_redeemed: false, created_at: '2026-09-01T10:00:00+00:00', ...over,
})

const received = (over = {}) => ({
  id: 7, direction: 'received', amount: '150.00', from: 'Noura', message: 'Enjoy!',
  redeemed_at: '2026-09-10T10:00:00+00:00', created_at: '2026-09-09T10:00:00+00:00', ...over,
})

const history = (over = {}) => ({
  success: true,
  message: 'ok',
  errors: null,
  data: {
    totals: { sent_count: 1, sent_total_paid: '200.00', received_count: 1, received_total: '150.00' },
    gifts: [sent(), received()],
    ...over,
  },
})

const mount = () => mountSuspended(GiftsIndex, { global: { stubs: { PageBar: true } } })
const chip = (wrapper, direction) => wrapper.find(`[data-direction="${direction}"]`)

beforeEach(() => {
  api.calls.length = 0
  api.table['GET /api/gifts/history'] = () => globalThis.__history()
  globalThis.__history = () => history()
})

describe('gifts — the received side', () => {
  it('reads /api/gifts/history without per_page, so the whole list arrives to filter', async () => {
    await mount()
    await flushPromises()
    const call = api.calls.find((c) => c.url === '/api/gifts/history')
    expect(call).toBeTruthy()
    expect(call.query?.per_page).toBeUndefined()
  })

  it('renders a claimed gift with who it came from and what landed', async () => {
    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.text()).toContain('From Noura')
    expect(wrapper.text()).toContain('150.00 SAR')
    expect(wrapper.text()).toContain('Enjoy!')
  })

  it('names nobody rather than "From " when the server does not say who sent it', async () => {
    globalThis.__history = () => history({ gifts: [received({ from: null })] })
    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.text()).toContain('A gift you claimed')
    expect(wrapper.text()).not.toContain('From ')
  })

  it('a claimed gift is not a link — the token and the share link are the buyer\'s', async () => {
    globalThis.__history = () => history({ gifts: [received()] })
    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.findAll('a').some((a) => a.attributes('href')?.startsWith('/gifts/7'))).toBe(false)
  })

  it('labels both sides from the whole-history totals before either is opened', async () => {
    const wrapper = await mount()
    await flushPromises()
    expect(chip(wrapper, 'sent').text()).toContain('1')
    expect(chip(wrapper, 'received').text()).toContain('1')
    expect(chip(wrapper, 'all').text()).toContain('2')
  })

  it('narrows to one side without asking the server again', async () => {
    const wrapper = await mount()
    await flushPromises()

    await chip(wrapper, 'received').trigger('click')
    expect(wrapper.text()).toContain('From Noura')
    expect(wrapper.text()).not.toContain('Sara')
    expect(api.calls.filter((c) => c.url === '/api/gifts/history')).toHaveLength(1)
  })

  it('an empty side is said about the filter, not about the history', async () => {
    globalThis.__history = () => history({
      totals: { sent_count: 0, received_count: 1 },
      gifts: [received()],
    })
    const wrapper = await mount()
    await flushPromises()

    await chip(wrapper, 'sent').trigger('click')
    expect(wrapper.find('[data-test="gifts-filter-empty"]').text()).toContain('not sent any gifts')
  })

  it('a failed read is an error with a retry, never "no gifts yet"', async () => {
    const { apiError } = await import('../helpers/mockApi')
    api.table['GET /api/gifts/history'] = apiError(500, {}, 'Server error')

    const wrapper = await mount()
    await flushPromises()
    expect(wrapper.find('[data-test="load-error"]').exists()).toBe(true)
    expect(wrapper.text()).not.toContain('No gifts yet')
  })
})
