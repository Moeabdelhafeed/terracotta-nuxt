<template>
  <AuthScreen
    :back="{ name: 'login' }"
    :title="t('verify_login_title', 'Enter code', 'أدخل الرمز')"
    :subtitle="
      t(
        'enter_otp_sent_to',
        'We sent a code to :target.',
        'أرسلنا رمزًا إلى :target.',
        { target: identifier },
      )
    "
  >
    <form class="flex flex-col gap-6" @submit.prevent="onSubmit">
      <div class="flex flex-col items-center gap-2">
        <AuthOtpInput v-model="otp" :length="OTP_LENGTH" @complete="onSubmit" />
        <span v-if="errors.otp" class="text-xs text-destructive">{{ errors.otp[0] }}</span>
        <span v-if="errors.identifier" class="text-xs text-destructive">{{ errors.identifier[0] }}</span>
        <span v-if="errors.device_id" class="text-xs text-destructive">{{ errors.device_id[0] }}</span>
        <span v-if="errors.platform" class="text-xs text-destructive">{{ errors.platform[0] }}</span>
        <span v-if="errors.fcm_token" class="text-xs text-destructive">{{ errors.fcm_token[0] }}</span>
        <AuthFormError :message="formError" />
      </div>

      <Button
        type="submit"
        size="lg"
        class="h-13 w-full rounded-control bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
        :disabled="loading || resending || otp.length < OTP_LENGTH"
      >
        {{ loading ? t('verifying', 'Verifying...', 'جارٍ التحقق...') : t('verify', 'Verify', 'تحقق') }}
      </Button>

      <button
        type="button"
        class="mx-auto rounded-control bg-brand-terracotta/10 px-4 py-2 text-sm font-medium text-brand-terracotta transition-colors disabled:cursor-not-allowed disabled:opacity-50"
        :disabled="cooldown > 0 || resending || loading"
        @click="resend"
      >
        {{
          resending
            ? t('sending', 'Sending...', 'جارٍ الإرسال...')
            : cooldown > 0
              ? t('resend_in_seconds', 'Resend in :seconds s', 'إعادة الإرسال خلال :seconds ث', { seconds: cooldown })
              : t('resend_otp', 'Resend OTP', 'إعادة إرسال الرمز')
        }}
      </button>
    </form>
  </AuthScreen>
</template>

<script setup>
definePageMeta({
  middleware: ['require-pre-auth'],
  name: 'verify-login',
})

const OTP_LENGTH = 6
const RESEND_COOLDOWN = 120

const route = useRoute()
const identifier = ref(String(route.query.identifier ?? ''))
const identifierType = ref(String(route.query.type ?? ''))
const redirectTarget = computed(() => safeAuthRedirect(route.query.redirect))
const otp = ref('')
const errors = ref({})
// 429 from the OTP throttle and 403 carry a message and no `errors` map.
const formError = ref('')
const loading = ref(false)
const resending = ref(false)
const cooldown = ref(0)
let timer = null

const client = useApi()
const { user, refreshIdentity } = useSanctumAuth()
const { t } = useLang('web', 'auth')

const startCooldown = () => {
  cooldown.value = RESEND_COOLDOWN
  if (timer) clearInterval(timer)
  timer = setInterval(() => {
    cooldown.value--
    if (cooldown.value <= 0) {
      clearInterval(timer)
      timer = null
    }
  }, 1000)
}

// A code has just been sent, so the button starts on its cooldown rather than live. It
// sits on the 3-per-5-minutes OTP limiter: an enabled button on arrival let a customer who
// had not yet seen the SMS spend their remaining sends before typing anything.
onMounted(startCooldown)

onUnmounted(() => {
  if (timer) clearInterval(timer)
})

const persistTokenId = (tokenId) => {
  if (tokenId == null || !import.meta.client) return
  document.cookie = `current_token_id=${tokenId}; path=/; SameSite=Lax; max-age=${60 * 60 * 24 * 365}`
}

const onSubmit = async () => {
  if (loading.value) return
  if (!identifier.value) {
    navigateTo({ name: 'login' })
    return
  }
  errors.value = {}
  formError.value = ''
  loading.value = true
  try {
    if (user.value?.data?.is_guest) user.value = null
    const res = await client('/api/verify-login', {
      method: 'POST',
      body: {
        identifier: identifier.value,
        type: identifierType.value,
        otp: otp.value,
        ...authDeviceMeta(),
      },
    })
    const data = res?.data ?? res ?? {}
    if (data.token) {
      const sanctum = useSanctumAppConfig()
      await sanctum?.tokenStorage?.set?.(useNuxtApp(), data.token)
    }
    persistTokenId(data.token_id)
    await refreshIdentity()
    navigateTo(redirectTarget.value)
  } catch (error) {
    const normalized = normalizeApiError(error)
    errors.value = normalized.errors
    formError.value = Object.keys(normalized.errors).length ? '' : normalized.message
    otp.value = ''
  } finally {
    loading.value = false
  }
}

const resend = async () => {
  if (cooldown.value > 0 || resending.value) return
  errors.value = {}
  formError.value = ''
  resending.value = true
  try {
    await client('/api/login', {
      method: 'POST',
      body: { identifier: identifier.value, type: identifierType.value },
    })
    startCooldown()
  } catch (error) {
    const normalized = normalizeApiError(error)
    errors.value = normalized.errors
    formError.value = Object.keys(normalized.errors).length ? '' : normalized.message
  } finally {
    resending.value = false
  }
}
</script>
