// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang, sanctum } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/shop/cart': envelope({ items: [], total_price: '0.00' }),
      'GET /api/shop/favorites': envelope([]),
      'GET /api/notifications': envelope([]),
    }),
    lang: createLang('ar'),
    sanctum: createSanctumState(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)

const AppBottomNav = (await import('~/components/AppBottomNav.vue')).default

describe('AppBottomNav — About Terracotta', () => {
  it('puts the studio, its projects and its news behind one About entry', async () => {
    const wrapper = await mountSuspended(AppBottomNav, {
      attachTo: document.body,
      global: { stubs: { LanguageSwitcher: true, NotificationBell: true } },
    })
    await flushPromises()

    // The bar keeps one About item, opening upward rather than adding two links of width.
    const trigger = wrapper.find('[data-test="nav-dropdown"]')
    expect(trigger.text()).toContain('عن تيراكوتا')
    expect(wrapper.find('nav a[href="/about/projects"]').exists()).toBe(false)

    // The phone menu shows the group open: its name, then its three pages.
    await wrapper.find('[data-test="nav-fab"]').trigger('click')
    await flushPromises()
    const menu = document.querySelector('[data-test="nav-menu"]')
    const hrefs = [...menu.querySelectorAll('a')].map((a) => a.getAttribute('href'))
    expect(hrefs).toEqual(expect.arrayContaining(['/about', '/about/projects', '/about/news']))
    expect(menu.textContent).toContain('مشاريعنا')
    expect(menu.textContent).toContain('أخبار تيراكوتا')

    wrapper.unmount()
  })
})
