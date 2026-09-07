import { describe, it, expect } from 'vitest'
import { toHalalas, isZeroMoney } from '~/composables/useMoney'

describe('useMoney', () => {
  it('reads decimal strings exactly', () => {
    expect(toHalalas('145.00')).toBe(14500)
    expect(toHalalas('0.10')).toBe(10)
    expect(toHalalas('19.9')).toBe(1990)
    expect(toHalalas(65)).toBe(6500)
    expect(toHalalas(null)).toBe(0)
  })

  it('treats "0.00" as settled', () => {
    expect(isZeroMoney('0.00')).toBe(true)
    expect(isZeroMoney('0')).toBe(true)
    expect(isZeroMoney(null)).toBe(true)
    expect(isZeroMoney('0.01')).toBe(false)
    expect(isZeroMoney('145.00')).toBe(false)
  })
})
