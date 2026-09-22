<template>
  <Teleport to="body">
    <div v-if="open" class="fixed inset-0 z-[60] flex items-center justify-center p-4" role="dialog" aria-modal="true">
      <div class="fixed inset-0 bg-black/50" @click="emit('update:open', false)" />
      <div class="relative max-h-[90svh] w-full max-w-lg overflow-y-auto rounded-2xl border bg-background p-6 shadow-lg">
        <div class="mb-5 flex items-center justify-between">
          <span class="flex items-center gap-3">
            <span class="flex size-9 items-center justify-center rounded-xl bg-brand-terracotta/10 text-brand-terracotta"><LucideFileText class="size-4" /></span>
            <span class="font-display text-base font-semibold">{{ page?.name || t('terms_and_conditions', 'Terms & Conditions', 'الشروط والأحكام') }}</span>
          </span>
          <button type="button" class="text-muted-foreground transition-colors hover:text-foreground" :aria-label="t('close', 'Close', 'إغلاق')" @click="emit('update:open', false)">
            <LucideX class="size-5" />
          </button>
        </div>

        <div v-if="pending && !page" class="flex flex-col gap-3" aria-busy="true">
          <AppSkeleton v-for="n in 5" :key="n" class="h-4 w-full" />
        </div>
        <p v-else-if="!page" class="text-sm text-muted-foreground">
          {{ t('terms_unavailable', 'The terms are not available right now.', 'الشروط غير متاحة حاليًا.') }}
        </p>
        <!-- eslint-disable-next-line vue/no-v-html -- server-authored CMS copy, never bundled -->
        <div
          v-else
          data-test="terms-content"
          class="prose prose-sm max-h-[60svh] max-w-none overflow-y-auto dark:prose-invert [&_a]:text-brand-terracotta [&_a]:underline [&_h2]:mt-6 [&_h2]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h3]:mt-4 [&_h3]:mb-2 [&_h3]:font-semibold [&_li]:my-1 [&_p]:my-3 [&_ul]:list-disc [&_ul]:ps-6"
          v-html="page.content"
        />

        <Button class="mt-6 h-12 w-full rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90" @click="emit('update:open', false)">
          {{ t('close', 'Close', 'إغلاق') }}
        </Button>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
/**
 * The terms are FETCHED from the CMS (`GET /api/pages/{slug}`), never bundled with the
 * app — the operator can change them without a deploy, and only one copy is ever live.
 */
const props = defineProps({ open: { type: Boolean, default: false } })

useModalScrollLock(toRef(props, 'open'))
const emit = defineEmits(['update:open'])

const { t } = useLang('web', 'auth')
const { page, pending } = usePage('terms')
</script>
