// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const { api, lang, sanctum } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  // The server keeps exactly one default at all times, so promoting one demotes the other.
  let book = [
    { id: 1, label: 'Home', is_default: true, address_line: 'A', phone: '+966500000000' },
    { id: 2, label: 'Office', is_default: false, address_line: 'B', phone: '+966500000001' },
  ]
  return {
    api: createApiMock({
      'GET /api/addresses': () => envelope(book),
      'PUT /api/addresses/{id}': (opts) => {
        book = book.map((a) => ({ ...a, is_default: a.id === opts.body.id }))
        return envelope(book.find((a) => a.is_default))
      },
      'GET /api/delivery-zones': envelope({ zones: [], default_fee: null, free_delivery_over: null }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)

const AddressesPage = (await import('~/pages/addresses.vue')).default

describe('/addresses — make default', () => {
  it('promotes a non-default address in one press, and offers the action on no other row', async () => {
    const page = await mountSuspended(AddressesPage, {
      global: { stubs: { AppSkeleton: true, AddressForm: true, NuxtLink: { template: '<a><slot /></a>' } } },
    })
    await vi.waitFor(() => expect(page.findAll('[data-test="address-card"]').length).toBe(2))

    // The row that already is the default has nothing to promote.
    expect(page.findAll('[data-test="make-default"]').length).toBe(1)

    await page.find('[data-test="make-default"]').trigger('click')
    // The badge moved rather than being duplicated — the list was refetched, not edited.
    await vi.waitFor(() => {
      expect(api.calls.some((c) => c.method === 'PUT' && c.url === '/api/addresses/2')).toBe(true)
      expect(page.findAll('[data-test="default-badge"]').length).toBe(1)
      expect(page.findAll('[data-test="address-card"]')[1].find('[data-test="default-badge"]').exists()).toBe(true)
    })
  })
})
