<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/40 p-6">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle class="text-2xl">{{ t('verify_login_title', 'Enter code', 'أدخل الرمز') }}</CardTitle>
        <CardDescription>
          {{ t('enter_otp_sent_to', 'Enter the OTP sent to :target.', 'أدخل الرمز المرسل إلى :target.', { target: identifier }) }}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
          <div class="grid gap-2">
            <Label for="otp">{{ t('otp', 'OTP', 'الرمز') }}</Label>
            <Input id="otp" v-model="otp" type="text" inputmode="numeric" placeholder="123456" required />
            <span v-if="errors.otp" class="text-xs text-red-500">{{ errors.otp[0] }}</span>
            <span v-if="errors.identifier" class="text-xs text-red-500">{{ errors.identifier[0] }}</span>
          </div>
          <p v-if="restoredNotice" class="text-xs text-green-600">
            {{ t('account_restored', 'Account restored.', 'تم استعادة الحساب.') }}
          </p>
          <p v-if="errors.device_id" class="text-xs text-red-500">{{ errors.device_id[0] }}</p>
          <p v-if="errors.platform" class="text-xs text-red-500">{{ errors.platform[0] }}</p>
          <p v-if="errors.fcm_token" class="text-xs text-red-500">{{ errors.fcm_token[0] }}</p>
          <Button type="submit" class="w-full" :disabled="loading || resending">
            {{ loading ? t('verifying', 'Verifying...', 'جارٍ التحقق...') : t('verify', 'Verify', 'تحقق') }}
          </Button>
        </form>
      </CardContent>
      <CardFooter class="justify-center text-sm">
        <button
          type="button"
          class="font-medium underline-offset-4 hover:underline disabled:cursor-not-allowed disabled:opacity-50 disabled:no-underline"
          :disabled="cooldown > 0 || resending || loading"
          @click="resend"
        >
          {{ resending
            ? t('sending', 'Sending...', 'جارٍ الإرسال...')
            : (cooldown > 0
              ? t('resend_in_seconds', 'Resend in :seconds s', 'إعادة الإرسال خلال :seconds ث', { seconds: cooldown })
              : t('resend_otp', 'Resend OTP', 'إعادة إرسال الرمز')) }}
        </button>
      </CardFooter>
    </Card>
  </div>
</template>

<script setup>
definePageMeta({
  middleware: ['require-pre-auth'],
  name: 'verify-login'
})

const RESEND_COOLDOWN = 120

const route = useRoute()
const identifier = ref(String(route.query.identifier ?? ''))
const identifierType = ref(String(route.query.type ?? ''))
const otp = ref('')
const errors = ref({})
const loading = ref(false)
const resending = ref(false)
const restoredNotice = ref(false)
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

onUnmounted(() => {
  if (timer) clearInterval(timer)
})

const persistTokenId = (tokenId) => {
  if (tokenId == null || !import.meta.client) return
  document.cookie = `current_token_id=${tokenId}; path=/; SameSite=Lax; max-age=${60 * 60 * 24 * 365}`
}

const onSubmit = async () => {
  if (!identifier.value) {
    navigateTo({ name: 'login' })
    return
  }
  errors.value = {}
  restoredNotice.value = false
  loading.value = true
  try {
    if (user.value?.data?.is_guest) user.value = null
    const res = await client('/api/verify-login', {
      method: 'POST',
      body: { identifier: identifier.value, type: identifierType.value, otp: otp.value },
    })
    const data = res?.data ?? res ?? {}
    const token = data.token
    if (token) {
      const sanctum = useSanctumAppConfig()
      await sanctum?.tokenStorage?.set?.(useNuxtApp(), token)
    }
    persistTokenId(data.token_id)
    if (data.account_restored) restoredNotice.value = true
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
    await client('/api/login', { method: 'POST', body: { identifier: identifier.value, type: identifierType.value } })
    startCooldown()
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    resending.value = false
  }
}
</script>
