<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/40 p-6">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle class="text-2xl">{{ t('verify_otp', 'Verify OTP', 'تأكيد الرمز') }}</CardTitle>
        <CardDescription>
          {{ t('enter_otp_sent_to', 'Enter the OTP sent to :target.', 'أدخل الرمز المرسل إلى :target.', { target: user?.data?.email }) }}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
          <div class="grid gap-2">
            <Label for="otp">{{ t('otp', 'OTP', 'الرمز') }}</Label>
            <Input id="otp" v-model="otp" type="text" inputmode="numeric" placeholder="123456" required />
            <span v-if="errors.otp" class="text-red-500">{{ errors.otp[0] }}</span>
          </div>
          <Button type="submit" class="w-full" :disabled="loading || resending">
            {{ loading ? t('verifying', 'Verifying...', 'جارٍ التحقق...') : t('verify', 'Verify', 'تحقق') }}
          </Button>
        </form>
      </CardContent>
      <CardFooter class="flex flex-col items-center gap-3 text-sm">
        <button
          type="button"
          class="font-medium underline-offset-4 hover:underline disabled:cursor-not-allowed disabled:opacity-50 disabled:no-underline"
          :disabled="cooldown > 0 || resending || loading"
          @click="resend"
        >
          {{ resending ? t('sending', 'Sending...', 'جارٍ الإرسال...') : (cooldown > 0 ? t('resend_in_seconds', 'Resend in :seconds s', 'إعادة الإرسال خلال :seconds ث', { seconds: cooldown }) : t('resend_otp', 'Resend OTP', 'إعادة إرسال الرمز')) }}
        </button>
        <Button
          variant="outline"
          size="sm"
          :disabled="loggingOut || loading || resending"
          @click="handleLogout"
        >{{ loggingOut ? t('logging_out', 'Logging out...', 'جارٍ تسجيل الخروج...') : t('logout', 'Logout', 'تسجيل الخروج') }}</Button>
      </CardFooter>
    </Card>
  </div>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'unverified'],
  name: 'verify'
})

const RESEND_COOLDOWN = 120

const errors = ref({})
const loading = ref(false)
const resending = ref(false)
const client = useApi()
const { user, refreshIdentity, logout } = useSanctumAuth()
const { t } = useLang('web', 'auth')

const otp = ref('')
const cooldown = ref(0)
const loggingOut = ref(false)
let timer = null

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

onUnmounted(() => {
  if (timer) clearInterval(timer)
})

const onSubmit = async () => {
  errors.value = {}
  loading.value = true
  try {
    await client('/api/verify-otp', {
      method: 'POST',
      body: { identifier: user.value?.data?.email, otp: otp.value }
    })

    await refreshIdentity()
    navigateTo({ name: 'home' })
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    loading.value = false
  }
}

const resend = async () => {
  if (cooldown.value > 0 || resending.value) return
  errors.value = {}
  resending.value = true
  try {
    await client('/api/send-otp', {
      method: 'POST',
      body: { identifier: user.value?.data?.email }
    })
    startCooldown()
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    resending.value = false
  }
}
</script>
