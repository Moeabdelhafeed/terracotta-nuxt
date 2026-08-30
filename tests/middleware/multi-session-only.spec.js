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

const middleware = (await import('~/middleware/multi-session-only')).default

beforeEach(() => {
  navigateTo.mockReset()
  cfgRef.value = {}
})

describe('multi-session-only', () => {
  it('multi_session=true → pass', () => {
    cfgRef.value = { multi_session: true }
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('multi_session=false → redirect /profile', () => {
    cfgRef.value = { multi_session: false }
    middleware()
    expect(navigateTo).toHaveBeenCalledWith('/profile')
  })

  it('cfg empty → pass (no redirect until cfg loads)', () => {
    cfgRef.value = {}
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })
})
