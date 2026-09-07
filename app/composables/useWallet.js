/**
 * Store-credit wallet: `GET /api/wallet/transactions` (paginated, newest first). The
 * balance rides on every page of the ledger; `balance_after` is the running balance so
 * a statement never re-sums. Money stays a decimal string end to end.
 */

/** Every `reason` the ledger can carry, grouped by what the row is about. */
export const WALLET_REASON_GROUPS = {
  booking: ['booking_payment', 'booking_cancelled', 'booking_rescheduled', 'booking_absent', 'booking_partial_no_show', 'delivery_fee'],
  shop: ['shop_order_payment', 'shop_order_cancelled'],
  gift: ['gift_purchase', 'gift_redeemed'],
  admin: ['admin_adjustment'],
}

const REASON_ICONS = { booking: 'LucideCalendarDays', shop: 'LucideShoppingBag', gift: 'LucideGift', admin: 'LucideSlidersHorizontal' }

export const walletReasonGroup = (reason) =>
  Object.keys(WALLET_REASON_GROUPS).find((group) => WALLET_REASON_GROUPS[group].includes(reason)) ?? null

/** Auto-imported Lucide component name for a reason; a wallet icon for anything unknown. */
export const walletReasonIcon = (reason) => REASON_ICONS[walletReasonGroup(reason)] ?? 'LucideWallet'

export const walletReasonLabel = (reason, t) => {
  const known = {
    booking_payment: t('reason_booking_payment', 'Workshop booking', 'دفع حجز ورشة'),
    booking_cancelled: t('reason_booking_cancelled', 'Booking cancelled — refund', 'إلغاء حجز — استرداد'),
    booking_rescheduled: t('reason_booking_rescheduled', 'Booking rescheduled — refund', 'تغيير موعد حجز — استرداد'),
    booking_absent: t('reason_booking_absent', 'Absence credit', 'رصيد تعويض غياب'),
    booking_partial_no_show: t('reason_booking_partial_no_show', 'Partial no-show credit', 'رصيد تعويض حضور جزئي'),
    delivery_fee: t('reason_delivery_fee', 'Piece delivery fee', 'رسوم توصيل القطعة'),
    shop_order_payment: t('reason_shop_order_payment', 'Shop order', 'دفع طلب من المتجر'),
    shop_order_cancelled: t('reason_shop_order_cancelled', 'Order cancelled — wallet refund', 'إلغاء طلب — استرداد للمحفظة'),
    gift_purchase: t('reason_gift_purchase', 'Gift sent', 'إهداء رصيد'),
    gift_redeemed: t('reason_gift_redeemed', 'Gift received', 'رصيد هدية'),
    admin_adjustment: t('reason_admin_adjustment', 'Adjustment by Terracotta', 'تعديل من تيراكوتا'),
  }
  return known[reason] ?? String(reason ?? '').replaceAll('_', ' ')
}

export const useWallet = ({ page = ref(1), perPage = 10 } = {}) => {
  const { data, pending, error, refresh } = useApiFetch('/api/wallet/transactions', {
    key: 'wallet-transactions',
    query: { page, per_page: perPage },
    transform: (res) => {
      const payload = res?.data ?? {}
      return { balance: payload.balance ?? '0.00', ...unwrapList(payload.transactions) }
    },
    default: () => ({ balance: '0.00', items: [], page: 1, lastPage: 1, total: 0 }),
  })

  return {
    balance: computed(() => data.value?.balance ?? '0.00'),
    transactions: computed(() => data.value?.items ?? []),
    lastPage: computed(() => data.value?.lastPage ?? 1),
    total: computed(() => data.value?.total ?? 0),
    pending,
    error,
    refresh,
  }
}
