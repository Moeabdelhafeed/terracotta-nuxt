// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'
import { imagePdf } from '../../app/utils/imagePdf.js'

const TOKEN = '18d08cb9-0843-4865-9c40-11a470b183db'

const { lang, sanctum, giftRef, save } = await vi.hoisted(async () => {
  const { ref } = await import('vue')
  const { vi: v } = await import('vitest')
  const { createLang, createSanctumState } = await import('../helpers/mockApi')
  return {
    lang: createLang('en'),
    sanctum: createSanctumState({ id: 7, name: 'Sara', is_guest: false }),
    giftRef: ref(null),
    save: v.fn(async () => {}),
  }
})

mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('usePrice', () => () => ({ format: (v) => `${v} SAR`, currency: 'SAR' }))
mockNuxtImport('useSanctumAuth', () => () => sanctum)
mockNuxtImport('useRoute', () => () => ({ params: { token: TOKEN }, query: {} }))
mockNuxtImport('useGSAP', () => () => ({ matchMedia: () => ({ add: () => {}, revert: () => {} }), from: () => {} }))
mockNuxtImport('saveGiftPdf', () => save)
mockNuxtImport('useFetch', () => () => ({ data: giftRef, error: ref(null), refresh: vi.fn(), pending: ref(false), status: ref('success') }))

const GiftLanding = (await import('~/pages/gift/[token].vue')).default

describe('/gift/[token] — save as PDF', () => {
  const gift = (over = {}) => ({
    token: TOKEN,
    recipient_name: 'Sara',
    message: 'Happy birthday!',
    amount: '200.00',
    from: 'Nour',
    is_claimable: true,
    deep_link: `terracotta://gift/${TOKEN}`,
    store_links: [
      { type: 'app_store', url: 'https://apps.apple.com/app/id1' },
      { type: 'google_play', url: 'https://play.google.com/store/apps/details?id=x' },
    ],
    ...over,
  })

  const savedPage = async () => {
    save.mockClear()
    const wrapper = await mountSuspended(GiftLanding, { global: { stubs: { AppCurtain: true, AppConfetti: true } } })
    await wrapper.find('[data-test="gift-save-pdf"]').trigger('click')
    await flushPromises()
    expect(save).toHaveBeenCalledOnce()
    return save.mock.calls[0]
  }

  it('hands the PDF the page as shown: its words, a Claim button to this gift and the store buttons', async () => {
    giftRef.value = gift()
    const [page, options] = await savedPage()

    expect(page).toMatchObject({
      from: 'Nour sent you a gift',
      amount: '200.00 SAR',
      message: 'Happy birthday!',
      to: 'For Sara',
      claim: { label: 'Claim your gift', url: `${window.location.origin}/gift/${TOKEN}` },
      stores: {
        heading: 'Do not have the app yet?',
        items: [
          { label: 'App Store', url: 'https://apps.apple.com/app/id1' },
          { label: 'Google Play', url: 'https://play.google.com/store/apps/details?id=x' },
        ],
      },
      claimed: null,
      explore: { url: `${window.location.origin}/` },
    })
    expect(options).toMatchObject({ dir: 'ltr', fileName: 'terracotta-gift.pdf' })
  })

  it('shows a claimed gift as claimed, with nothing to press', async () => {
    giftRef.value = gift({ is_claimable: false, is_redeemed: true })
    const [page] = await savedPage()

    expect(page.claim).toBeNull()
    expect(page.stores).toBeNull()
    expect(page.claimed).toBe('This gift has already been claimed.')
  })
})

describe('imagePdf', () => {
  it('writes a one-page PDF whose cross-reference table points at every object', () => {
    const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 0xff, 0xd9])
    const pdf = imagePdf(jpeg, 1240, 1754, 420, 595)
    const text = new TextDecoder('latin1').decode(pdf)

    expect(text.startsWith('%PDF-1.4\n')).toBe(true)
    expect(text.trimEnd().endsWith('%%EOF')).toBe(true)
    expect(text).toContain('/MediaBox [0 0 420 595]')
    expect(text).toContain('/Width 1240 /Height 1754')

    // startxref names the byte where the table starts, and each entry the byte where
    // its object starts — the two things a reader trusts blindly.
    const xref = Number(text.match(/startxref\n(\d+)/)[1])
    expect(text.slice(xref, xref + 4)).toBe('xref')
    const entries = text.slice(xref).match(/^\d{10} 00000 n $/gm)
    expect(entries).toHaveLength(5)
    entries.forEach((entry, index) => {
      const offset = Number(entry.slice(0, 10))
      expect(text.slice(offset, offset + `${index + 1} 0 obj`.length)).toBe(`${index + 1} 0 obj`)
    })

    expect(text).not.toContain('/Annots') // no links asked for, none written

    // The JPEG goes in byte for byte.
    const start = pdf.findIndex((byte, i) => byte === 0xff && pdf[i + 1] === 0xd8)
    expect(Array.from(pdf.slice(start, start + jpeg.length))).toEqual(Array.from(jpeg))
  })

  it('turns each link rectangle into a clickable area, measured from the bottom-left in points', () => {
    const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xd9])
    // A 1000 × 2000 picture on a 500 × 1000 point page: half scale.
    const pdf = imagePdf(jpeg, 1000, 2000, 500, 1000, [
      { x: 100, y: 200, width: 400, height: 100, url: 'https://terracotta-ksa.com/gift/abc' },
      { x: 0, y: 0, width: 10, height: 10, url: 'https://example.com/a(b)' },
      { x: 0, y: 0, width: 10, height: 10, url: '' }, // no address, no link
    ])
    const text = new TextDecoder('latin1').decode(pdf)

    expect(text).toContain('/Annots [6 0 R 7 0 R]')
    expect(text).toContain('/Rect [50 850 250 900]') // y 200–300 px from the top = 850–900 pt from the bottom
    expect(text).toContain('/URI (https://terracotta-ksa.com/gift/abc)')
    expect(text).toContain('/URI (https://example.com/a\\(b\\))') // brackets escaped inside a PDF string

    const xref = Number(text.match(/startxref\n(\d+)/)[1])
    const entries = text.slice(xref).match(/^\d{10} 00000 n $/gm)
    expect(entries).toHaveLength(7)
    entries.forEach((entry, index) => {
      const offset = Number(entry.slice(0, 10))
      expect(text.slice(offset, offset + `${index + 1} 0 obj`.length)).toBe(`${index + 1} 0 obj`)
    })
  })
})
