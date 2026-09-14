<template>
  <ol class="flex flex-col gap-0">
    <li v-for="(step, index) in steps" :key="step.key" class="relative flex gap-4 pb-6 last:pb-0">
      <span
        v-if="index < steps.length - 1"
        aria-hidden="true"
        class="absolute top-8 bottom-0 w-px ltr:left-4 rtl:right-4"
        :class="step.done && steps[index + 1].done ? 'bg-brand-green' : 'bg-border'"
      />
      <span
        class="relative z-10 flex size-8 shrink-0 items-center justify-center rounded-full border-2"
        :class="step.tone"
      >
        <LucideX v-if="step.state === 'stopped'" class="size-4" />
        <LucideCheck v-else-if="step.done" class="size-4" />
        <LucideClock v-else-if="step.state === 'current'" class="size-4" />
        <span v-else class="size-2 rounded-full bg-current opacity-40" />
      </span>
      <div class="min-w-0 pt-1">
        <p class="text-sm font-medium" :class="step.done || step.state === 'current' ? 'text-foreground' : 'text-muted-foreground'">{{ step.label }}</p>
        <p v-if="step.note" class="mt-0.5 text-xs text-muted-foreground">{{ step.note }}</p>
      </div>
    </li>
  </ol>
</template>

<script setup>
/**
 * `awaiting_payment → pending → preparing → out_for_delivery → completed`, with the
 * pay step shown only while the order sits in it, and `cancelled` as a red stop after
 * the last step that was actually reached.
 */
const props = defineProps({
  order: { type: Object, required: true },
})

const { t } = useLang('web', 'shop')
const { formatDate } = useDateFormat()
const { format } = usePrice()

const LABELS = () => ({
  awaiting_payment: t('step_awaiting_payment', 'Payment', 'الدفع'),
  pending: t('step_pending', 'Order confirmed', 'تم تأكيد الطلب'),
  preparing: t('step_preparing', 'Being prepared', 'قيد التحضير'),
  out_for_delivery: t('step_out_for_delivery', 'Out for delivery', 'خرج للتوصيل'),
  completed: t('step_completed', 'Delivered', 'تم التسليم'),
})

const TONES = {
  done: 'border-brand-green bg-brand-green text-white',
  current: 'border-brand-rust bg-brand-rust/10 text-brand-rust',
  todo: 'border-border bg-card text-muted-foreground',
  stopped: 'border-destructive bg-destructive text-white',
}

/**
 * `refunded_amount` is the whole charge on a paid order and null on a hold that was never
 * paid — null means nothing was refunded, not that nothing came back: the wallet slice the
 * hold was sitting on is still released, and saying so is the only way the line is true.
 */
const refundNote = () => {
  if (!isZeroMoney(props.order.refunded_amount)) {
    return t('refunded_to_wallet', ':amount refunded to your wallet', 'تمت إعادة :amount إلى محفظتك', { amount: format(props.order.refunded_amount) })
  }
  if (!isZeroMoney(props.order.wallet_applied)) {
    return t('hold_released_to_wallet', ':amount released back to your wallet', 'أُعيد :amount المحجوز إلى محفظتك', { amount: format(props.order.wallet_applied) })
  }
  return ''
}

const steps = computed(() => {
  const labels = LABELS()
  const status = props.order.status
  const paid = props.order.payment_status === 'paid' || props.order.payment_status === 'refunded'
  const path = status === 'awaiting_payment' ? ['awaiting_payment', ...ORDER_STEPS] : ORDER_STEPS
  const reached = status === 'cancelled' ? (paid ? 0 : -1) : path.indexOf(status)

  const list = path.map((key, index) => {
    const done = index < reached || (status === 'completed' && key === 'completed')
    const current = index === reached && status !== 'completed'
    return {
      key,
      label: labels[key],
      done,
      state: done ? 'done' : current ? 'current' : 'todo',
      tone: done ? TONES.done : current ? TONES.current : TONES.todo,
      note: key === 'pending' && (done || current) ? formatDate(props.order.created_at) : '',
    }
  })

  if (status === 'cancelled') {
    const cut = list.slice(0, reached + 1)
    cut.push({
      key: 'cancelled',
      label: t('step_cancelled', 'Cancelled', 'تم الإلغاء'),
      done: false,
      state: 'stopped',
      tone: TONES.stopped,
      note: [
        props.order.cancelled_at ? formatDate(props.order.cancelled_at) : '',
        refundNote(),
      ].filter(Boolean).join(' · '),
    })
    return cut
  }
  return list
})
</script>
