<template>
  <div class="flex h-full flex-col gap-4 rounded-card border bg-card p-6">
    <div class="flex items-start justify-between gap-4">
      <div class="flex min-w-0 items-start gap-3">
        <span class="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-field bg-success/10 text-success rtl:-scale-x-100">
          <LucideArrowDownLeft class="size-4" />
        </span>
        <div class="min-w-0">
          <p class="text-xs uppercase tracking-[0.2em] text-muted-foreground">
            {{ t('gift_received_eyebrow', 'Claimed', 'استلمتها') }}
          </p>
          <p class="mt-1 truncate font-display text-xl font-semibold">
            {{ gift.from
              ? t('gift_from', 'From :name', 'من :name', { name: gift.from })
              : t('gift_from_someone', 'A gift you claimed', 'هدية استلمتها') }}
          </p>
        </div>
      </div>
      <p class="shrink-0 font-display text-2xl font-black text-primary">{{ format(gift.amount) }}</p>
    </div>

    <p v-if="gift.message" class="line-clamp-2 text-sm text-muted-foreground">“{{ gift.message }}”</p>

    <div class="mt-auto flex flex-wrap items-center gap-2">
      <span class="rounded-md bg-success/10 px-3 py-1 text-xs font-medium text-success">
        {{ t('gift_in_wallet', 'In your wallet', 'في محفظتك') }}
      </span>
      <span class="ms-auto text-xs text-muted-foreground">{{ formatDateOnly(gift.redeemed_at ?? gift.created_at) }}</span>
    </div>
  </div>
</template>

<script setup>
/**
 * A gift the reader CLAIMED. Not a link: there is no buyer's-eye detail page behind it —
 * the token, the share link and what was paid are the buyer's, and the server never puts
 * them on a received row. The money is already in the wallet, moved by its own
 * `gift_redeemed` transaction, so there is nothing here to act on.
 */
defineProps({
  gift: { type: Object, required: true },
})

const { t } = useLang('web', 'gifts')
const { format } = usePrice()
const { formatDateOnly } = useDateFormat()
</script>
