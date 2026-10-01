// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const image = (name) => ({ id: name.length, url: `x/${name}.webp`, type: 'webp', blurhash: null, image_api: `https://cdn.test/${name}.webp` })

const { api, lang } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/media': envelope({ group: 'web', media: {} }),
      'GET /api/about/sections': () => envelope(globalThis.__sections),
      'GET /api/projects': () => envelope(globalThis.__projects),
      'GET /api/news': () => envelope(globalThis.__news),
    }),
    lang: createLang('en'),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)

const AboutPage = (await import('~/pages/about/index.vue')).default
const ProjectsPage = (await import('~/pages/about/projects/index.vue')).default
const NewsPage = (await import('~/pages/about/news/index.vue')).default

const project = (over = {}) => ({ id: 1, title: 'Breakfast sets', client_type: 'hotel', client_name: null, city: 'Riyadh', year: 2026, logo: null, image: image('cover'), ...over })
const news = (over = {}) => ({ id: 1, type: 'conference', title: 'Crafts conference', place: 'Riyadh', starts_on: '2026-09-12', ends_on: null, link: null, image: null, ...over })

beforeEach(() => {
  globalThis.__sections = []
  globalThis.__projects = []
  globalThis.__news = []
})

describe('About page', () => {
  it('stacks the CMS blocks in order, swapping sides on every second pictured section', async () => {
    globalThis.__sections = [
      { id: 1, type: 'section', eyebrow: 'Our story', title: 'How it started', body: 'One wheel.', image: image('story') },
      { id: 2, type: 'banner', eyebrow: null, title: 'Everyone can make something', body: 'An afternoon.', image: null },
      { id: 3, type: 'section', eyebrow: 'The craft', title: 'How we work', body: 'Fired twice.', image: image('craft') },
      { id: 4, type: 'section', eyebrow: null, title: 'Words only', body: 'No picture here.', image: null },
    ]

    const wrapper = await mountSuspended(AboutPage)
    await flushPromises()

    const titles = wrapper.findAll('h2').map((h) => h.text())
    expect(titles.slice(0, 4)).toEqual(['How it started', 'Everyone can make something', 'How we work', 'Words only'])

    const sections = wrapper.findAll('[data-test="about-section"]')
    expect(sections[0].html()).not.toContain('lg:order-2') // first pictured: picture leads
    expect(sections[1].html()).toContain('lg:order-2') // second pictured: mirrored
    expect(sections[2].find('img').exists()).toBe(false) // copy alone, centred
    expect(wrapper.findAll('[data-test="about-banner"]')).toHaveLength(1)
  })

  it('shows the project and news teasers only once there is something in them', async () => {
    let wrapper = await mountSuspended(AboutPage)
    await flushPromises()
    expect(wrapper.find('[data-test="about-projects"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="about-news"]').exists()).toBe(false)

    globalThis.__projects = [project()]
    globalThis.__news = [news()]
    wrapper = await mountSuspended(AboutPage)
    await flushPromises()

    const teaser = wrapper.find('[data-test="about-projects"]')
    // An unnamed client reads as the kind of place and the city.
    expect(teaser.text()).toContain('Hotel · Riyadh · 2026')
    expect(teaser.find('a[href="/about/projects/1"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="about-news"] a[href="/about/news/1"]').exists()).toBe(true)
  })
})

describe('Projects page', () => {
  it('offers a filter only for the kinds of client the studio has worked for', async () => {
    globalThis.__projects = [
      project({ id: 1, client_type: 'hotel', title: 'Lobby vases' }),
      project({ id: 2, client_type: 'restaurant', client_name: 'Al Bait', title: 'Serving plates' }),
    ]

    const wrapper = await mountSuspended(ProjectsPage)
    await flushPromises()

    const pills = wrapper.findAll('[data-test="project-filter"]')
    expect(pills.map((p) => p.text())).toEqual(['All', 'Hotel', 'Restaurant'])
    expect(wrapper.text()).toContain('Al Bait · Riyadh')

    await pills[2].trigger('click')
    expect(wrapper.text()).toContain('Serving plates')
    expect(wrapper.text()).not.toContain('Lobby vases')
  })
})

describe('News page', () => {
  it('groups events by their own year, newest first', async () => {
    globalThis.__news = [
      news({ id: 3, title: 'Crafts conference', starts_on: '2026-09-12' }),
      news({ id: 2, type: 'event', title: 'Summer festival', starts_on: '2026-08-28' }),
      news({ id: 1, type: 'event', title: 'Open workshop', starts_on: '2025-12-14' }),
    ]

    const wrapper = await mountSuspended(NewsPage)
    await flushPromises()

    const years = wrapper.findAll('[data-test="news-year"]')
    expect(years.map((y) => y.find('h2').text())).toEqual(['2026', '2025'])
    expect(years[0].text()).toContain('Crafts conference')
    expect(years[0].text()).toContain('Summer festival')
    expect(years[1].text()).toContain('Open workshop')

    const conferences = wrapper.findAll('[data-test="news-filter"]')[2]
    expect(conferences.text()).toBe('Conference')
    await conferences.trigger('click')
    expect(wrapper.text()).not.toContain('Summer festival')
  })
})
