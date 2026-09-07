<template>
  <AuthScreen
    :title="t('reset_password', 'Change password', 'تغيير كلمة السر')"
    :subtitle="t('reset_password_description', 'You can now set a new password for your account.', 'الآن يمكنك كتابة كلمة السر الجديدة لحسابك.')"
  >
    <form class="flex flex-col gap-5" @submit.prevent="onSubmit">
      <div class="grid gap-2">
        <Label for="password">{{ t('new_password', 'New password', 'كلمة مرور جديدة') }}</Label>
        <AuthPasswordInput id="password" v-model="form.password" required />
        <span v-if="errors.password" class="text-xs text-destructive">{{ errors.password[0] }}</span>
      </div>
      <div class="grid gap-2">
        <Label for="confirm">{{ t('confirm_password', 'Confirm password', 'تأكيد كلمة المرور') }}</Label>
        <AuthPasswordInput id="confirm" v-model="form.password_confirmation" required />
        <span v-if="errors.password_confirmation" class="text-xs text-destructive">{{ errors.password_confirmation[0] }}</span>
      </div>
      <span v-if="errors.otp" class="text-xs text-destructive">{{ errors.otp[0] }}</span>
      <span v-if="errors.identifier" class="text-xs text-destructive">{{ errors.identifier[0] }}</span>
      <Button
        type="submit"
        size="lg"
        class="h-13 w-full rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
        :disabled="loading"
      >
        {{ loading ? t('updating', 'Updating...', 'جارٍ التحديث...') : t('update_password', 'Change', 'تغيير') }}
      </Button>
    </form>
  </AuthScreen>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-pre-auth', 'password-mode-only'],
  name: 'forgot-password-reset'
})

const route = useRoute()
const errors = ref({})
const loading = ref(false)
const client = useApi()
const { t } = useLang('web', 'auth')

const form = ref({
  identifier: route.query.identifier?.toString() ?? '',
  type: route.query.type?.toString() ?? '',
  otp: route.query.otp?.toString() ?? '',
  password: '',
  password_confirmation: ''
})

if (!form.value.identifier || !form.value.otp) {
  navigateTo({ name: 'forgot-password' })
}

const onSubmit = async () => {
  errors.value = {}
  loading.value = true
  try {
    await client('/api/change-forgot-password', {
      method: 'POST',
      body: form.value
    })
    navigateTo({ name: 'login' })
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    loading.value = false
  }
}
</script>
