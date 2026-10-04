// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

/** The coffee house menu page, and its invitation on the home page. */
const { api, lang } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/media': envelope({ group: 'web', media: {} }),
      'GET /api/coffee-house': () => envelope(globalThis.__menu),
      'GET /api/coffee-house/featured': () => envelope(globalThis.__featured),
    }),
    lang: createLang('en'),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))

const MenuPage = (await import('~/pages/coffee-house.vue')).default
const HomeCoffeeHouse = (await import('~/components/home/HomeCoffeeHouse.vue')).default

const latte = {
  id: 4, title: 'Spanish latte', description: 'Espresso and milk.', image: null, price: null, is_featured: true,
  sizes: [{ id: 1, name: 'Small', price: '14.00' }, { id: 2, name: 'Large', price: '18.00' }],
}
const saudi = { id: 5, title: 'Saudi coffee', description: null, image: null, price: '10.00', sizes: [], is_featured: false }
const cake = { id: 9, title: 'Date cake', description: null, image: null, price: '18.00', sizes: [], is_featured: true }

beforeEach(() => {
  globalThis.__menu = []
  globalThis.__featured = []
})

describe('/coffee-house', () => {
  it('lists each section with its items, one price beside the name and sizes under it', async () => {
    globalThis.__menu = [
      { id: 1, title: 'Hot drinks', items: [saudi, latte] },
      { id: 3, title: 'Sweets', items: [cake] },
    ]
    const wrapper = await mountSuspended(MenuPage)
    await flushPromises()

    expect(wrapper.findAll('[data-test="coffee-section"]').map((s) => s.find('h2').text())).toEqual(['Hot drinks', 'Sweets'])
    const [first, second] = wrapper.findAll('[data-test="coffee-item"]')
    expect(first.text()).toContain('Saudi coffee')
    expect(first.text()).toContain('10.00 SAR')
    expect(second.findAll('li').map((li) => li.findAll('span').map((span) => span.text()))).toEqual([
      ['Small', '14.00 SAR'],
      ['Large', '18.00 SAR'],
    ])

    // The section pills filter on the page.
    const pills = wrapper.findAll('[data-test="coffee-filter"]')
    expect(pills.map((p) => p.text())).toEqual(['All', 'Hot drinks', 'Sweets'])
    await pills[2].trigger('click')
    expect(wrapper.text()).toContain('Date cake')
    expect(wrapper.text()).not.toContain('Spanish latte')
  })

  it('says the menu is coming rather than showing an empty page', async () => {
    const wrapper = await mountSuspended(MenuPage)
    await flushPromises()
    expect(wrapper.find('[data-test="coffee-empty"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="coffee-filter"]').exists()).toBe(false)
  })
})

describe('home — coffee house', () => {
  it('always invites people to the menu, and shows the starred items only when there are some', async () => {
    let wrapper = await mountSuspended(HomeCoffeeHouse)
    await flushPromises()
    expect(wrapper.find('[data-test="home-coffee-menu"]').attributes('href')).toBe('/coffee-house')
    expect(wrapper.find('[data-test="home-coffee-featured"]').exists()).toBe(false)

    globalThis.__featured = [{ ...latte, category: { id: 1, title: 'Hot drinks' } }]
    wrapper = await mountSuspended(HomeCoffeeHouse)
    await flushPromises()
    const featured = wrapper.find('[data-test="home-coffee-featured"]')
    expect(featured.exists()).toBe(true)
    expect(featured.text()).toContain('Spanish latte')
    expect(featured.text()).toContain('Hot drinks')
  })
})
