// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'

const { api, lang, sanctum, navigate, routeQuery } = await vi.hoisted(async () => {
  const { ref: r, computed: c } = await import('vue')
  const { vi: v } = await import('vitest')
  const { createApiMock, createLang } = await import('../helpers/mockApi')
  const user = r(null)
  return {
    api: createApiMock({
      'POST /api/change-forgot-password': () => globalThis.__changePassword(),
    }),
    lang: createLang('en'),
    sanctum: {
      user,
      isAuthenticated: c(() => !!user.value),
      login: v.fn(async () => ({ data: { token_id: 3 } })),
      logout: v.fn(),
      refreshIdentity: v.fn(),
    },
    navigate: v.fn(),
    routeQuery: r({ identifier: 'sara@example.com', type: 'email', otp: '123456' }),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useMedia', () => () => ({ mediaAsset: () => null, media: () => null }))
mockNuxtImport('navigateTo', () => navigate)
mockNuxtImport('useRoute', () => () => ({
  path: '/forgot-password/reset',
  params: {},
  query: routeQuery.value,
  fullPath: '/forgot-password/reset',
}))

const ResetPassword = (await import('~/pages/forgot-password/reset.vue')).default

const mount = () => mountSuspended(ResetPassword, { global: { stubs: { AppMedia: true } } })

const submit = async (wrapper, password = 'hunter2hunter2', confirmation = password) => {
  await wrapper.find('#password').setValue(password)
  await wrapper.find('#confirm').setValue(confirmation)
  await wrapper.find('form').trigger('submit')
  await flushPromises()
}

const ok = () => ({ success: true, message: 'ok', errors: null, data: null })
const otpExpired = () => {
  const err = new Error('The given data was invalid.')
  err.status = 422
  err.data = { message: 'The given data was invalid.', errors: { otp: ['This code has expired.'] } }
  throw err
}

beforeEach(() => {
  api.calls.length = 0
  navigate.mockClear()
  sanctum.login.mockClear()
  sanctum.login.mockImplementation(async () => ({ data: { token_id: 3 } }))
  sanctum.user.value = null
  routeQuery.value = { identifier: 'sara@example.com', type: 'email', otp: '123456' }
  globalThis.__changePassword = ok
})

describe('/forgot-password/reset', () => {
  it('signs the customer in with the password they just chose', async () => {
    const wrapper = await mount()
    await submit(wrapper)

    expect(api.calls.map((c) => c.url)).toContain('/api/change-forgot-password')
    expect(sanctum.login).toHaveBeenCalledWith(
      expect.objectContaining({
        identifier: 'sara@example.com',
        type: 'email',
        password: 'hunter2hunter2',
      }),
    )
    expect(navigate).not.toHaveBeenCalledWith({ name: 'login', query: {} })
  })

  it('carries a claim link through the sign-in', async () => {
    routeQuery.value = { ...routeQuery.value, redirect: '/gift/abc' }
    const wrapper = await mount()
    await submit(wrapper)

    expect(navigate).toHaveBeenCalledWith('/gift/abc', { replace: true })
  })

  // As on `/login`: the page owns the destination, so a refused redirect lands home.
  it('refuses a redirect to another host', async () => {
    routeQuery.value = { ...routeQuery.value, redirect: 'https://evil.example' }
    const wrapper = await mount()
    await submit(wrapper)

    expect(navigate).toHaveBeenCalledWith('/', { replace: true })
    expect(navigate).not.toHaveBeenCalledWith(expect.stringContaining('evil.example'), expect.anything())
  })

  it('sends an expired code back for a fresh one instead of dead-ending', async () => {
    globalThis.__changePassword = otpExpired
    const wrapper = await mount()
    await submit(wrapper)

    expect(sanctum.login).not.toHaveBeenCalled()
    expect(navigate).toHaveBeenCalledWith({
      name: 'forgot-password-verify',
      query: { identifier: 'sara@example.com', type: 'email', expired: '1' },
    })
  })

  it('falls back to the sign-in screen when only the convenience sign-in fails', async () => {
    sanctum.login.mockImplementation(async () => {
      throw new Error('429')
    })
    const wrapper = await mount()
    await submit(wrapper)

    expect(navigate).toHaveBeenCalledWith({ name: 'login', query: {} })
  })

  it('does not send two passwords that differ', async () => {
    const wrapper = await mount()
    await submit(wrapper, 'hunter2hunter2', 'hunter3hunter3')

    expect(api.calls).toHaveLength(0)
    expect(wrapper.text()).toContain('The two passwords do not match.')
  })
})
