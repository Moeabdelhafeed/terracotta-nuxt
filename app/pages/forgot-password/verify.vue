<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/40 p-6">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle class="text-2xl">{{ t('verify_otp', 'Verify OTP', 'تأكيد الرمز') }}</CardTitle>
        <CardDescription>
          {{ t('enter_otp_sent_to', 'Enter the OTP sent to :target.', 'أدخل الرمز المرسل إلى :target.', { target: form.identifier }) }}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
          <div class="grid gap-2">
            <Label for="otp">{{ t('otp', 'OTP', 'الرمز') }}</Label>
            <Input id="otp" v-model="form.otp" type="text" inputmode="numeric" placeholder="123456" required />
            <span v-if="errors.otp" class="text-red-500">{{ errors.otp[0] }}</span>
            <span v-if="errors.identifier" class="text-red-500">{{ errors.identifier[0] }}</span>
          </div>
          <Button type="submit" class="w-full" :disabled="loading || resending">
            {{ loading ? t('verifying', 'Verifying...', 'جارٍ التحقق...') : t('verify', 'Verify', 'تحقق') }}
          </Button>
        </form>
      </CardContent>
      <CardFooter class="justify-center text-sm">
        <button
          type="button"
          class="font-medium underline-offset-4 hover:underline disabled:cursor-not-allowed disabled:opacity-50"
          :disabled="cooldown > 0 || resending || loading"
          @click="resend"
        >
          {{ resending ? t('sending', 'Sending...', 'جارٍ الإرسال...') : (cooldown > 0 ? t('resend_in_seconds', 'Resend in :seconds s', 'إعادة الإرسال خلال :seconds ث', { seconds: cooldown }) : t('resend_otp', 'Resend OTP', 'إعادة إرسال الرمز')) }}
        </button>
      </CardFooter>
    </Card>
  </div>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-pre-auth', 'password-mode-only'],
  name: 'forgot-password-verify'
})

const RESEND_COOLDOWN = 120

const route = useRoute()
const errors = ref({})
const loading = ref(false)
const resending = ref(false)
const client = useApi()
const { t } = useLang('web', 'auth')

const form = ref({
  identifier: route.query.identifier?.toString() ?? '',
  // Carried through the flow so every step declares the same identifier kind.
  type: route.query.type?.toString() ?? '',
  otp: ''
})

if (!form.value.identifier) {
  navigateTo({ name: 'forgot-password' })
}

const cooldown = ref(0)
let timer = null

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
    await client('/api/verify-forgot-password-otp', {
      method: 'POST',
      body: form.value
    })
    navigateTo({
      name: 'forgot-password-reset',
      query: { identifier: form.value.identifier, type: form.value.type, otp: form.value.otp }
    })
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
    await client('/api/forgot-password', {
      method: 'POST',
      body: { identifier: form.value.identifier, type: form.value.type }
    })
    startCooldown()
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    resending.value = false
  }
}
</script>
