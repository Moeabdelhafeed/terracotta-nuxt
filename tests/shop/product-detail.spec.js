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

const ProductDetailView = (await import('~/components/shop/ProductDetailView.vue')).default

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

  it('hands the buy control the chosen glaze, and the first one until one is picked', async () => {
    const wrapper = await mount({ colors: ['#81341a', '#345a4a'] })
    const buy = wrapper.findComponent({ name: 'ShopAddToCart' })

    // The app sends `colors.first` when nobody touches a swatch — an unglazed line is
    // never what the customer picked.
    expect(buy.props('colour')).toBe('#81341a')

    await wrapper.findAll('button[title]').at(1).trigger('click')
    expect(buy.props('colour')).toBe('#345a4a')
  })
})
