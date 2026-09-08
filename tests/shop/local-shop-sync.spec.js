// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { nextTick } from 'vue'

const { api, lang, toast, registered, cartIds, favoriteIds, push } = await vi.hoisted(async () => {
  const { vi: v } = await import('vitest')
  const { ref } = await import('vue')
  const { createApiMock, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({}),
    lang: createLang('en'),
    toast: { success: v.fn(), error: v.fn(), info: v.fn() },
    registered: ref(false),
    cartIds: ref([]),
    favoriteIds: ref([]),
    push: v.fn(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useToast', () => () => toast)
mockNuxtImport('useIsRegistered', () => () => ({ isRegistered: registered }))
mockNuxtImport('localCartIds', () => cartIds)
mockNuxtImport('localFavoriteIds', () => favoriteIds)
mockNuxtImport('pushLocalShopToServer', () => push)

// The test environment boots the app, which installs the client plugin — so the watcher
// under test is the real one, driven by the mocked session and storage refs.
const { shouldPushLocalShop } = await import('~/plugins/05.local-shop-sync.client')

const settle = async () => { await nextTick(); await flushPromises() }

beforeEach(async () => {
  registered.value = false
  cartIds.value = []
  favoriteIds.value = []
  await settle()
  push.mockReset()
  push.mockImplementation(async () => ({ pushedLines: 0, pushedFavorites: 0, dropped: 0 }))
  toast.info.mockClear()
})

describe('shouldPushLocalShop', () => {
  it('needs a registered account and something to hand over', () => {
    expect(shouldPushLocalShop(false, [{ id: 1, quantity: 1 }], [])).toBe(false)
    expect(shouldPushLocalShop(true, [], [])).toBe(false)
    expect(shouldPushLocalShop(true, [{ id: 1, quantity: 1 }], [])).toBe(true)
    expect(shouldPushLocalShop(true, [], [7])).toBe(true)
  })
})

describe('local shop sync', () => {
  it('hands the basket over the moment the visitor becomes registered', async () => {
    cartIds.value = [{ id: 11, quantity: 2 }]
    await settle()
    expect(push).not.toHaveBeenCalled()

    registered.value = true
    await settle()

    expect(push).toHaveBeenCalledTimes(1)
    expect(push).toHaveBeenCalledWith(api.$fetch)
  })

  it('pushes hearts on their own too', async () => {
    favoriteIds.value = [7]
    registered.value = true
    await settle()

    expect(push).toHaveBeenCalledTimes(1)
  })

  it('stays quiet when there is nothing stored', async () => {
    registered.value = true
    await settle()

    expect(push).not.toHaveBeenCalled()
  })

  it('pushes once, even while storage keeps changing under it', async () => {
    let finish
    push.mockImplementationOnce(() => new Promise((resolve) => { finish = resolve }))
    cartIds.value = [{ id: 11, quantity: 2 }]
    registered.value = true
    await settle()
    expect(push).toHaveBeenCalledTimes(1)

    favoriteIds.value = [7]
    await settle()
    expect(push).toHaveBeenCalledTimes(1)

    finish({ pushedLines: 1, pushedFavorites: 0, dropped: 0 })
    await settle()
    expect(push).toHaveBeenCalledTimes(1)
  })

  it('says so when pieces were dropped on the way', async () => {
    push.mockImplementation(async () => ({ pushedLines: 1, pushedFavorites: 0, dropped: 2 }))
    cartIds.value = [{ id: 11, quantity: 2 }, { id: 12, quantity: 1 }, { id: 13, quantity: 1 }]
    registered.value = true
    await settle()

    expect(toast.info).toHaveBeenCalledWith('2 item(s) in your basket are no longer available and were removed.')
  })

  it('keeps quiet when nothing was dropped', async () => {
    cartIds.value = [{ id: 11, quantity: 2 }]
    registered.value = true
    await settle()

    expect(push).toHaveBeenCalledTimes(1)
    expect(toast.info).not.toHaveBeenCalled()
  })

  it('leaves the basket alone when the push fails, so a later change retries', async () => {
    push.mockImplementationOnce(async () => { throw new Error('offline') })
    cartIds.value = [{ id: 11, quantity: 2 }]
    registered.value = true
    await settle()
    expect(push).toHaveBeenCalledTimes(1)
    expect(cartIds.value).toHaveLength(1)

    favoriteIds.value = [7]
    await settle()
    expect(push).toHaveBeenCalledTimes(2)
  })
})
