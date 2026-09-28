import { describe, it, expect } from 'vitest'
import { isStaleTranslation } from '../../app/composables/useLang'

/**
 * A stored translation is seeded once and never rewritten, so a placeholder the code later
 * renamed stays behind in the row — the booking page printed "والمتبقي على موعدها :n أيام".
 * The first case is the real row from the database.
 */
describe('isStaleTranslation', () => {
  it('flags a stored row whose placeholder the code no longer fills', () => {
    expect(isStaleTranslation(
      'يرجى مسح الرمز عند الوصول إلى موقع الورشة، والمتبقي على موعدها :n أيام.',
      'يرجى مسح الرمز عند الوصول إلى موقع الورشة، والمتبقي على موعدها :remaining.',
    )).toBe(true)
  })

  it('keeps an admin\'s own wording that uses the same placeholders', () => {
    expect(isStaleTranslation('اعرض الرمز — تبقّى :remaining.', 'default :remaining')).toBe(false)
  })

  it('keeps wording that dropped a placeholder on purpose', () => {
    expect(isStaleTranslation('نص بلا متغيرات', 'تبقّى :remaining')).toBe(false)
  })

  it('does not read times or links as placeholders', () => {
    expect(isStaleTranslation('Opens at 10:00 — see https://terracotta-ksa.com', 'Opens soon')).toBe(false)
  })

  it('trusts the stored row when the code gave no default', () => {
    expect(isStaleTranslation('Hello :name', undefined)).toBe(false)
  })
})
