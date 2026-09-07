import { describe, it, expect } from 'vitest'
import { toHalalas, fromHalalas, isZeroMoney, moneyEquals, quoteIsConsistent } from '~/composables/useMoney'

describe('useMoney', () => {
  it('reads decimal strings exactly', () => {
    expect(toHalalas('145.00')).toBe(14500)
    expect(toHalalas('0.10')).toBe(10)
    expect(toHalalas('19.9')).toBe(1990)
    expect(toHalalas(65)).toBe(6500)
    expect(toHalalas(null)).toBe(0)
  })

  it('round-trips', () => {
    expect(fromHalalas(14500)).toBe('145.00')
    expect(fromHalalas(5)).toBe('0.05')
    expect(fromHalalas(-250)).toBe('-2.50')
  })

  it('treats "0.00" as settled', () => {
    expect(isZeroMoney('0.00')).toBe(true)
    expect(isZeroMoney('0')).toBe(true)
    expect(isZeroMoney('0.01')).toBe(false)
    expect(moneyEquals('50', '50.00')).toBe(true)
  })

  it('checks the two quote identities', () => {
    expect(quoteIsConsistent({ subtotal: '200.00', discount_amount: '20.00', delivery_fee: '15.00', total_price: '195.00', wallet_applied: '50.00', amount_due: '145.00' })).toBe(true)
    // Workshop quotes carry delivery_fee null.
    expect(quoteIsConsistent({ subtotal: '95.00', discount_amount: '0.00', delivery_fee: null, total_price: '95.00', wallet_applied: '60.00', amount_due: '35.00' })).toBe(true)
    // A discount that "reduced" the delivery fee would break the identity.
    expect(quoteIsConsistent({ subtotal: '100.00', discount_amount: '50.00', delivery_fee: '20.00', total_price: '60.00', wallet_applied: '0.00', amount_due: '60.00' })).toBe(false)
  })
})
