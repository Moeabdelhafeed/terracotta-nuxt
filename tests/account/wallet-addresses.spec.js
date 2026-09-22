// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { CalendarDays, Gift, ShoppingBag, Wallet } from 'lucide-vue-next'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

const { api, lang, sanctum } = await vi.hoisted(async () => {
  const { createApiMock, envelope, createLang, createSanctumState } = await import('../helpers/mockApi')
  // The server keeps exactly one default: deleting it promotes the newest remaining.
  let book = [
    { id: 1, label: 'Home', is_default: true, address_line: 'A', phone: '+966500000000' },
    { id: 2, label: 'Office', is_default: false, address_line: 'B', phone: '+966500000001' },
  ]
  return {
    api: createApiMock({
      'GET /api/addresses': () => envelope(book),
      // The mock table matches on path only, so this drops whichever row is the default —
      // which is exactly the row the page's first delete button belongs to.
      'DELETE /api/addresses/{id}': () => {
        book = book.filter((a) => !a.is_default)
        if (book.length) book[0] = { ...book[0], is_default: true }
        return envelope(null)
      },
      'GET /api/delivery-zones': envelope({ zones: [], default_fee: null, free_delivery_over: null }),
      'GET /api/wallet/transactions': envelope({
        balance: '30.00',
        transactions: [
          { id: 3, type: 'debit', amount: '20.00', reason: 'booking_payment', balance_after: '30.00', created_at: '2026-07-04T13:05:00+00:00' },
          { id: 2, type: 'credit', amount: '50.00', reason: 'admin_adjustment', balance_after: '50.00', created_at: '2026-07-04T13:00:00+00:00' },
          { id: 1, type: 'credit', amount: '5.00', reason: 'moon_phase_bonus', balance_after: '5.00', created_at: '2026-07-04T12:00:00+00:00' },
        ],
      }),
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)

const { walletReasonLabel, walletReasonIcon, useWallet } = await import('~/composables/useWallet')
const { useAddresses } = await import('~/composables/useAddresses')
const AddressesPage = (await import('~/pages/addresses.vue')).default

describe('wallet ledger reasons', () => {
  it('translates every reason on the contract sheet', () => {
    const reasons = ['booking_payment', 'booking_cancelled', 'booking_rescheduled', 'booking_absent',
      'booking_partial_no_show', 'delivery_fee', 'shop_order_payment', 'shop_order_cancelled',
      'gift_purchase', 'gift_redeemed', 'admin_adjustment']
    reasons.forEach((reason) => {
      const label = walletReasonLabel(reason, lang.t)
      expect(label).not.toBe(reason)
      expect(label).not.toMatch(/_/)
    })
  })

  it('falls back to a readable string for a reason the backend adds later', () => {
    expect(walletReasonLabel('moon_phase_bonus', lang.t)).toBe('moon phase bonus')
    expect(walletReasonIcon('moon_phase_bonus')).toBe(Wallet)
  })

  /**
   * The COMPONENT, not its name. `nuxt-lucide-icons` resolves an icon by rewriting its
   * name where it appears literally in a template; a name held in a variable is never
   * rewritten, so `<component :is="'LucideWallet'">` rendered an empty
   * `<lucidewallet></lucidewallet>` element and the ledger showed no icons at all.
   */
  it('gives each reason group its own icon', () => {
    expect(walletReasonIcon('booking_payment')).toBe(CalendarDays)
    expect(walletReasonIcon('shop_order_payment')).toBe(ShoppingBag)
    expect(walletReasonIcon('gift_redeemed')).toBe(Gift)
  })

  it('reads the balance as a decimal string and keeps balance_after per row', async () => {
    const { balance, transactions } = useWallet()
    await vi.waitFor(() => expect(transactions.value.length).toBe(3))
    expect(balance.value).toBe('30.00')
    expect(transactions.value[0].balance_after).toBe('30.00')
  })
})

describe('/addresses', () => {
  it('lists the default first', async () => {
    const { addresses, defaultAddress } = useAddresses()
    await vi.waitFor(() => expect(addresses.value.length).toBe(2))
    expect(defaultAddress.value.id).toBe(1)
  })

  it('refetches after a delete, so the promoted default is the one shown', async () => {
    const page = await mountSuspended(AddressesPage, {
      global: { stubs: { AppSkeleton: true, AddressForm: true, NuxtLink: { template: '<a><slot /></a>' } } },
    })
    await vi.waitFor(() => expect(page.findAll('[data-test="address-card"]').length).toBe(2))

    await page.findAll('[data-test="delete-address"]')[0].trigger('click')
    // The confirm dialog is `<Teleport to="body">`, so it lives outside the wrapper.
    await vi.waitFor(() => expect(document.querySelector('[data-test="confirm-delete"]')).not.toBeNull())
    document.querySelector('[data-test="confirm-delete"]').click()

    await vi.waitFor(() => {
      expect(api.calls.some((c) => c.method === 'DELETE' && c.url === '/api/addresses/1')).toBe(true)
      expect(page.findAll('[data-test="address-card"]').length).toBe(1)
    })
    expect(page.find('[data-test="default-badge"]').exists()).toBe(true)
    expect(page.text()).toContain('Office')
  })
})
