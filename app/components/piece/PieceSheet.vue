<template>
  <BookingSheet
    :open="!!piece"
    wide
    :title="piece?.label || t('piece_untitled', 'Untitled piece', 'قطعة بلا اسم')"
    @close="emit('close')"
  >
    <template #icon><LucidePalette class="size-5" /></template>

    <template v-if="piece">
      <div class="flex flex-wrap items-center gap-x-3 gap-y-2 text-xs text-muted-foreground">
        <span
          v-if="statusLabel"
          class="rounded-md px-2 py-0.5 font-semibold"
          :class="statusTone"
        >{{ statusLabel }}</span>

        <span v-if="piece.madeOn">
          {{ t('piece_made_on', 'Made :date', 'صُنعت في :date', { date: formatDate(piece.madeOn) }) }}
        </span>

        <span v-if="piece.workshopTitle">
          {{ t('piece_made_at', 'Made at :workshop', 'صُنعت في :workshop', { workshop: piece.workshopTitle }) }}
        </span>
      </div>

      <!-- Every photograph, in the same masonry rhythm as the page behind the sheet. -->
      <ul class="mt-5 columns-2 gap-2 sm:columns-3 [&>li]:mb-2">
        <li v-for="(image, index) in piece.images" :key="image.id" class="break-inside-avoid">
          <button
            type="button"
            class="block w-full overflow-hidden rounded-xl bg-brand-mist"
            @click="lightbox = index"
          >
            <AppImage :src="image" :alt="piece.label ?? ''" class="w-full object-cover" />
          </button>
        </li>
      </ul>

      <AppLightbox v-model="lightbox" :items="piece.images" :alt="piece.label ?? ''" />
    </template>

    <!-- Pinned, not at the end of the photographs: on a piece with six pictures the
         button used to scroll away. BookingSheet's footer sits outside the scroll area. -->
    <template v-if="piece?.offers?.length" #footer>
      <Button
        type="button"
        size="lg"
        class="h-12 w-full rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
        @click="emit('paint', piece)"
      >
        {{ buttonLabel }}
      </Button>
    </template>
  </BookingSheet>
</template>

<script setup>
const props = defineProps({
  /** Null closes the sheet. */
  piece: { type: Object, default: null },
})

const emit = defineEmits(['close', 'paint'])

const { t, code } = useLang('web', 'profile')
const { formatDate } = useDateFormat()
const { currency } = usePrice()

const lightbox = ref(null)

// Closing the sheet must not leave the lightbox open over the page behind it.
watch(() => props.piece, () => { lightbox.value = null })

const statusLabel = computed(() => pieceStatusLabel(props.piece?.status, t))

const statusTone = computed(() => ({
  ready_to_paint: 'bg-brand-terracotta/10 text-brand-terracotta',
  // The studio's mint: painted is done, not an error.
  painted: 'bg-brand-green/15 text-brand-green',
}[props.piece?.status] ?? 'bg-muted text-muted-foreground'))

/**
 * A figure only when exactly one workshop will take the piece. With two or more the
 * cheapest is not what the reader is about to pay, and the chooser lists every rate
 * anyway.
 */
const buttonLabel = computed(() => {
  const offers = props.piece?.offers ?? []
  if (offers.length === 1 && !isZeroMoney(offers[0].price)) {
    const amount = `${localeDigits(displayMoney(offers[0].price), code.value)} ${currency.value}`
    return t('piece_paint_for', 'Paint it for :amount', 'لوّنها بـ :amount', { amount })
  }
  return t('piece_paint', 'Paint it', 'لوّنها')
})
</script>
