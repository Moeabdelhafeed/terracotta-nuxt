// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
import { ref } from 'vue'

const { mediaData, uploads } = vi.hoisted(() => ({
  mediaData: { value: null },
  uploads: [],
}))

mockNuxtImport('useApiFetch', () => () => ({
  data: mediaData,
  refresh: vi.fn(),
  pending: ref(false),
}))
mockNuxtImport('useApi', () => () => vi.fn(async (url, opts) => {
  uploads.push({ url, opts })
  return { success: true, data: {} }
}))

const { useMedia } = await import('~/composables/useMedia')

const withMedia = (key, entry) => {
  mediaData.value = { data: { media: { branding: entry === undefined ? {} : { [key]: entry } } } }
}

/**
 * Seeding has to key off the VALUE, not the presence of the key. A row whose file was
 * deleted in the CMS still comes back in the list — as a key with nothing under it — and
 * if that counted as "already seeded" the asset could never restore itself.
 */
describe('useMedia seeding', () => {
  beforeEach(() => {
    uploads.length = 0
    globalThis.fetch = vi.fn(async () => ({ ok: true, blob: async () => new Blob(['x'], { type: 'image/png' }) }))
  })

  it('returns the stored asset and seeds nothing when the key has a real file', () => {
    withMedia('logo_stored', { type: 'image', image: { image_api: 'https://cdn.test/logo.png' } })
    const asset = useMedia('web', 'branding').mediaAsset('logo_stored', '/logo.png')

    expect(asset).toMatchObject({ type: 'image' })
    expect(uploads).toHaveLength(0)
  })

  // A distinct key per case: the in-flight guard is module-level by design, so one key
  // seeded in an earlier case would block the next.
  it.each([
    ['the key is absent', 'k_absent', undefined],
    ['the morph is null', 'k_null', { type: 'image', image: null }],
    ['the morph is empty', 'k_empty', { type: 'image', image: {} }],
    ['the url is an empty string', 'k_blank', { type: 'image', image: { image_api: '' } }],
  ])('falls back to the local file and re-seeds when %s', async (_label, key, entry) => {
    withMedia(key, entry)
    const asset = useMedia('web', 'branding').mediaAsset(key, '/logo.png')

    expect(asset).toBe('/logo.png')
    await vi.waitFor(() => expect(uploads.length).toBeGreaterThan(0))
  })
})
