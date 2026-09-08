<template>
  <Teleport to="body">
    <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4" role="dialog" aria-modal="true">
      <div class="absolute inset-0 bg-black/50" @click="busy || emit('close')" />

      <div class="relative flex max-h-[85vh] w-full flex-col overflow-hidden rounded-2xl border bg-background shadow-lg" :class="wide ? 'max-w-2xl' : 'max-w-md'">
        <div class="flex items-center justify-between gap-3 border-b p-6 pb-4">
          <div class="flex items-center gap-3">
            <span v-if="$slots.icon" class="flex size-9 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust">
              <slot name="icon" />
            </span>
            <h2 class="font-display text-lg font-semibold">{{ title }}</h2>
          </div>
          <Button type="button" size="icon" variant="ghost" class="size-9 rounded-xl" :disabled="busy" :aria-label="t('close', 'Close', 'اغلاق')" @click="emit('close')">
            <LucideX class="size-5" />
          </Button>
        </div>

        <div class="overflow-y-auto p-6">
          <slot />
        </div>

        <div v-if="$slots.footer" class="flex gap-3 border-t p-6 pt-4">
          <slot name="footer" />
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
/** The app's Teleport modal, as one shell — the booking detail opens four of them. */
defineProps({
  open: { type: Boolean, default: false },
  title: { type: String, default: '' },
  busy: { type: Boolean, default: false },
  wide: { type: Boolean, default: false },
})

const emit = defineEmits(['close'])
const { t } = useLang('web', 'bookings')
</script>
