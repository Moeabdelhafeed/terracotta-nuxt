<template>
  <AuthScreen
    :title="t('create_account', 'Create account', 'إنشاء حساب')"
    :subtitle="verified ? '' : t('verify_otp_sent_note', 'We sent a :count-digit code to your :field.', 'لقد أرسلنا رمز تحقق مكوّنًا من :count أرقام إلى :field.', { count: OTP_LENGTH, field: targetLabel })"
  >
    <template v-if="verified">
      <AppConfetti />
      <div class="flex flex-col items-center gap-4 text-center">
        <span class="flex size-16 items-center justify-center rounded-full bg-brand-green/15 text-brand-green">
          <LucideCheck class="size-8" />
        </span>
        <h2 data-test="verify-success" class="font-display text-2xl font-semibold text-foreground">
          {{ t('account_created_success', 'Your account is ready', 'تم انشاء الحساب بنجاح') }}
        </h2>
        <Button as-child size="lg" class="h-13 w-full rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90">
          <NuxtLink to="/">{{ t('continue', 'Continue', 'استكمال') }}</NuxtLink>
        </Button>
      </div>
    </template>

    <template v-else>
      <form class="flex flex-col gap-6" @submit.prevent="onSubmit">
        <div class="grid gap-3">
          <Label class="text-center">{{ t('enter_verification_code', 'Enter the verification code', 'أدخل رمز التحقق') }}</Label>
          <AuthOtpInput v-model="otp" :length="OTP_LENGTH" />
          <span v-if="errors.otp" class="text-center text-xs text-destructive">{{ errors.otp[0] }}</span>
          <span v-else-if="error" class="text-center text-xs text-destructive">{{ error }}</span>
          <span v-if="attempts >= 3" class="text-center text-xs text-amber-600">
            {{ t('otp_attempts_warning', 'A few more wrong tries and this code stops working — ask for a new one.', 'محاولات خاطئة قليلة أخرى وسيتوقف هذا الرمز — اطلب رمزًا جديدًا.') }}
          </span>
        </div>

        <Button
          type="submit"
          size="lg"
          class="h-13 w-full rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
          :disabled="loading || resending || otp.length < OTP_LENGTH"
        >
          {{ loading ? t('verifying', 'Verifying...', 'جارٍ التحقق...') : t('verify', 'Verify', 'تحقق') }}
        </Button>

        <div class="flex flex-col items-center gap-3 text-sm">
          <button
            type="button"
            class="font-medium text-brand-rust underline-offset-4 hover:underline disabled:cursor-not-allowed disabled:text-muted-foreground disabled:no-underline"
            :disabled="cooldown > 0 || resending || loading"
            @click="resend"
          >
            {{ resending
              ? t('sending', 'Sending...', 'جارٍ الإرسال...')
              : cooldown > 0
                ? t('resend_code_in', 'Resend the code :timer', 'اعادة ارسال الرمز :timer', { timer: countdown })
                : t('resend_code', 'Resend the code', 'اعادة ارسال الرمز') }}
          </button>
          <Button variant="outline" size="sm" class="rounded-xl" :disabled="loggingOut || loading || resending" @click="handleLogout">
            {{ loggingOut ? t('logging_out', 'Logging out...', 'جارٍ تسجيل الخروج...') : t('logout', 'Sign out', 'تسجيل الخروج') }}
          </Button>
        </div>
      </form>
    </template>
  </AuthScreen>
</template>

<script setup>
/**
 * `POST /api/verify-otp` and `POST /api/send-otp` are protected routes — the bearer
 * identifies the account, so neither carries an identifier. Five wrong codes destroy the
 * code server-side, hence the warning from the third failure.
 */
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'unverified'],
  name: 'verify',
})

const OTP_LENGTH = 6
const RESEND_COOLDOWN = 120

const client = useApi()
const { user, refreshIdentity, logout } = useSanctumAuth()
const { t } = useLang('web', 'auth')

const otp = ref('')
const errors = ref({})
const error = ref('')
const loading = ref(false)
const resending = ref(false)
const loggingOut = ref(false)
const verified = ref(false)
const attempts = ref(0)
const cooldown = ref(0)
let timer = null

const profile = computed(() => user.value?.data ?? user.value ?? null)
const targetLabel = computed(() => profile.value?.phone || profile.value?.email || t('your_account', 'your account', 'حسابك'))

const countdown = computed(() => {
  const minutes = Math.floor(cooldown.value / 60)
  return `${minutes}:${String(cooldown.value % 60).padStart(2, '0')}`
})

const startCooldown = () => {
  cooldown.value = RESEND_COOLDOWN
  if (timer) clearInterval(timer)
  timer = setInterval(() => {
    cooldown.value--
    if (cooldown.value <= 0) { clearInterval(timer); timer = null }
  }, 1000)
}

onUnmounted(() => { if (timer) clearInterval(timer) })

const handleLogout = async () => {
  loggingOut.value = true
  try {
    await logout()
    if (import.meta.client) document.cookie = 'current_token_id=; path=/; max-age=0'
    navigateTo({ name: 'login' })
  } finally {
    loggingOut.value = false
  }
}

const onSubmit = async () => {
  errors.value = {}
  error.value = ''
  loading.value = true
  try {
    await client('/api/verify-otp', { method: 'POST', body: { otp: otp.value } })
    await refreshIdentity()
    verified.value = true
  } catch (e) {
    const normalized = normalizeApiError(e)
    errors.value = normalized.errors
    error.value = normalized.errors.otp ? '' : normalized.message
    attempts.value++
    otp.value = ''
  } finally {
    loading.value = false
  }
}

const resend = async () => {
  if (cooldown.value > 0 || resending.value) return
  errors.value = {}
  error.value = ''
  resending.value = true
  try {
    await client('/api/send-otp', { method: 'POST' })
    attempts.value = 0
    startCooldown()
  } catch (e) {
    const normalized = normalizeApiError(e)
    errors.value = normalized.errors
    error.value = normalized.message
  } finally {
    resending.value = false
  }
}
</script>
