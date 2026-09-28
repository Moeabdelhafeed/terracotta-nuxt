// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const lang = await vi.hoisted(async () => (await import('../helpers/mockApi')).createLang('ar'))
mockNuxtImport('useLang', () => () => lang)

/**
 * QA WEB-02: the confirmation screen said "حتى 1 ساعات قبل موعد الجلسة" — one template for
 * every count. Arabic inflects for one, two, 3–10 and 11+.
 */
describe('useDuration — Arabic', () => {
  it('inflects hours and minutes for every count', () => {
    const { remaining } = useDuration()

    expect(remaining(1)).toBe('دقيقة واحدة')
    expect(remaining(2)).toBe('دقيقتان')
    expect(remaining(60)).toBe('ساعة واحدة')
    expect(remaining(80)).toBe('ساعة واحدة و20 دقيقة')
    expect(remaining(135)).toBe('ساعتان و15 دقيقة')
    expect(remaining(5 * 60 + 3)).toBe('5 ساعات و3 دقائق')
  })

  it('switches to days and hours past a day', () => {
    const { remaining } = useDuration()

    expect(remaining(27 * 60)).toBe('يوم واحد و3 ساعات')
    expect(remaining(48 * 60)).toBe('يومان')
  })

  it('inflects a head count — never "1 أشخاص"', () => {
    const { counted } = useDuration()

    expect(counted(1, 'person')).toBe('شخص واحد')
    expect(counted(2, 'person')).toBe('شخصان')
    expect(counted(4, 'person')).toBe('4 أشخاص')
    expect(counted(12, 'person')).toBe('12 شخصًا')
  })
})
