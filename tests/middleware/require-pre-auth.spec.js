// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const { navigateTo, sanctumState, authConfig } = vi.hoisted(() => ({
  navigateTo: vi.fn(),
  sanctumState: { user: { value: null }, isAuthenticated: { value: false } },
  authConfig: {
    appUsers: { value: true },
    appGuests: { value: true },
    cfg: { value: { app_users: true } },
    refresh: vi.fn(),
  },
}))

mockNuxtImport('navigateTo', () => navigateTo)
mockNuxtImport('useSanctumAuth', () => () => sanctumState)
mockNuxtImport('useAuthConfig', () => () => authConfig)

const middleware = (await import('~/middleware/require-pre-auth')).default

beforeEach(() => {
  navigateTo.mockReset()
  sanctumState.user.value = null
  sanctumState.isAuthenticated.value = false
  authConfig.appUsers.value = true
  authConfig.appGuests.value = true
  authConfig.cfg.value = { app_users: true }
  authConfig.refresh.mockReset()
})

describe('require-pre-auth', () => {
  it('anon → pass', async () => {
    await middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('guest → pass', async () => {
    sanctumState.user.value = { data: { is_guest: true } }
    sanctumState.isAuthenticated.value = true
    await middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('registered → redirect /', async () => {
    sanctumState.user.value = { data: { is_guest: false } }
    sanctumState.isAuthenticated.value = true
    await middleware()
    expect(navigateTo).toHaveBeenCalledWith('/')
  })

  it('no auth system (both off) → redirect /', async () => {
    authConfig.appUsers.value = false
    authConfig.appGuests.value = false
    await middleware()
    expect(navigateTo).toHaveBeenCalledWith('/')
  })
})
