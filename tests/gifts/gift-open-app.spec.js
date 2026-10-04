// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

const TOKEN = '18d08cb9-0843-4865-9c40-11a470b183db'

/**
 * The Claim button on a phone: the link always opens this page (the gift is the page), and
 * the button tries the app first, then falls back to signing in on the website.
 */
const { api, lang, sanctum, giftRef, navigate, openApp } = await vi.hoisted(async () => {
  const { ref } = await import('vue')
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'POST /api/gifts/{token}/redeem': envelope({ amount: '200.00', wallet_balance: '250.00' }, 'Gift redeemed successfully.'),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(null),
    giftRef: ref(null),
    navigate: v.fn(),
    openApp: v.fn(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useRoute', () => () => ({ params: { token: TOKEN }, query: {} }))
mockNuxtImport('navigateTo', () => navigate)
mockNuxtImport('useDevice', () => () => ({ os: ref('ios'), deviceId: ref('test-device'), platform: ref('web') }))
mockNuxtImport('openApp', () => openApp)
mockNuxtImport('useGSAP', () => () => ({ matchMedia: () => ({ add: () => {}, revert: () => {} }), from: () => {} }))
mockNuxtImport('useFetch', () => () => ({ data: giftRef, error: ref(null), refresh: vi.fn(), pending: ref(false), status: ref('success') }))

const GiftLanding = (await import('~/pages/gift/[token].vue')).default

const mount = () => mountSuspended(GiftLanding, { global: { stubs: { AppCurtain: true, AppConfetti: true } } })
const pressClaim = async (wrapper) => {
  await wrapper.findAll('button').find((b) => b.text().includes('Claim your gift')).trigger('click')
  await flushPromises()
}

describe('/gift/[token] on a phone', () => {
  beforeEach(() => {
    api.calls.length = 0
    navigate.mockClear()
    openApp.mockReset()
    sessionStorage.clear()
    sanctum.user.value = null
    giftRef.value = {
      token: TOKEN, recipient_name: 'Sara', message: 'Happy birthday!', amount: '200.00', from: 'Nour',
      is_redeemed: false, redeemed_at: null, is_claimable: true,
      deep_link: `terracotta://gift/${TOKEN}`, store_links: [],
    }
  })

  it('hands the gift to the app when it is installed, and stays on the page', async () => {
    openApp.mockResolvedValue(true)
    const wrapper = await mount()

    // One button; the old separate "Open in the app" is gone.
    expect(wrapper.text()).not.toContain('Open in the app')
    await pressClaim(wrapper)

    expect(openApp).toHaveBeenCalledWith(`terracotta://gift/${TOKEN}`)
    expect(navigate).not.toHaveBeenCalled()
    expect(api.calls).toHaveLength(0) // the app claims it, not the page
  })

  it('falls back to signing in on the website when the app does not open', async () => {
    openApp.mockResolvedValue(false)
    const wrapper = await mount()
    await pressClaim(wrapper)

    expect(navigate).toHaveBeenCalledWith({ path: '/login', query: { redirect: `/gift/${TOKEN}` } })
    expect(sessionStorage.getItem('gift:pending')).toBe(TOKEN) // claimed on the way back
  })

  it('claims right here for someone already signed in on the website — same wallet', async () => {
    sanctum.user.value = { data: { id: 7, is_guest: false } }
    const wrapper = await mount()
    await pressClaim(wrapper)

    expect(openApp).not.toHaveBeenCalled()
    expect(api.calls.map((c) => c.url)).toContain(`/api/gifts/${TOKEN}/redeem`)
  })

  it('goes straight to website sign-in when the app has no deep link yet', async () => {
    giftRef.value = { ...giftRef.value, deep_link: null }
    const wrapper = await mount()
    await wrapper.findAll('button').find((b) => b.text().includes('Sign in to claim')).trigger('click')
    await flushPromises()

    expect(openApp).not.toHaveBeenCalled()
    expect(navigate).toHaveBeenCalledWith({ path: '/login', query: { redirect: `/gift/${TOKEN}` } })
  })
})
