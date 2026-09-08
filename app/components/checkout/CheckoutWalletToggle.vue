<template>
  <label
    class="flex cursor-pointer items-center justify-between gap-4 rounded-2xl border bg-card p-4 transition-colors"
    :class="{ 'border-brand-rust/50 bg-brand-mist/40': enabled, 'cursor-not-allowed opacity-60': disabled || !hasBalance }"
  >
    <span class="flex items-center gap-3">
      <span class="flex size-9 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust">
        <LucideWallet class="size-4" />
      </span>
      <span class="flex flex-col">
        <span class="text-sm font-medium text-foreground">{{ t('use_wallet', 'Pay from my wallet', 'الدفع من محفظتي') }}</span>
        <span class="text-xs text-muted-foreground">
          {{ hasBalance
            ? t('wallet_balance_available', 'Balance: :amount', 'الرصيد: :amount', { amount: format(balance) })
            : t('wallet_empty', 'Your wallet is empty.', 'محفظتك فارغة.') }}
        </span>
      </span>
    </span>
    <Checkbox v-model="enabled" :disabled="disabled || !hasBalance" />
  </label>
</template>

<script setup>
/**
 * `v-model` is the `use_wallet` flag the parent sends with its quote. The balance comes
 * from the signed-in user; the server caps `wallet_applied` at the total, so the toggle
 * only says "use it", never how much.
 */
const props = defineProps({
  disabled: { type: Boolean, default: false },
})

const enabled = defineModel({ type: Boolean, default: false })
const { t } = useLang('web', 'checkout')
const { format } = usePrice()
const { user } = useSanctumAuth()

const balance = computed(() => user.value?.data?.wallet_balance ?? user.value?.wallet_balance ?? '0.00')
const hasBalance = computed(() => !isZeroMoney(balance.value))
</script>
