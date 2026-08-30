<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/40 p-6">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle class="text-2xl">{{ t('forgot_password_title', 'Forgot password', 'نسيت كلمة المرور') }}</CardTitle>
        <CardDescription>{{ t('forgot_password_description', 'Enter your identifier to receive an OTP.', 'أدخل المعرّف لتلقي الرمز.') }}</CardDescription>
      </CardHeader>
      <CardContent>
        <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
          <div v-if="identifierTypes.length > 1" class="flex gap-2">
            <Button
              v-for="kind in identifierTypes"
              :key="kind"
              type="button"
              size="sm"
              :variant="form.type === kind ? 'default' : 'outline'"
              @click="form.type = kind"
            >{{ labelFor(kind) }}</Button>
          </div>

          <div class="grid gap-2">
            <Label for="identifier">{{ identifierLabel }}</Label>
            <Input
              id="identifier"
              v-model="form.identifier"
              :type="identifierInputType"
              :placeholder="identifierPlaceholder"
              required
            />
            <span v-if="checking" class="text-xs text-muted-foreground">{{ t('checking', 'Checking...', 'جارٍ التحقق...') }}</span>
            <span v-else-if="exists === false" class="text-xs text-red-500">{{ t('no_account_with_identifier_generic', 'No account with this identifier.', 'لا يوجد حساب بهذا المعرّف.') }}</span>
            <span v-else-if="exists === true && availableChannels.length === 0" class="text-xs text-red-500">{{ t('no_delivery_channel', 'No delivery channel available.', 'لا توجد قناة إرسال متاحة.') }}</span>
            <span v-if="errors.identifier" class="text-xs text-red-500">{{ errors.identifier[0] }}</span>
          </div>

          <div v-if="exists && availableChannels.length > 1" class="grid gap-2">
            <Label>{{ t('send_otp_via', 'Send OTP via', 'إرسال الرمز عبر') }}</Label>
            <div class="flex gap-2">
              <Button
                v-for="ch in availableChannels"
                :key="ch"
                type="button"
                size="sm"
                :variant="form.channel === ch ? 'default' : 'outline'"
                @click="form.channel = ch"
              >
                {{ t(`channel_${ch}`, ch) }}
              </Button>
            </div>
            <span v-if="errors.type" class="text-xs text-red-500">{{ errors.type[0] }}</span>
          </div>

          <Button type="submit" class="w-full" :disabled="loading || checking || exists === false || (exists && availableChannels.length === 0)">
            {{ loading ? t('sending', 'Sending...', 'جارٍ الإرسال...') : t('send_otp', 'Send OTP', 'إرسال الرمز') }}
          </Button>
        </form>
      </CardContent>
      <CardFooter class="justify-center text-sm">
        <NuxtLink to="/login" class="font-medium underline-offset-4 hover:underline">{{ t('back_to_login', 'Back to login', 'العودة لتسجيل الدخول') }}</NuxtLink>
      </CardFooter>
    </Card>
  </div>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-pre-auth', 'password-mode-only'],
  name: 'forgot-password'
})

const { identifierLabel, identifierInputType, identifierPlaceholder, identifierTypes, defaultIdentifierType, labelFor } = useAuthConfig()
const { t } = useLang('web', 'auth')

const errors = ref({})
const loading = ref(false)
const checking = ref(false)
const exists = ref(null)
const availableChannels = ref([])
const client = useApi()
// `type` = which kind of identifier was typed (declared, never guessed).
// `channel` = where the reset code should be sent, when the account has both.
const form = ref({ identifier: '', type: defaultIdentifierType.value, channel: '' })

watch(identifierTypes, (list) => {
  if (list.length && !list.includes(form.value.type)) form.value.type = list[0]
}, { immediate: true })

let debounce = null

watch(() => form.value.identifier, (val) => {
  exists.value = null
  availableChannels.value = []
  form.value.channel = ''
  if (debounce) clearTimeout(debounce)
  if (!val || val.length < 3) {
    checking.value = false
    return
  }
  checking.value = true
  debounce = setTimeout(async () => {
    try {
      const res = await client('/api/check-identifier', {
        method: 'POST',
        body: { identifier: val, type: form.value.type }
      })
      const data = res?.data ?? res ?? {}
      exists.value = !!data.exists
      availableChannels.value = data.available_channels ?? []
      if (availableChannels.value.length === 1) {
        form.value.channel = availableChannels.value[0]
      }
    } catch {
      exists.value = null
      availableChannels.value = []
    } finally {
      checking.value = false
    }
  }, 500)
})

onUnmounted(() => {
  if (debounce) clearTimeout(debounce)
})

const onSubmit = async () => {
  errors.value = {}
  loading.value = true
  try {
    const body = { identifier: form.value.identifier, type: form.value.type }
    if (form.value.channel) body.channel = form.value.channel
    await client('/api/forgot-password', {
      method: 'POST',
      body
    })
    navigateTo({
      name: 'forgot-password-verify',
      query: { identifier: form.value.identifier, type: form.value.type }
    })
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    loading.value = false
  }
}
</script>
