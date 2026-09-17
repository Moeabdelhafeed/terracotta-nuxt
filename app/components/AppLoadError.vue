<template>
  <div
    v-if="error"
    role="alert"
    data-test="load-error"
    class="mx-auto flex w-full max-w-xl flex-col items-center gap-3 rounded-card border bg-card p-10 text-center"
  >
    <span class="flex size-12 items-center justify-center rounded-control bg-destructive/10 text-destructive">
      <LucideWifiOff v-if="offline" class="size-5" />
      <LucideCircleAlert v-else class="size-5" />
    </span>

    <h2 class="font-display text-lg font-semibold text-foreground">{{ title }}</h2>
    <p class="text-sm text-muted-foreground">{{ body }}</p>

    <Button
      v-if="retry"
      class="mt-2 h-12 rounded-control px-8 text-base"
      :disabled="retrying"
      data-test="load-error-retry"
      @click="onRetry"
    >
      <LucideRotateCw class="size-4" :class="retrying ? 'animate-spin' : ''" />
      {{ t('retry', 'Try again', 'إعادة المحاولة', { subGroup: 'general' }) }}
    </Button>
  </div>
</template>

<script setup>
/**
 * A request that FAILED, said out loud — the one thing every list on this site used to
 * swallow. `useApiFetch`/`useApiList` resolve to their `default` on a rejection, so a 500
 * or an offline browser reached the page as an empty array and rendered its "nothing here
 * yet" copy. Mount this above the empty state and flip that state to `v-else-if`, and the
 * two stop looking alike.
 *
 *   <AppLoadError :error="error" :retry="refresh" />
 *   <ul v-else-if="pending"> … skeleton
 *   <div v-else-if="!items.length"> … empty
 *   <ul v-else> … rows
 *
 * Renders nothing when `error` is null, so it costs a page one line.
 */
const props = defineProps({
  error: { type: [Object, Error], default: null },
  retry: { type: Function, default: null },
})

const { t } = useLang('web', 'general')
const online = useOnline()

const offline = computed(() => !online.value)

const title = computed(() => (offline.value
  ? t('offline_title', "You're offline", 'أنت غير متصل')
  : t('load_failed_title', 'Something went wrong', 'حدث خطأ ما')))

/**
 * The server's own sentence when it sent one — a rate limit or a maintenance window is
 * worth reading. A transport failure carries ofetch's wording, which names hosts and
 * sockets and means nothing to a customer.
 */
const body = computed(() => {
  if (offline.value) return t('offline_body', 'Check your connection and try again.', 'تحقق من اتصالك وحاول مرة أخرى.')
  const sent = props.error?.data?.message
  if (typeof sent === 'string' && sent.trim()) return sent
  return t('load_failed_body', "We couldn't load this. Try again in a moment.", 'تعذّر تحميل هذا. حاول بعد قليل.')
})

const retrying = ref(false)
const onRetry = async () => {
  retrying.value = true
  try {
    await props.retry()
  } finally {
    retrying.value = false
  }
}
</script>
