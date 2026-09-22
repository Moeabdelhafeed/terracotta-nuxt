/**
 * Money arrives as decimal strings ("145.00") and must stay exact — never `parseFloat`
 * two of them and compare. These helpers work in integer halalas.
 */
export const toHalalas = (value) => {
  const str = String(value ?? '0').trim()
  if (!/^-?\d+(\.\d{1,2})?$/.test(str)) return Math.round(Number(str || 0) * 100) || 0
  const [whole, frac = ''] = str.replace('-', '').split('.')
  const cents = Number(whole) * 100 + Number((frac + '00').slice(0, 2))
  return str.startsWith('-') ? -cents : cents
}

/** `"0.00"` is settled — the create call already paid it, there is nothing to `/pay`. */
export const isZeroMoney = (value) => toHalalas(value) === 0

/** Back to the wire format: `12345` → `"123.45"`. */
export const fromHalalas = (cents) => {
  const rounded = Math.round(cents)
  const abs = Math.abs(rounded)
  return `${rounded < 0 ? '-' : ''}${Math.floor(abs / 100)}.${String(abs % 100).padStart(2, '0')}`
}

/**
 * The digits as they arrived, never parsed: `"60.00"` → `"60"`, `"99.99"` → `"99.99"`.
 * `Number()` on a money string is how totals come out a halala wrong on some amounts.
 */
export const displayMoney = (value) => {
  const decimal = fromHalalas(toHalalas(value))
  return decimal.endsWith('.00') ? decimal.slice(0, -3) : decimal
}

/**
 * Arabic reads Arabic-Indic digits — «٤ صور», not "4 صور". Dates elsewhere on the site
 * deliberately force Latin digits (`nu-latn`); counts and money on a customer's own
 * pages follow the locale, which is what the app does.
 */
const ARABIC_DIGITS = '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669'

export const localeDigits = (value, code = 'en') =>
  code === 'ar'
    // A character map, not Intl: `format()` would take the number through a float, which
    // is the one thing a money string must never do.
    ? String(value).replace(/\d/g, (digit) => ARABIC_DIGITS[Number(digit)])
    : String(value)
