<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-[70] flex items-center justify-center p-6"
      role="dialog"
      aria-modal="true"
    >
      <div class="fixed inset-0 bg-black/50" @click="dismiss" />

      <div class="relative w-full max-w-md rounded-sheet bg-background p-6 shadow-2xl">
        <div class="flex items-start justify-between gap-4">
          <h2 class="font-display text-lg font-bold">
            {{ t("login_required_title", "Sign in to continue", "سجّل الدخول للمتابعة") }}
          </h2>
          <button
            type="button"
            class="flex size-9 shrink-0 items-center justify-center rounded-xl bg-brand-mist text-foreground/70 transition-colors hover:text-foreground"
            :aria-label="t('close', 'Close', 'إغلاق')"
            @click="dismiss"
          >
            <LucideX class="size-4" />
          </button>
        </div>

        <p class="mt-3 text-sm leading-relaxed text-muted-foreground">
          {{
            t(
              "login_required_body",
              "This step needs an account. Sign in to reach your cart, your bookings and your balance.",
              "هذه الخطوة تحتاج إلى حساب. سجّل الدخول للوصول إلى سلتك وحجوزاتك ورصيدك.",
            )
          }}
        </p>

        <div class="mt-6 grid grid-cols-2 gap-3">
          <Button
            class="h-12 rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
            @click="signIn"
          >
            {{ t("login_required_cta", "Sign in", "تسجيل الدخول") }}
          </Button>
          <Button variant="outline" class="h-12 rounded-xl text-base" @click="dismiss">
            {{ t("cancel", "Cancel", "إلغاء") }}
          </Button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
const { t } = useLang("web", "auth");
const { target, open, dismiss } = useLoginPrompt();

useModalScrollLock(open);

const signIn = () => {
  const redirect = target.value;
  dismiss();
  navigateTo({ path: "/login", query: redirect && redirect !== "/" ? { redirect } : {} });
};
</script>
