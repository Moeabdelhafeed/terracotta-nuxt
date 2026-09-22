<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-[60] flex items-center justify-center p-4"
      role="dialog"
      aria-modal="true"
      :aria-label="title"
    >
      <div class="fixed inset-0 bg-black/50" @click="emit('close')" />

      <!--
        Its own shell rather than `BookingSheet`: this one is a full-bleed colour with a
        pattern over it and the copy centred on top, which the shared white sheet with a
        titled header bar and a bordered footer cannot express.
      -->
      <div
        class="relative flex max-h-[90svh] w-full max-w-md flex-col overflow-hidden rounded-sheet bg-brand-blush text-white shadow-lg"
      >
        <!-- The pattern tiles rather than stretches, so the confetti keeps its size
             whatever the sheet grows to. Decorative, so it is hidden from the reader. -->
        <span
          class="pointer-events-none absolute inset-0 bg-[url('/confetti.png')] bg-[length:342px_342px] bg-repeat opacity-25"
          aria-hidden="true"
        />

        <div class="relative overflow-y-auto px-7 pb-7 pt-10 text-center">
          <h2 class="font-display text-3xl font-bold sm:text-4xl">{{ title }}</h2>

          <div class="mt-6 flex flex-col gap-4 text-sm leading-relaxed text-white/90">
            <slot />
          </div>
        </div>

        <div class="relative flex flex-col gap-3 px-7 pb-8">
          <button
            type="button"
            class="text-base font-medium text-white/90 transition-colors hover:text-white"
            @click="emit('close')"
          >
            {{ t('close', 'Close', 'اغلاق') }}
          </button>

          <!-- A wash of white rather than a solid fill: it has to read as raised off the
               pink without introducing a third colour. -->
          <Button
            type="button"
            class="h-14 w-full rounded-2xl bg-white/25 text-base text-white hover:bg-white/35"
            @click="emit('confirm')"
          >
            {{ confirmLabel }}
          </Button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
const props = defineProps({
  open: { type: Boolean, default: false },
  title: { type: String, default: '' },
  confirmLabel: { type: String, default: '' },
})

const emit = defineEmits(['close', 'confirm'])

const { t } = useLang('web', 'bookings')

// Without it a scroll inside the sheet chains to the page behind it once the sheet hits
// its own end, and the booking flow is somewhere else when the sheet closes.
useModalScrollLock(toRef(props, 'open'))
</script>
