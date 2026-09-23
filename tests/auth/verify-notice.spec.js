// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { ref } from 'vue'

const { lang, user } = await vi.hoisted(async () => {
  const { ref: r } = await import('vue')
  const { createLang } = await import('../helpers/mockApi')
  return { lang: createLang('en'), user: r(null) }
})

mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => ({ user, isAuthenticated: ref(true) }))

const VerifyNotice = (await import('~/components/AccountVerifyNotice.vue')).default

const shown = async () => (await mountSuspended(VerifyNotice)).find('[data-test="verify-notice"]')

describe('the unverified-account notice', () => {
  it('tells a registered account that has not entered its code', async () => {
    user.value = { data: { id: 1, is_guest: false, verified_at: null, phone: '+966500000000' } }
    const notice = await shown()

    expect(notice.exists()).toBe(true)
    expect(notice.text()).toContain('Your account is not verified')
    // Named, so it is obvious which inbox or handset to look at.
    expect(notice.text()).toContain('+966500000000')
    expect(notice.attributes('href')).toBe('/verify')
  })

  it('says nothing to a verified account', async () => {
    user.value = { data: { id: 1, is_guest: false, verified_at: '2026-09-01T10:00:00Z' } }
    expect((await shown()).exists()).toBe(false)
  })

  // A guest has nothing to verify, and being asked to confirm an account they never made
  // is how a browsing visitor ends up on a screen with no way forward.
  it('says nothing to a guest', async () => {
    user.value = { data: { id: 2, is_guest: true, verified_at: null } }
    expect((await shown()).exists()).toBe(false)
  })
})
