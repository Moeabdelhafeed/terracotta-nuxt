// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const lang = await vi.hoisted(async () => (await import('../helpers/mockApi')).createLang('en'))
mockNuxtImport('useLang', () => () => lang)

const AppGallery = (await import('~/components/AppGallery.vue')).default

const shot = (n) => ({ id: n, image_api: `https://example.test/${n}.webp` })

const mount = (items) => mountSuspended(AppGallery, { props: { items, alt: 'A cup' } })
const shown = (wrapper) => wrapper.find('img').attributes('src')

describe('AppGallery', () => {
  it('walks the set with the arrows, wrapping at both ends', async () => {
    const wrapper = await mount([shot(1), shot(2), shot(3)])
    expect(shown(wrapper)).toBe('https://example.test/1.webp')

    await wrapper.find('[data-test="shot-next"]').trigger('click')
    expect(shown(wrapper)).toBe('https://example.test/2.webp')

    await wrapper.find('[data-test="shot-prev"]').trigger('click')
    await wrapper.find('[data-test="shot-prev"]').trigger('click')
    expect(shown(wrapper)).toBe('https://example.test/3.webp')
  })

  it('jumps straight to a photograph from its mark, and says which is showing', async () => {
    const wrapper = await mount([shot(1), shot(2), shot(3)])

    await wrapper.find('[data-shot="2"]').trigger('click')
    expect(shown(wrapper)).toBe('https://example.test/3.webp')
    expect(wrapper.find('[data-shot="2"]').attributes('aria-current')).toBe('true')
    expect(wrapper.find('[data-shot="0"]').attributes('aria-current')).toBeUndefined()
  })

  it('draws no controls over a single photograph', async () => {
    const wrapper = await mount([shot(1)])

    expect(wrapper.find('[data-test="shot-next"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="shot-indicator"]').exists()).toBe(false)
  })

  /**
   * Without this the next photograph only starts downloading when it is asked for, so the
   * one on screen stays put while it arrives and the arrow reads as dead.
   */
  it('fetches every photograph up front, not just the one on screen', async () => {
    const requested = []
    const original = globalThis.Image
    globalThis.Image = class {
      set src(value) { requested.push(value) }
    }

    try {
      await mount([shot(1), shot(2), shot(3)])
      expect(requested).toEqual([
        'https://example.test/1.webp',
        'https://example.test/2.webp',
        'https://example.test/3.webp',
      ])
    } finally {
      globalThis.Image = original
    }
  })
})
