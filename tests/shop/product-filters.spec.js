// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { nextTick, ref } from 'vue'

const categories = [
  { id: 3, title: 'Mugs', sub_categories: [{ id: 7, title: 'Espresso' }] },
]

const { api, lang } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/shop/categories': () => envelope(globalThis.__categories),
      'GET /api/shop/products': () => envelope({ data: [], current_page: 1, last_page: 1, total: 0 }),
    }),
    lang: createLang('en'),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: ref('SAR') }))

const ShopProductFilters = (await import('~/components/shop/ShopProductFilters.vue'))
const Filters = ShopProductFilters.default
const { productApiQuery, PRODUCTS_PER_PAGE } = ShopProductFilters

beforeEach(() => {
  globalThis.__categories = categories
  api.$fetch.mockClear()
})

const mount = (query = {}) => mountSuspended(Filters, { props: { query } })

describe('productApiQuery', () => {
  it('sends no sort key at all while the studio order is selected', () => {
    expect('sort' in productApiQuery({})).toBe(false)
    expect('sort' in productApiQuery({ sort: '' })).toBe(false)
    expect('sort' in productApiQuery({ sort: 'cheapest' })).toBe(false)
  })

  it('passes the three sorts the endpoint knows', () => {
    expect(productApiQuery({ sort: 'newest' }).sort).toBe('newest')
    expect(productApiQuery({ sort: 'price_asc' }).sort).toBe('price_asc')
    expect(productApiQuery({ sort: 'price_desc' }).sort).toBe('price_desc')
  })

  it('keeps the existing filters and paging alongside the new ones', () => {
    expect(productApiQuery({ category: '3', sub: '7', search: 'mug', featured: '1', sale: '1', page: '2' })).toEqual({
      category_id: 3,
      sub_category_id: 7,
      search: 'mug',
      featured: 1,
      on_sale: 1,
      page: 2,
      per_page: PRODUCTS_PER_PAGE,
    })
  })

  it('sends a price bound only when it is a usable number', () => {
    expect(productApiQuery({ min_price: '40', max_price: '90' })).toMatchObject({ min_price: 40, max_price: 90 })
    expect(productApiQuery({ min_price: '' })).not.toHaveProperty('min_price')
    expect(productApiQuery({ min_price: 'abc' })).not.toHaveProperty('min_price')
    expect(productApiQuery({ min_price: '-5' })).not.toHaveProperty('min_price')
  })

  it('drops a maximum under the minimum rather than earning a 422', () => {
    const query = productApiQuery({ min_price: '90', max_price: '40' })
    expect(query.min_price).toBe(90)
    expect(query).not.toHaveProperty('max_price')
  })
})

describe('ShopProductFilters', () => {
  // A shadcn/reka Select: its items live in a portal and only exist while it is open, so
  // a choice is a press on the trigger followed by a press on the option.
  const pick = async (select, label) => {
    await select.trigger('pointerdown', { button: 0, ctrlKey: false })
    await flushPromises()
    const option = [...document.querySelectorAll('[role="option"]')].find((o) =>
      o.textContent.includes(label),
    )
    option.dispatchEvent(new window.PointerEvent('pointerup', { bubbles: true }))
    await flushPromises()
  }

  it('defaults the sort control to the studio order', async () => {
    const wrapper = await mount()
    expect(wrapper.find('[data-test="product-sort"]').text()).toContain('Studio order')
  })

  it('asks for a sort by name, and clears it back to the studio order', async () => {
    const wrapper = await mount({ sort: 'price_asc' })
    const select = wrapper.find('[data-test="product-sort"]')
    expect(select.text()).toContain('Price: low to high')

    await pick(select, 'Price: high to low')
    expect(wrapper.emitted('apply').at(-1)[0]).toEqual({ sort: 'price_desc' })

    // The studio's own order is `null` on the wire, never the name it travels under.
    await pick(select, 'Studio order')
    expect(wrapper.emitted('apply').at(-1)[0]).toEqual({ sort: null })
  })
})

describe('ShopProductFilters price range', () => {
  afterEach(() => { vi.useRealTimers() })

  it('waits for typing to settle instead of asking on every keystroke', async () => {
    const wrapper = await mount()
    vi.useFakeTimers()

    const min = wrapper.find('[data-test="price-min"]')
    await min.setValue('4')
    await min.setValue('40')
    vi.advanceTimersByTime(200)
    expect(wrapper.emitted('apply')).toBeUndefined()

    vi.advanceTimersByTime(600)
    await flushPromises()
    expect(wrapper.emitted('apply')).toHaveLength(1)
    expect(wrapper.emitted('apply')[0][0]).toEqual({ min_price: 40, max_price: null })
  })

  it('says so and asks for nothing when the top is under the bottom', async () => {
    const wrapper = await mount({ min_price: '90' })
    vi.useFakeTimers()

    await wrapper.find('[data-test="price-max"]').setValue('40')
    vi.advanceTimersByTime(1000)
    await flushPromises()

    expect(wrapper.emitted('apply')).toBeUndefined()
    expect(wrapper.find('[data-test="price-hint"]').exists()).toBe(true)
  })

  it('clears both bounds in one tap', async () => {
    const wrapper = await mount({ min_price: '40', max_price: '90' })
    vi.useFakeTimers()

    await wrapper.find('[data-test="price-clear"]').trigger('click')
    vi.advanceTimersByTime(1000)
    await flushPromises()

    expect(wrapper.emitted('apply').at(-1)[0]).toEqual({ min_price: null, max_price: null })
  })
})

describe('ShopProductFilters active filters', () => {
  it('names every filter in force and clears them one at a time', async () => {
    const wrapper = await mount({ category: '3', sub: '7', search: 'mug', sale: '1', min_price: '40', max_price: '90', sort: 'price_asc' })
    await flushPromises()
    await nextTick()

    const chips = wrapper.findAll('[data-test="active-filters"] button')
    const text = wrapper.find('[data-test="active-filters"]').text()

    expect(text).toContain('Mugs')
    expect(text).toContain('Espresso')
    expect(text).toContain('mug')
    expect(text).toContain('On sale')
    expect(text).toContain('40 SAR – 90 SAR')
    expect(text).toContain('Price: low to high')

    await chips.at(-2).trigger('click')
    expect(wrapper.emitted('apply').at(-1)[0]).toEqual({ sort: null })
  })

  it('shows nothing to clear on an unfiltered list', async () => {
    const wrapper = await mount()
    expect(wrapper.find('[data-test="active-filters"]').exists()).toBe(false)
  })
})
