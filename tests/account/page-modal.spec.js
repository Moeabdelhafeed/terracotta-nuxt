// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const { api, lang } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/pages/terms': envelope({ id: 1, slug: 'terms', name: 'Terms & Conditions', content: '<p>Sessions are non-refundable within 24 hours.</p>', image: null }),
      'GET /api/pages/privacy': envelope({ id: 2, slug: 'privacy', name: 'Privacy Policy', content: '<p>We keep your number to text you about your booking.</p>', image: null }),
    }),
    lang: createLang('en'),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)

const PageModal = (await import('~/components/account/PageModal.vue')).default

describe('auth document modal', () => {
  // The panel is `<Teleport to="body">`, so it lands outside the mounted wrapper.
  const panel = () => document.querySelector('[data-test="page-content"]')

  it('fetches the terms from the CMS instead of bundling them', async () => {
    document.body.innerHTML = ''
    await mountSuspended(PageModal, { props: { slug: 'terms' }, global: { stubs: { AppSkeleton: true } } })

    await vi.waitFor(() => expect(api.calls.some((c) => c.url === '/api/pages/terms')).toBe(true))
    await vi.waitFor(() => expect(panel()?.innerHTML).toContain('non-refundable'))
    expect(document.body.textContent).toContain('Terms & Conditions')
  })

  // The privacy policy reaches the reader the same way the terms do — same dialog, same
  // endpoint, a different slug — rather than as a second tab away from the form.
  it('fetches whichever document it is given', async () => {
    document.body.innerHTML = ''
    await mountSuspended(PageModal, { props: { slug: 'privacy' }, global: { stubs: { AppSkeleton: true } } })

    await vi.waitFor(() => expect(api.calls.some((c) => c.url === '/api/pages/privacy')).toBe(true))
    await vi.waitFor(() => expect(panel()?.innerHTML).toContain('text you about your booking'))
    expect(document.body.textContent).toContain('Privacy Policy')
  })
})
