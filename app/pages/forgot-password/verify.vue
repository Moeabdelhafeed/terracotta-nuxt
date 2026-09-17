<template>
  <AuthScreen
    back="/forgot-password"
    :title="t('verify_otp', 'Enter the verification code', 'أدخل رمز التحقق')"
    :subtitle="
      t(
        'enter_otp_sent_to',
        'We sent a code to :target.',
        'أرسلنا رمزًا إلى :target.',
        { target: form.identifier },
      )
    "
  >
    <form class="flex flex-col gap-6" @submit.prevent="onSubmit">
      <p
        v-if="expired"
        data-test="reset-code-expired"
        class="rounded-card bg-warning/15 px-4 py-3 text-center text-sm text-foreground"
      >
        {{
          t(
            "reset_code_expired",
            "That code is no longer valid. Ask for a new one and enter it below.",
            "لم يعد هذا الرمز صالحًا. اطلب رمزًا جديدًا وأدخله أدناه.",
          )
        }}
      </p>
      <div class="flex flex-col items-center gap-2">
        <AuthOtpInput v-model="form.otp" @complete="onSubmit" />
        <span v-if="errors.otp" class="text-xs text-destructive">{{
          errors.otp[0]
        }}</span>
        <span v-if="errors.identifier" class="text-xs text-destructive">{{
          errors.identifier[0]
        }}</span>
      </div>
      <Button
        type="submit"
        size="lg"
        class="h-13 w-full rounded-control bg-brand-rust text-base hover:bg-brand-rust/90"
        :disabled="loading || resending || form.otp.length < 6"
      >
        {{
          loading
            ? t("verifying", "Verifying...", "جارٍ التحقق...")
            : t("verify", "Verify", "تحقق")
        }}
      </Button>
      <button
        type="button"
        class="mx-auto rounded-control bg-brand-rust/10 px-4 py-2 text-sm font-medium text-brand-rust transition-colors disabled:cursor-not-allowed disabled:opacity-50"
        :disabled="cooldown > 0 || resending || loading"
        @click="resend"
      >
        {{
          resending
            ? t("sending", "Sending...", "جارٍ الإرسال...")
            : cooldown > 0
              ? t(
                  "resend_in_seconds",
                  "Resend in :seconds s",
                  "إعادة الإرسال خلال :seconds ث",
                  { seconds: cooldown },
                )
              : t("resend_otp", "Resend OTP", "إعادة إرسال الرمز")
        }}
      </button>
    </form>
  </AuthScreen>
</template>

<script setup>
definePageMeta({
  middleware: ["auth-mode", "require-pre-auth", "password-mode-only"],
  name: "forgot-password-verify",
});

const RESEND_COOLDOWN = 120;

const route = useRoute();
const errors = ref({});
const loading = ref(false);
const resending = ref(false);
const client = useApi();
const { t } = useLang("web", "auth");

const form = ref({
  identifier: route.query.identifier?.toString() ?? "",
  // Carried through the flow so every step declares the same identifier kind.
  type: route.query.type?.toString() ?? "",
  otp: "",
});

if (!form.value.identifier) {
  navigateTo({ name: "forgot-password" });
}

const expired = ref(route.query.expired === "1");
const redirectTarget = computed(() => safeAuthRedirect(route.query.redirect));

const cooldown = ref(0);
let timer = null;

const startCooldown = () => {
  cooldown.value = RESEND_COOLDOWN;
  if (timer) clearInterval(timer);
  timer = setInterval(() => {
    cooldown.value--;
    if (cooldown.value <= 0) {
      clearInterval(timer);
      timer = null;
    }
  }, 1000);
};

onUnmounted(() => {
  if (timer) clearInterval(timer);
});

const onSubmit = async () => {
  if (loading.value) return;
  errors.value = {};
  loading.value = true;
  try {
    await client("/api/verify-forgot-password-otp", {
      method: "POST",
      body: form.value,
    });
    navigateTo({
      name: "forgot-password-reset",
      query: {
        identifier: form.value.identifier,
        type: form.value.type,
        otp: form.value.otp,
        ...(redirectTarget.value === "/"
          ? {}
          : { redirect: redirectTarget.value }),
      },
    });
  } catch (error) {
    errors.value = error.data?.errors ?? {};
  } finally {
    loading.value = false;
  }
};

const resend = async () => {
  if (cooldown.value > 0 || resending.value) return;
  errors.value = {};
  resending.value = true;
  expired.value = false;
  try {
    await client("/api/forgot-password", {
      method: "POST",
      body: { identifier: form.value.identifier, type: form.value.type },
    });
    startCooldown();
  } catch (error) {
    errors.value = error.data?.errors ?? {};
  } finally {
    resending.value = false;
  }
};
</script>
