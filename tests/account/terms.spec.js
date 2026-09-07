// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const { api, lang } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/pages/terms': envelope({ id: 1, slug: 'terms', name: 'Terms & Conditions', content: '<p>Sessions are non-refundable within 24 hours.</p>', image: null }),
    }),
    lang: createLang('en'),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)

const TermsModal = (await import('~/components/account/TermsModal.vue')).default

describe('terms modal', () => {
  // The panel is `<Teleport to="body">`, so it lands outside the mounted wrapper.
  const panel = () => document.querySelector('[data-test="terms-content"]')

  it('fetches the terms from the CMS instead of bundling them', async () => {
    await mountSuspended(TermsModal, { props: { open: true }, global: { stubs: { AppSkeleton: true } } })

    await vi.waitFor(() => expect(api.calls.some((c) => c.url === '/api/pages/terms')).toBe(true))
    await vi.waitFor(() => expect(panel()?.innerHTML).toContain('non-refundable'))
    expect(document.body.textContent).toContain('Terms & Conditions')
  })

  it('renders nothing while closed', async () => {
    document.body.innerHTML = ''
    await mountSuspended(TermsModal, { props: { open: false }, global: { stubs: { AppSkeleton: true } } })
    expect(panel()).toBeNull()
  })
})
