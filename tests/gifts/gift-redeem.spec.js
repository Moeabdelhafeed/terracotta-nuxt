// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

const TOKEN = '18d08cb9-0843-4865-9c40-11a470b183db'

/** The narrow public preview — deliberately without any of the buyer's money fields. */
const preview = (over = {}) => ({
  token: TOKEN,
  recipient_name: 'Sara',
  message: 'Happy birthday!',
  amount: '200.00',
  from: 'Nour',
  is_redeemed: false,
  redeemed_at: null,
  is_claimable: true,
  deep_link: `terracotta://gift/${TOKEN}`,
  store_links: [{ type: 'app_store', url: 'https://apps.apple.com/app/id1' }],
  ...over,
})

const { api, lang, sanctum, giftRef, navigate } = await vi.hoisted(async () => {
  const { ref } = await import('vue')
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'POST /api/gifts/{token}/redeem': envelope({ amount: '200.00', wallet_balance: '250.00' }, 'Gift redeemed successfully.'),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState({ id: 7, name: 'Sara', is_guest: false }),
    giftRef: ref(null),
    navigate: v.fn(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useMedia', () => () => ({ mediaAsset: () => null, media: () => null }))
mockNuxtImport('useRoute', () => () => ({ params: { token: TOKEN }, query: {} }))
mockNuxtImport('navigateTo', () => navigate)
mockNuxtImport('useGSAP', () => () => ({
  matchMedia: () => ({ add: () => {}, revert: () => {} }),
  from: () => {},
}))
mockNuxtImport('useFetch', () => () => ({
  data: giftRef,
  error: ref(null),
  refresh: vi.fn(),
  pending: ref(false),
  status: ref('success'),
}))

const GiftLanding = (await import('~/pages/gift/[token].vue')).default

const mount = () => mountSuspended(GiftLanding, {
  global: { stubs: { AppCurtain: true, AppConfetti: true, AppMedia: true } },
})

describe('/gift/[token] — public preview', () => {
  beforeEach(() => {
    api.calls.length = 0
    sanctum.user.value = { data: { id: 7, name: 'Sara', is_guest: false } }
    giftRef.value = preview()
    sessionStorage.clear()
  })

  it('renders the gift without a single buyer money field', async () => {
    // A payload carrying everything the buyer's own order would: if the page leaked any of
    // it, these numbers would show up. `server/api/gift/[token].get.js` allow-lists the
    // public fields, but the page must not render them even when handed them.
    giftRef.value = preview({
      subtotal: '250.00',
      discount_amount: '50.00',
      discount_code: 'FRIEND50',
      total_price: '250.00',
      wallet_applied: '110.00',
      amount_due: '140.00',
      vat_amount: '32.61',
      buyer_name: 'Nour Al-Otaibi',
      buyer_phone: '+966501234567',
      payment_status: 'paid',
    })

    const wrapper = await mount()
    const text = wrapper.text()
    expect(text).toContain('200.00 SAR')
    expect(text).toContain('Happy birthday!')

    for (const leak of ['250.00', '50.00', '110.00', '140.00', '32.61', 'FRIEND50', 'Nour Al-Otaibi', '+966501234567']) {
      expect(text).not.toContain(leak)
    }
    expect(text).not.toMatch(/total|wallet applied|discount|amount due/i)
    expect(wrapper.html()).not.toContain('total_price')
  })
})

describe('/gift/[token] — who may claim', () => {
  beforeEach(() => {
    api.calls.length = 0
    giftRef.value = preview()
    sessionStorage.clear()
    navigate.mockClear()
  })

  it('offers the claim button to a signed-in registered user', async () => {
    sanctum.user.value = { data: { id: 7, is_guest: false } }
    const wrapper = await mount()
    expect(wrapper.text()).toContain('Claim your gift')
    expect(wrapper.text()).not.toContain('Sign in to claim')
  })

  it('sends an anonymous visitor to sign in instead', async () => {
    sanctum.user.value = null
    const wrapper = await mount()
    expect(wrapper.text()).toContain('Sign in to claim your gift')
    expect(wrapper.text()).not.toContain('Claim your gift')
  })

  it('treats a guest session as anonymous — a guest has no wallet to credit', async () => {
    sanctum.user.value = { data: { id: 99, is_guest: true } }
    const wrapper = await mount()
    expect(wrapper.text()).toContain('Sign in to claim your gift')
  })

  it('parks the token before sending the visitor to login, and resumes on the way back', async () => {
    sanctum.user.value = null
    const wrapper = await mount()
    await wrapper.findAll('button').find((b) => b.text().includes('Sign in')).trigger('click')

    expect(navigate).toHaveBeenCalledWith({ path: '/login', query: { redirect: `/gift/${TOKEN}` } })
    expect(sessionStorage.getItem('gift:pending')).toBe(TOKEN)

    // Same link, now with a session: the parked intent is spent without another tap.
    sanctum.user.value = { data: { id: 7, is_guest: false } }
    const back = await mount()
    await flushPromises()
    expect(api.calls.map((c) => c.url)).toContain(`/api/gifts/${TOKEN}/redeem`)
    expect(back.text()).toContain('250.00 SAR')
    expect(sessionStorage.getItem('gift:pending')).toBe(null)
  })
})

describe('/gift/[token] — redeeming', () => {
  beforeEach(() => {
    api.calls.length = 0
    sanctum.user.value = { data: { id: 7, is_guest: false } }
    giftRef.value = preview()
    sessionStorage.clear()
    api.table['POST /api/gifts/{token}/redeem'] = { success: true, message: 'ok', errors: null, data: { amount: '200.00', wallet_balance: '250.00' } }
  })

  const claim = async (wrapper) => {
    await wrapper.findAll('button').find((b) => b.text().includes('Claim')).trigger('click')
    await flushPromises()
  }

  it('credits the wallet and shows the new balance with a way to it', async () => {
    const wrapper = await mount()
    await claim(wrapper)

    expect(api.calls[0].url).toBe(`/api/gifts/${TOKEN}/redeem`)
    expect(wrapper.text()).toContain('200.00 SAR has been added to your wallet.')
    expect(wrapper.text()).toContain('250.00 SAR')
    expect(wrapper.find('a[href="/wallet"]').exists()).toBe(true)
  })

  it.each([
    ['gift_already_redeemed', 'This gift has already been redeemed.'],
    ['gift_not_paid', 'This gift has not been paid for yet.'],
    ['gift_cannot_redeem_own', "You can't redeem a gift you bought yourself."],
    ['gift_unavailable', 'Gift purchases are unavailable right now.'],
  ])('renders the server message for %s', async (_key, message) => {
    const { apiError } = await import('../helpers/mockApi')
    api.table['POST /api/gifts/{token}/redeem'] = apiError(422, { gift: [message] }, message)

    const wrapper = await mount()
    await claim(wrapper)

    expect(wrapper.text()).toContain(message)
    expect(wrapper.text()).not.toContain('has been added to your wallet')
  })
})

describe('/gift/[token] — a spent link', () => {
  it('says the gift is claimed and offers nothing to press', async () => {
    sanctum.user.value = { data: { id: 7, is_guest: false } }
    giftRef.value = preview({ is_redeemed: true, is_claimable: false, store_links: [] })
    const wrapper = await mount()
    expect(wrapper.text()).toContain('This gift has already been claimed.')
    expect(wrapper.text()).not.toContain('Claim your gift')
  })
})
