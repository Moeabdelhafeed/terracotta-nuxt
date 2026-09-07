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

export const fromHalalas = (cents) => {
  const sign = cents < 0 ? '-' : ''
  const abs = Math.abs(cents)
  return `${sign}${Math.floor(abs / 100)}.${String(abs % 100).padStart(2, '0')}`
}

/** `"0.00"` is settled — the create call already paid it, there is nothing to `/pay`. */
export const isZeroMoney = (value) => toHalalas(value) === 0

export const moneyEquals = (a, b) => toHalalas(a) === toHalalas(b)

/** The two identities every quote satisfies; a false answer means the client patched a total. */
export const quoteIsConsistent = (quote) => {
  if (!quote) return false
  const subtotal = toHalalas(quote.subtotal)
  const discount = toHalalas(quote.discount_amount)
  const delivery = toHalalas(quote.delivery_fee ?? 0)
  const total = toHalalas(quote.total_price)
  const wallet = toHalalas(quote.wallet_applied)
  const due = toHalalas(quote.amount_due)
  return subtotal - discount + delivery === total && total - wallet === due
}
