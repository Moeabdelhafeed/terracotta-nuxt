<template>
  <!-- Registered only: the balance is an account's, and a guest has no ledger to read. -->
  <div v-if="isRegistered" class="flex items-stretch gap-4">
    <!-- The balance is the fact the reader came for; the gift tile is an offer beside it. -->
    <NuxtLink
      to="/wallet"
      class="flex flex-1 flex-col rounded-card border bg-card p-5 transition-colors hover:bg-brand-mist/40"
    >
      <span class="text-sm text-muted-foreground">
        {{ t("terracotta_balance", "Terracotta balance", "رصيد تيراكوتا") }}
      </span>

      <span class="mt-1 font-display text-2xl font-black text-primary">
        {{ format(balance) }}
      </span>

      <!--
        A control, not a caption: in the app this is a bordered row with an arrow, and it
        is the whole reason the card is tappable. `w-fit`, so it hugs its words instead of
        stretching to the card's width.

        The arrow is NOT mirrored: a back arrow flips with the language, but this one
        means "onward", and onward in Arabic already points left — `rtl:-scale-x-100`
        turned it round to point back the way the reader came.
      -->
      <span
        class="mt-4 flex w-fit items-center gap-2 rounded-xl border px-4 py-2.5 text-sm font-medium text-foreground"
      >
        {{ t("view_transactions", "View transactions", "عرض المعاملات") }}
        <LucideArrowLeft class="size-4 shrink-0 text-muted-foreground ltr:-scale-x-100" />
      </span>
    </NuxtLink>

    <!--
      Taken off entirely when the studio is not selling gift credit, rather than disabled:
      a gap where it was reads as something that failed to load, and the balance takes the
      width back. `packageActive` is the site's own copy of the app's one switch.
    -->
    <NuxtLink
      v-if="packageActive"
      to="/gifts/new"
      class="relative flex w-[7.5rem] shrink-0 items-center justify-center overflow-hidden rounded-card bg-brand-blush text-center text-white transition-opacity hover:opacity-90"
    >
      <!-- The studio's drawn line, as the app wears it behind this tile. -->
      <CardLineArt class="absolute inset-0 size-full [filter:brightness(0)_invert(1)] opacity-30" />

      <span class="relative flex flex-col items-center gap-2">
        <LucideGift class="size-7" />
        <span class="text-sm font-medium leading-snug">
          {{ t("gift_credit_short", "Gift", "اهداء") }}
        </span>
      </span>
    </NuxtLink>
  </div>
</template>

<script setup>
/**
 * «رصيد تيراكوتا» and «اهداء», side by side.
 *
 * Its own component rather than markup on one page, because the app keeps the pair in one
 * place for the same reason — the workshops, bookings, shop and materials pages all carry
 * it, and four copies would drift. They are one offer: what the reader has, and the way
 * to give somebody else some.
 */
const { t } = useLang("web", "home");
const { format } = usePrice();
const { isRegistered } = useIsRegistered();
const { balance } = useWallet();
const { packageActive } = useGifts();
</script>
