<template>
  <Teleport to="body">
    <div class="fixed inset-0 z-[60] flex items-center justify-center p-4" role="dialog" aria-modal="true">
      <div class="fixed inset-0 bg-black/50" @click="emit('close')" />
      <div class="relative max-h-[90svh] w-full max-w-lg overflow-y-auto rounded-2xl border bg-background p-6 shadow-lg">
        <div class="mb-5 flex items-center justify-between">
          <span class="flex items-center gap-3">
            <span class="flex size-9 items-center justify-center rounded-xl bg-brand-terracotta/10 text-brand-terracotta"><LucideFileText class="size-4" /></span>
            <span class="font-display text-base font-semibold">{{ page?.name || title }}</span>
          </span>
          <button type="button" class="text-muted-foreground transition-colors hover:text-foreground" :aria-label="t('close', 'Close', 'إغلاق')" @click="emit('close')">
            <LucideX class="size-5" />
          </button>
        </div>

        <div v-if="pending && !page" class="flex flex-col gap-3" aria-busy="true">
          <AppSkeleton v-for="n in 5" :key="n" class="h-4 w-full" />
        </div>
        <p v-else-if="!page" class="text-sm text-muted-foreground">
          {{ t('page_unavailable', 'This page is not available right now.', 'هذه الصفحة غير متاحة حاليًا.') }}
        </p>
        <!-- eslint-disable-next-line vue/no-v-html -- server-authored CMS copy, never bundled -->
        <div
          v-else
          data-test="page-content"
          class="prose prose-sm max-h-[60svh] max-w-none overflow-y-auto dark:prose-invert [&_a]:text-brand-terracotta [&_a]:underline [&_h2]:mt-6 [&_h2]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h3]:mt-4 [&_h3]:mb-2 [&_h3]:font-semibold [&_li]:my-1 [&_p]:my-3 [&_ul]:list-disc [&_ul]:ps-6"
          v-html="page.content"
        />

        <Button class="mt-6 h-12 w-full rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90" @click="emit('close')">
          {{ t('close', 'Close', 'إغلاق') }}
        </Button>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
/**
 * One CMS page in a dialog, for the documents an auth screen has to put in front of
 * somebody without sending them away from the form they are filling in — the terms and
 * the privacy policy both.
 *
 * The copy is FETCHED (`GET /api/pages/{slug}`), never bundled with the app, so the
 * operator changes it without a deploy and only one copy is ever live. The full page is
 * still at `/{slug}` for anyone who wants the address itself.
 *
 * Mounted only while it is open (`v-if` at the call site, keyed by slug), so `usePage`
 * is given a plain string and each document gets its own fetch key.
 */
const props = defineProps({
  /** A CMS page slug — `terms`, `privacy`. */
  slug: { type: String, required: true },
  /** Shown in the header until the page itself arrives with its own name. */
  title: { type: String, default: '' },
})

const emit = defineEmits(['close'])

useModalScrollLock(ref(true))

const { t } = useLang('web', 'auth')
const { page, pending } = usePage(props.slug)
</script>
