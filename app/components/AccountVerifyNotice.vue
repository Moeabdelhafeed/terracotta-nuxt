<template>
  <!--
    The one thing an unverified account has to be told, wherever it is about to be a
    problem. A link, not a banner with a button: the whole row goes to the code screen,
    which is the only thing to do about it.
  -->
  <NuxtLink
    v-if="needsVerification"
    to="/verify"
    data-test="verify-notice"
    class="flex items-center gap-3 rounded-card border border-brand-terracotta/30 bg-brand-terracotta/10 p-4 text-start transition-colors hover:bg-brand-terracotta/15"
  >
    <span class="flex size-10 shrink-0 items-center justify-center rounded-control bg-brand-terracotta/15 text-brand-terracotta">
      <LucideShieldAlert class="size-5" />
    </span>

    <span class="min-w-0 flex-1">
      <span class="block font-medium text-foreground">
        {{ t('verify_notice_title', 'Your account is not verified', 'حسابك غير مفعّل') }}
      </span>
      <span class="block text-sm text-muted-foreground">
        {{ t('verify_notice_body', 'Enter the code we sent to :target to book and order.', 'أدخل الرمز المُرسل إلى :target لتتمكن من الحجز والشراء.', { target }) }}
      </span>
    </span>

    <LucideChevronLeft class="size-5 shrink-0 text-brand-terracotta ltr:-scale-x-100" />
  </NuxtLink>
</template>

<script setup>
/**
 * Shown on the pages an unverified customer lands on — the home page and their account —
 * because the block itself only appears later: `/cart` sends them to the code screen at
 * checkout, and `verified` gates the pages that need it. Being told at the till is too
 * late to be useful.
 */
const { t } = useLang('web', 'auth')
const { account, needsVerification } = useIsRegistered()

const target = computed(
  () => account.value?.phone || account.value?.email || t('your_account', 'your account', 'حسابك'),
)
</script>
