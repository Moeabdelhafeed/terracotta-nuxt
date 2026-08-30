// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const { navigateTo, cfgRef, refresh } = vi.hoisted(() => ({
  navigateTo: vi.fn(),
  cfgRef: { value: {} },
  refresh: vi.fn(),
}))

mockNuxtImport('navigateTo', () => navigateTo)
mockNuxtImport('useAuthConfig', () => () => ({ cfg: cfgRef, refresh }))

const middleware = (await import('~/middleware/auth-mode')).default

beforeEach(() => {
  navigateTo.mockReset()
  refresh.mockReset()
  cfgRef.value = {}
})

describe('auth-mode', () => {
  it('app_users=true → pass', async () => {
    cfgRef.value = { app_users: true }
    await middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('app_users=false → redirect /', async () => {
    cfgRef.value = { app_users: false }
    await middleware()
    expect(navigateTo).toHaveBeenCalledWith('/')
  })

  it('cfg empty → calls refresh', async () => {
    cfgRef.value = {}
    refresh.mockImplementation(() => {
      cfgRef.value = { app_users: true }
    })
    await middleware()
    expect(refresh).toHaveBeenCalled()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('cfg empty + refresh fills app_users=false → redirect /', async () => {
    cfgRef.value = {}
    refresh.mockImplementation(() => {
      cfgRef.value = { app_users: false }
    })
    await middleware()
    expect(navigateTo).toHaveBeenCalledWith('/')
  })
})
