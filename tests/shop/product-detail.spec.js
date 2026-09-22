// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const { api, lang, sanctum, toast } = await vi.hoisted(async () => {
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/shop/cart': () => envelope({ items: [], total_price: '0.00' }),
      'GET /api/shop/products/{id}': () => envelope({ id: 11, title: 'Cup', price: '45.00' }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
    toast: { success: v.fn(), error: v.fn(), info: v.fn() },
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useToast', () => () => toast)
mockNuxtImport('useRoute', () => () => ({ params: { id: '11' }, query: {}, fullPath: '/shop/11' }))

const ProductDetailView = (await import('~/components/ProductDetailView.vue')).default

const product = (over = {}) => ({
  id: 11,
  title: 'Abbasi Cup',
  category: 'Cups',
  price: '45.00',
  sale_price: '35.00',
  description: '<p>Hand-thrown stoneware.</p>',
  colors: ['#81341a'],
  height: '8.00',
  width: '6.00',
  in_stock: true,
  stock: 40,
  max_quantity: 40,
  image: { image_api: 'https://example.test/cup.webp' },
  ...over,
})

const mount = (over) =>
  mountSuspended(ProductDetailView, {
    props: { product: product(over), status: 'success', sectionTo: '/shop', sectionLabel: 'Shop' },
  })

/**
 * This file shipped once with `<script setup>` nested inside `<template>`. It compiled,
 * it built, and every other suite stayed green — the page simply rendered a picture and
 * nothing else: no title, no price, no way to buy. These assert the parts that vanished.
 */
describe('the photographs', () => {
  const shots = {
    images: [
      { id: 1, image_api: 'https://example.test/one.webp' },
      { id: 2, image_api: 'https://example.test/two.webp' },
      { id: 3, image_api: 'https://example.test/three.webp' },
    ],
  }

  const shown = (wrapper) =>
    wrapper.find('[data-test="shot-next"]').element.parentElement.querySelector('img').getAttribute('src')

  // This used to hold the chosen image OBJECT and ask `shots.includes(it)` — an identity
  // test that fails the moment the product ref is rebuilt, so the view fell back to the
  // first photograph and the picker looked like it did nothing at all.
  it('shows the photograph the reader picked', async () => {
    const wrapper = await mount(shots)

    await wrapper.find('[data-shot="2"]').trigger('click')
    expect(shown(wrapper)).toBe('https://example.test/three.webp')

    await wrapper.find('[data-shot="0"]').trigger('click')
    expect(shown(wrapper)).toBe('https://example.test/one.webp')
  })

  it('wraps at both ends, so an arrow never dead-ends', async () => {
    const wrapper = await mount(shots)

    await wrapper.find('[data-test="shot-prev"]').trigger('click')
    expect(shown(wrapper)).toBe('https://example.test/three.webp')

    await wrapper.find('[data-test="shot-next"]').trigger('click')
    expect(shown(wrapper)).toBe('https://example.test/one.webp')
  })

  it('marks which one is showing, and leaves the set alone when there is only one', async () => {
    const many = await mount(shots)
    expect(many.findAll('[data-test="shot-indicator"] button')).toHaveLength(3)
    expect(many.find('[data-shot="0"]').attributes('aria-current')).toBe('true')
    expect(many.find('[data-shot="1"]').attributes('aria-current')).toBeUndefined()

    const one = await mount()
    expect(one.find('[data-test="shot-indicator"]').exists()).toBe(false)
    expect(one.find('[data-test="shot-next"]').exists()).toBe(false)
  })
})

describe('ProductDetailView', () => {
  it('renders the piece, its price and a way to buy it', async () => {
    const wrapper = await mount()

    expect(wrapper.find('h1').text()).toBe('Abbasi Cup')
    expect(wrapper.text()).toContain('35.00 SAR')
    expect(wrapper.text()).toContain('Hand-thrown stoneware.')
    expect(wrapper.findComponent({ name: 'ShopAddToCart' }).exists()).toBe(true)
    expect(wrapper.findComponent({ name: 'ShopFavoriteButton' }).exists()).toBe(true)
  })

  it('strikes the original price only while the piece is on offer', async () => {
    expect((await mount()).text()).toContain('45.00 SAR')
    expect((await mount({ sale_price: null })).text()).not.toContain('45.00 SAR line-through')
  })

  it('names a bare hex glaze and lists the dimensions it has', async () => {
    const text = (await mount()).text()

    // #81341a lands nearest Rust (#8b4513) in RGB, not the studio's own Terracotta.
    expect(text).toContain('Rust')
    expect(text).toContain('8 cm')
    expect(text).not.toContain('Length')
  })

  /**
   * A legend, not a picker: `shop_cart_items` has no colour column and the cart endpoint
   * accepts none, so there is no variant to choose. Drawn as buttons with a selected
   * ring, they promised one the studio cannot sell separately.
   */
  it('shows the colours a piece comes in, with nothing to press', async () => {
    const wrapper = await mount({ colors: ['#81341a', '#345a4a'] })
    const swatches = wrapper.findAll('[role="tooltip"]')

    expect(swatches).toHaveLength(2)
    expect(wrapper.findAll('button[title]')).toHaveLength(0)
  })

  it('names each colour for a pointer and for a screen reader alike', async () => {
    const wrapper = await mount({ colors: ['#81341a'] })

    // The hover label and the off-screen copy carry the same name.
    expect(wrapper.find('[role="tooltip"]').text()).not.toBe('')
    expect(wrapper.find('.sr-only').text()).toBe(wrapper.find('[role="tooltip"]').text())
  })
})

