<template>
  <BookingSheet
    :open="open"
    :title="t('paint_choice_title', 'Where to paint it', 'أين تلوّنها')"
    @close="emit('close')"
  >
    <template #icon><LucideBrush class="size-5" /></template>

    <p class="text-sm text-muted-foreground">
      {{
        t(
          'paint_choice_body',
          'Each workshop sets its own rate for bringing a piece back.',
          'كل ورشة تحدد سعرها لإحضار قطعة معك.',
        )
      }}
    </p>

    <ul class="mt-5 flex flex-col gap-2">
      <li v-for="offer in offers" :key="offer.workshop.id">
        <button
          type="button"
          class="flex w-full items-center gap-3 rounded-2xl border bg-card p-3 text-start transition-colors hover:bg-brand-mist/50"
          @click="emit('choose', offer)"
        >
          <AppImage
            v-if="offer.workshop.image?.image_api"
            :src="offer.workshop.image"
            :alt="offer.workshop.title"
            class="size-12 shrink-0 rounded-xl object-cover"
          />
          <span v-else class="size-12 shrink-0 rounded-xl bg-brand-mist" />

          <span class="min-w-0 flex-1 truncate text-sm font-medium">{{ offer.workshop.title }}</span>

          <!-- `"0.00"` is an untouched CMS field, not a free session, so it reads as
               unset rather than as a price. -->
          <span
            v-if="isZeroMoney(offer.price)"
            class="shrink-0 text-xs text-muted-foreground"
          >{{ t('rate_not_set', 'Not specified', 'غير محدد') }}</span>
          <span
            v-else
            class="shrink-0 text-sm font-semibold"
            :style="{ color: offer.workshop.color || undefined }"
            :class="offer.workshop.color ? '' : 'text-brand-terracotta'"
          >{{ money(offer.price) }}</span>
        </button>
      </li>
    </ul>
  </BookingSheet>
</template>

<script setup>
/**
 * Opened by the piece's paint button — **always**, even when only one workshop will take
 * the piece: where it is painted and what that costs is the customer's call, not a
 * default the page makes for them.
 */
defineProps({
  open: { type: Boolean, default: false },
  /** Already sorted by `sortOffers`: rates first, cheapest of those first, unset last. */
  offers: { type: Array, default: () => [] },
})

const emit = defineEmits(['close', 'choose'])

const { t, code } = useLang('web', 'profile')
const { currency } = usePrice()

const money = (value) => `${localeDigits(displayMoney(value), code.value)} ${currency.value}`
</script>
