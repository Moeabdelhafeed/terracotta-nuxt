<template>
  <template v-if="order.can_cancel">
    <Button type="button" variant="outline" class="h-12 rounded-xl border-destructive/40 text-destructive hover:bg-destructive/10 hover:text-destructive" :disabled="pending" @click="open = true">
      {{ t('cancel_order', 'Cancel order', 'إلغاء الطلب') }}
    </Button>

    <Teleport to="body">
      <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto p-4" role="dialog" aria-modal="true">
        <div class="absolute inset-0 bg-black/50" @click="pending || (open = false)" />
        <div class="relative w-full max-w-md rounded-2xl border bg-background p-6 shadow-lg">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span class="flex size-9 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust">
                <LucidePackageX class="size-4" />
              </span>
              <h2 class="font-display text-lg font-semibold text-foreground">{{ t('cancel_order', 'Cancel order', 'إلغاء الطلب') }}</h2>
            </div>
            <button type="button" class="text-muted-foreground transition-colors hover:text-foreground" :disabled="pending" @click="open = false">
              <LucideX class="size-5" />
            </button>
          </div>

          <p class="mt-4 text-sm text-muted-foreground">{{ t('cancel_order_confirm', 'Are you sure you want to cancel this order?', 'هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟') }}</p>
          <p class="mt-2 text-sm text-muted-foreground">
            <template v-if="!isZeroMoney(order.wallet_applied)">
              {{ t('cancel_order_refund', 'Only the :amount paid from your wallet is refunded to it; any card payment is not returned here.', 'يُعاد فقط المبلغ المدفوع من محفظتك (:amount) إليها؛ ولا يُعاد هنا أي مبلغ مدفوع بالبطاقة.', { amount: format(order.wallet_applied) }) }}
            </template>
            <template v-else>
              {{ t('cancel_order_no_refund', 'Nothing was paid from your wallet, so there is nothing to refund to it.', 'لم يُدفع شيء من محفظتك، فلا يوجد ما يُعاد إليها.') }}
            </template>
          </p>

          <span v-if="error" class="mt-3 block text-xs text-destructive">{{ error }}</span>

          <div class="mt-6 flex flex-col gap-3 sm:flex-row">
            <Button type="button" variant="outline" class="h-12 flex-1 rounded-xl" :disabled="pending" @click="open = false">
              {{ t('keep_order', 'Keep order', 'الاحتفاظ بالطلب') }}
            </Button>
            <Button type="button" class="h-12 flex-1 rounded-xl bg-destructive text-base text-white hover:bg-destructive/90" :disabled="pending" @click="onConfirm">
              {{ pending ? t('cancelling', 'Cancelling...', 'جارٍ الإلغاء...') : t('confirm_cancel', 'Yes, cancel', 'نعم، إلغاء') }}
            </Button>
          </div>
        </div>
      </div>
    </Teleport>
  </template>
</template>

<script setup>
/**
 * Renders nothing unless `can_cancel` — the server decides, not the status. The confirm
 * button locks on the first tap: a second `DELETE` would only earn a 422.
 */
const props = defineProps({
  order: { type: Object, required: true },
  cancel: { type: Function, required: true },
})

const emit = defineEmits(['cancelled'])

const { t } = useLang('web', 'shop')
const { format } = usePrice()
const { submit, pending, error } = useSubmit()

const open = ref(false)

const onConfirm = async () => {
  if (pending.value) return
  try {
    const res = await submit(() => props.cancel(props.order.id))
    open.value = false
    emit('cancelled', res.data)
  } catch {
    // the message is already on screen
  }
}
</script>
