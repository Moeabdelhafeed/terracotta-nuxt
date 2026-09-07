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
