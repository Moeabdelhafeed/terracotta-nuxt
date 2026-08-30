// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const { navigateTo, cfgRef } = vi.hoisted(() => ({
  navigateTo: vi.fn(),
  cfgRef: { value: {} },
}))

mockNuxtImport('navigateTo', () => navigateTo)
mockNuxtImport('useAuthConfig', () => () => ({ cfg: cfgRef }))

const middleware = (await import('~/middleware/password-mode-only')).default

beforeEach(() => {
  navigateTo.mockReset()
  cfgRef.value = {}
})

describe('password-mode-only', () => {
  it('auth_mode=password → pass', () => {
    cfgRef.value = { auth_mode: 'password' }
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('auth_mode=otp → redirect /login', () => {
    cfgRef.value = { auth_mode: 'otp' }
    middleware()
    expect(navigateTo).toHaveBeenCalledWith({ name: 'login' })
  })

  it('cfg empty → pass (defensive)', () => {
    cfgRef.value = {}
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('auth_mode missing → pass', () => {
    cfgRef.value = { app_users: true }
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })
})
