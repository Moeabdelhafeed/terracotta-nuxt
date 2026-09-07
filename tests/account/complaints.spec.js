// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const NO_HTML = 'HTML tags are not allowed here.'

const { api, lang, sanctum } = await vi.hoisted(async () => {
  const { createApiMock, envelope, apiError, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/complaints': envelope([
        { id: 7, type: 'order', message: 'Cup arrived chipped.', reference: 'ORD-102', status: 'in_progress', created_at: '2026-07-04T12:00:00+00:00', resolved_at: null },
      ]),
      'POST /api/complaints': (opts) => {
        if (/<[a-z]/i.test(String(opts.body?.message ?? ''))) return apiError(422, { message: [NO_HTML] })
        if (!['order', 'workshop', 'delivery', 'payment', 'other'].includes(opts.body?.type)) return apiError(422, { type: ['The selected type is invalid.'] })
        return envelope({ id: 8, ...opts.body, status: 'new' }, 'Your complaint has been received.')
      },
    }),
    lang: createLang('en'),
    // Starts signed in; individual tests flip `user` to exercise the guest branch.
    sanctum: createSanctumState(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)

const ComplaintsPage = (await import('~/pages/complaints.vue')).default
const { COMPLAINT_TYPES, complaintStatusLabel } = await import('~/composables/useComplaints')

const mount = () => mountSuspended(ComplaintsPage, {
  global: { stubs: { PageBar: true, AppSkeleton: true, NuxtLink: { template: '<a><slot /></a>' } } },
})

describe('/complaints', () => {
  it('offers exactly the five enum types the API accepts', async () => {
    const page = await mount()
    const values = page.find('[data-test="complaint-type"]').findAll('option').map((o) => o.attributes('value'))
    expect(values).toEqual(['order', 'workshop', 'delivery', 'payment', 'other'])
    expect(values).toEqual(COMPLAINT_TYPES)
  })

  it('hides name and contact when signed in — the account is used instead', async () => {
    const page = await mount()
    expect(page.find('[data-test="complaint-name"]').exists()).toBe(false)
    expect(page.find('[data-test="complaint-contact"]').exists()).toBe(false)
  })

  it('shows name and contact when signed out, and posts them', async () => {
    sanctum.user.value = null
    const page = await mount()
    expect(page.find('[data-test="complaint-name"]').exists()).toBe(true)
    expect(page.find('[data-test="complaint-contact"]').exists()).toBe(true)

    await page.find('[data-test="complaint-name"]').setValue('Sara')
    await page.find('[data-test="complaint-contact"]').setValue('sara@example.com')
    await page.find('[data-test="complaint-message"]').setValue('The delivery never arrived.')
    await page.find('form').trigger('submit')

    await vi.waitFor(() => {
      const post = api.calls.filter((c) => c.method === 'POST' && c.url === '/api/complaints').at(-1)
      expect(post.body).toMatchObject({ type: 'order', name: 'Sara', contact: 'sara@example.com' })
    })
    sanctum.user.value = { data: { id: 1, name: 'Test', is_guest: false } }
  })

  it("renders the server's NoHtml message under the message field", async () => {
    const page = await mount()
    await page.find('[data-test="complaint-message"]').setValue('<img src=x onerror=1>')
    await page.find('form').trigger('submit')

    await vi.waitFor(() => expect(page.find('[data-test="message-error"]').text()).toBe(NO_HTML))
  })

  it('lists the signed-in user\'s complaints with a status badge', async () => {
    const page = await mount()
    await vi.waitFor(() => expect(page.text()).toContain('Cup arrived chipped.'))
    expect(page.text()).toContain(complaintStatusLabel('in_progress', lang.t))
  })
})
