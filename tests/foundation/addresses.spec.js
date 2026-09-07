// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const { api, lang, sanctum } = await vi.hoisted(async () => {
  const { createApiMock, envelope, apiError, createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    api: createApiMock({
      'GET /api/addresses': envelope([
        { id: 2, label: 'Office', is_default: false, address_line: 'B' },
        { id: 1, label: 'Home', is_default: true, address_line: 'A' },
      ]),
      'POST /api/addresses': (opts) => envelope({ id: 3, ...opts.body }),
      'DELETE /api/addresses/{id}': envelope(null),
      'POST /api/addresses/lookup': apiError(503, {}, 'Address lookup is unavailable right now.'),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)

const { validateAddress, isWithinSaudi, emptyAddressForm, useAddresses } = await import('~/composables/useAddresses')

const valid = () => ({
  ...emptyAddressForm(),
  building_number: '8228', street: 'Prince Turki', district: 'Al Muhammadiyah', postal_code: '12362',
  additional_number: '2933', phone: '+966500000000', lat: '24.7136', lng: '46.6753',
})

describe('validateAddress', () => {
  it('accepts a complete Saudi National Address', () => {
    expect(validateAddress(valid(), lang.t)).toEqual({})
  })

  it('rejects a 3-digit building number', () => {
    const errors = validateAddress({ ...valid(), building_number: '822' }, lang.t)
    expect(errors.building_number[0]).toMatch(/exactly 4 digits/)
  })

  it('rejects a 4-digit postal code and a 3-digit additional number', () => {
    const errors = validateAddress({ ...valid(), postal_code: '1236', additional_number: '293' }, lang.t)
    expect(errors.postal_code[0]).toMatch(/5 digits/)
    expect(errors.additional_number[0]).toMatch(/4 digits/)
  })

  it('rejects a malformed short address but accepts AAAA9999', () => {
    expect(validateAddress({ ...valid(), short_address: 'RRRD29' }, lang.t).short_address).toBeDefined()
    expect(validateAddress({ ...valid(), short_address: 'rrrd2929' }, lang.t)).toEqual({})
  })

  it('rejects a pin outside Saudi Arabia (Dubai, Cairo) and requires one', () => {
    expect(validateAddress({ ...valid(), lat: '25.2048', lng: '55.2708' }, lang.t).lat[0]).toMatch(/inside Saudi Arabia/)
    expect(validateAddress({ ...valid(), lat: '30.0444', lng: '31.2357' }, lang.t).lat[0]).toMatch(/inside Saudi Arabia/)
    expect(validateAddress({ ...valid(), lat: '', lng: '' }, lang.t).lat[0]).toMatch(/pin/)
    expect(isWithinSaudi(24.7, 46.6)).toBe(true)
  })
})

describe('useAddresses', () => {
  it('lists the default first and refetches after a save', async () => {
    const { addresses, defaultAddress, save } = useAddresses()
    await vi.waitFor(() => expect(addresses.value.length).toBe(2))
    expect(defaultAddress.value.id).toBe(1)

    const before = api.calls.filter((c) => c.method === 'GET').length
    const saved = await save({ ...valid(), short_address: 'rrrd2929' })
    expect(saved.short_address).toBe('RRRD2929')
    expect(api.calls.filter((c) => c.method === 'GET').length).toBe(before + 1)
  })

  it('flags a 503 lookup as the feature being off', async () => {
    const { lookup } = useAddresses()
    await expect(lookup('RRRD2929')).rejects.toMatchObject({ status: 503, unavailable: true })
  })
})
