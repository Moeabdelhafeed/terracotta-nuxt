<template>
  <div
    class="pointer-events-none fixed inset-x-0 top-4 z-[60] flex flex-col items-center gap-2 px-4"
    aria-live="polite"
  >
    <TransitionGroup
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="-translate-y-2 opacity-0"
      leave-active-class="transition duration-200 ease-in"
      leave-to-class="opacity-0"
    >
      <div
        v-for="toast in toasts"
        :key="toast.id"
        class="pointer-events-auto flex max-w-md items-start gap-3 rounded-2xl border px-4 py-3 text-sm shadow-lg backdrop-blur-md"
        :class="tone[toast.kind]"
        role="status"
      >
        <LucideCheckCircle2 v-if="toast.kind === 'success'" class="mt-0.5 size-4 shrink-0" />
        <LucideAlertCircle v-else-if="toast.kind === 'error'" class="mt-0.5 size-4 shrink-0" />
        <LucideInfo v-else class="mt-0.5 size-4 shrink-0" />
        <span class="min-w-0 flex-1">{{ toast.message }}</span>
        <button type="button" class="opacity-70 transition-opacity hover:opacity-100" :aria-label="t('dismiss', 'Dismiss', 'إغلاق')" @click="dismiss(toast.id)">
          <LucideX class="size-4" />
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<script setup>
const { toasts, dismiss } = useToast()
const { t } = useLang('web', 'general')

const tone = {
  success: 'border-brand-green/30 bg-brand-green text-white',
  error: 'border-destructive/30 bg-destructive text-white',
  info: 'border-brand-ink/20 bg-brand-ink/90 text-white',
}
</script>
