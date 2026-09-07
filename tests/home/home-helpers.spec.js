// @vitest-environment nuxt
import { describe, it, expect } from 'vitest'
import { createLang } from '../helpers/mockApi'

const { bannerRoute, isExternalRoute, isBannerRenderable, galleryCounts } = await import('~/composables/useHome')

const banner = (link_type, extra = {}) => ({ id: 1, title: 'Promo', link_type, link_target_id: null, link: null, ...extra })

// `GET /api/pages` sends the slug; `GET /api/home` only ever sends the numeric page id.
const PAGES = [
  { id: 4, slug: 'terms', name: 'Terms' },
  { id: 9, slug: 'about-us', name: 'About' },
]

describe('bannerRoute', () => {
  it('leaves a decorative banner untappable', () => {
    expect(bannerRoute(banner('none'))).toBeNull()
  })

  it('hands back the raw URL for an external banner', () => {
    expect(bannerRoute(banner('external', { link: 'https://instagram.com/terracotta' })))
      .toBe('https://instagram.com/terracotta')
  })

  it('treats an external banner with no URL as decorative', () => {
    expect(bannerRoute(banner('external'))).toBeNull()
  })

  it('maps the shop types', () => {
    expect(bannerRoute(banner('shop_home'))).toBe('/shop')
    expect(bannerRoute(banner('shop_category', { link_target_id: 3 }))).toBe('/shop?category=3')
    expect(bannerRoute(banner('shop_product', { link_target_id: 12 }))).toBe('/shop/12')
  })

  it('maps the workshop types', () => {
    expect(bannerRoute(banner('workshops'))).toBe('/workshops')
    expect(bannerRoute(banner('workshop', { link_target_id: 7 }))).toBe('/workshops/7')
  })

  it('maps the gallery types', () => {
    expect(bannerRoute(banner('gallery_home'))).toBe('/gallery')
    expect(bannerRoute(banner('gallery_category', { link_target_id: 2 }))).toBe('/gallery/2')
  })

  it('resolves a page id to its slug', () => {
    expect(bannerRoute(banner('page', { link_target_id: 9 }), PAGES)).toBe('/about-us')
  })

  it('gives up on a page id no published page matches', () => {
    expect(bannerRoute(banner('page', { link_target_id: 99 }), PAGES)).toBeNull()
    expect(bannerRoute(banner('page', { link_target_id: 9 }))).toBeNull()
  })

  it('treats an unknown link type as decorative', () => {
    expect(bannerRoute(banner('teleporter'))).toBeNull()
    expect(bannerRoute(null)).toBeNull()
  })
})

describe('isExternalRoute', () => {
  it('separates absolute URLs from site paths', () => {
    expect(isExternalRoute('https://instagram.com/terracotta')).toBe(true)
    expect(isExternalRoute('http://example.com')).toBe(true)
    expect(isExternalRoute('/shop?category=3')).toBe(false)
    expect(isExternalRoute(null)).toBe(false)
  })
})

describe('isBannerRenderable', () => {
  it('keeps an untappable banner but drops one pointing at a page that is gone', () => {
    expect(isBannerRenderable(banner('none'), null)).toBe(true)
    expect(isBannerRenderable(banner('page', { link_target_id: 99 }), null)).toBe(false)
    expect(isBannerRenderable(banner('page', { link_target_id: 9 }), '/about-us')).toBe(true)
  })
})

describe('galleryCounts', () => {
  it('reads the album counts in the current language', () => {
    const album = { id: 1, images_count: 10, videos_count: 11 }
    expect(galleryCounts(album, createLang('en').t)).toBe('10 photos · 11 videos')
    expect(galleryCounts(album, createLang('ar').t)).toBe('10 صورة · 11 فيديو')
  })

  it('reads a missing count as zero rather than printing the placeholder', () => {
    expect(galleryCounts({ id: 1 }, createLang('en').t)).toBe('0 photos · 0 videos')
  })
})
