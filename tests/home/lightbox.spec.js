// @vitest-environment nuxt
import { describe, it, expect, vi, afterEach } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const { lang } = await vi.hoisted(async () => {
  const { createLang } = await import('../helpers/mockApi')
  return { lang: createLang('en') }
})

mockNuxtImport('useLang', () => () => lang)

const AppLightbox = (await import('~/components/AppLightbox.vue')).default

const ITEMS = [
  { id: 1, type: 'image', image: { image_api: 'https://cdn.test/a.webp' } },
  { id: 2, type: 'image', image: { image_api: 'https://cdn.test/b.webp' } },
  { id: 3, type: 'video', video: { video_api: 'https://cdn.test/c.mp4', thumbnail: null } },
]

// Teleported panels stack up in `document.body` across mounts, so each test gets a
// clean one or it would be pressing the previous test's buttons.
const mounted = []
const mount = async (modelValue) => {
  const wrapper = await mountSuspended(AppLightbox, { props: { modelValue, items: ITEMS, alt: 'Album' } })
  mounted.push(wrapper)
  return wrapper
}
const panel = (selector) => document.querySelector(`[data-test="lightbox"] ${selector}`)

afterEach(() => {
  mounted.splice(0).forEach((wrapper) => wrapper.unmount())
  document.body.innerHTML = ''
})

describe('AppLightbox', () => {
  it('stays shut while the model is null', async () => {
    await mount(null)
    expect(document.querySelector('[data-test="lightbox"]')).toBeNull()
  })

  it('opens on the item that was tapped and counts the run', async () => {
    await mount(1)
    expect(panel('[data-test="lightbox-counter"]').textContent.trim()).toBe('2 / 3')
    expect(panel('img').getAttribute('src')).toBe('https://cdn.test/b.webp')
  })

  it('wraps at both ends rather than dead-ending on the last photograph', async () => {
    const wrapper = await mount(2)
    panel('[data-test="lightbox-next"]').click()
    expect(wrapper.emitted('update:modelValue').at(-1)).toEqual([0])
  })

  it('wraps backwards off the first photograph', async () => {
    const wrapper = await mount(0)
    panel('[data-test="lightbox-prev"]').click()
    expect(wrapper.emitted('update:modelValue').at(-1)).toEqual([2])
  })

  it('closes on the close button', async () => {
    const wrapper = await mount(0)
    panel('[data-test="lightbox-close"]').click()
    expect(wrapper.emitted('update:modelValue').at(-1)).toEqual([null])
  })

  it('plays a video item in place instead of showing a still', async () => {
    await mount(2)
    expect(panel('video')).not.toBeNull()
  })
})
