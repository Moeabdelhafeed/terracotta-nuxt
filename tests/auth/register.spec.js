// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

const { api, lang, sanctum, navigate, routeQuery, authConfig, tokenStorage } = await vi.hoisted(async () => {
  const { ref: r, computed: c } = await import('vue')
  const { vi: v } = await import('vitest')
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  const user = r(null)
  return {
    api: createApiMock({
      'POST /api/check-identifier': envelope({ exists: false }),
      'POST /api/register': () => globalThis.__register(),
    }),
    lang: createLang('en'),
    sanctum: {
      user,
      isAuthenticated: c(() => !!user.value),
      login: v.fn(async () => {
        user.value = { data: { id: 2, is_verified: false } }
        return { data: {} }
      }),
      logout: v.fn(),
      refreshIdentity: v.fn(async () => {
        user.value = { data: { id: 2, is_verified: true } }
      }),
    },
    navigate: v.fn(),
    routeQuery: r({}),
    tokenStorage: { set: v.fn() },
    authConfig: {
      identifiers: c(() => ['email']),
      isMultiIdentifier: c(() => false),
      showsExtraField: () => false,
      isExtraRequired: () => false,
      inputTypeFor: () => 'email',
      placeholderFor: () => 'm@example.com',
      labelFor: (k) => k,
      allowedPhoneCountries: c(() => 'all'),
      allowedEmailDomains: c(() => 'all'),
      isEmailDomainAllowed: () => true,
    },
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useAuthConfig', () => () => authConfig)
mockNuxtImport('useMedia', () => () => ({ mediaAsset: () => null, media: () => null }))
mockNuxtImport('usePages', () => () => ({ pages: ref([]), bySlug: () => null }))
mockNuxtImport('useSanctumAppConfig', () => () => ({ tokenStorage }))
mockNuxtImport('navigateTo', () => navigate)
mockNuxtImport('useRoute', () => () => ({ path: '/register', params: {}, query: routeQuery.value, fullPath: '/register' }))

const Register = (await import('~/pages/register.vue')).default

const mount = () =>
  mountSuspended(Register, { global: { stubs: { AccountTermsModal: true, AppMedia: true, AppConfetti: true } } })

const fill = async (wrapper, { consent = true, confirmation = 'hunter2hunter2' } = {}) => {
  await wrapper.find('#name').setValue('Sara')
  await wrapper.find('#email').setValue('sara@example.com')
  await wrapper.find('#password').setValue('hunter2hunter2')
  await wrapper.find('#confirm').setValue(confirmation)
  if (consent) wrapper.vm.form.policy_agreed = true
  await wrapper.find('form').trigger('submit')
  await flushPromises()
}

const posted = () => api.calls.filter((c) => c.url === '/api/register').length

beforeEach(() => {
  api.calls.length = 0
  navigate.mockClear()
  sanctum.login.mockClear()
  tokenStorage.set.mockClear()
  sanctum.user.value = null
  routeQuery.value = {}
  globalThis.__register = () => ({
    success: true,
    message: 'ok',
    errors: null,
    data: { token: 'tok', user: { id: 2, is_verified: true } },
  })
})

describe('/register', () => {
  it('uses the session register already returned instead of spending a second auth attempt', async () => {
    const wrapper = await mount()
    await fill(wrapper)

    expect(posted()).toBe(1)
    expect(tokenStorage.set).toHaveBeenCalled()
    expect(sanctum.login).not.toHaveBeenCalled()
    expect(wrapper.find('[data-test="register-success"]').exists()).toBe(true)
  })

  it('signs in for the code screen when verification is required and no token came back', async () => {
    globalThis.__register = () => ({
      success: true,
      message: 'ok',
      errors: null,
      data: { user: { id: 2, is_verified: false } },
    })
    const wrapper = await mount()
    await fill(wrapper)

    expect(sanctum.login).toHaveBeenCalled()
    expect(navigate).toHaveBeenCalledWith({ name: 'verify' })
    // The module used to send them to `redirect.onLogin` on its way, so the home page
    // was painted for a moment first. Nothing but the code screen now.
    expect(navigate).toHaveBeenCalledTimes(1)
  })

  it('says why an unticked consent box blocks the form instead of failing silently', async () => {
    const wrapper = await mount()
    await fill(wrapper, { consent: false })

    expect(posted()).toBe(0)
    expect(wrapper.text()).toContain('Accept the terms to continue.')
  })

  it('does not register two passwords that differ', async () => {
    const wrapper = await mount()
    await fill(wrapper, { confirmation: 'hunter3hunter3' })

    expect(posted()).toBe(0)
    expect(wrapper.text()).toContain('The two passwords do not match.')
  })
})
