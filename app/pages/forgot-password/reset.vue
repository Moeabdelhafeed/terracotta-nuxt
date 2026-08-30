<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/40 p-6">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle class="text-2xl">{{ t('reset_password', 'Reset password', 'إعادة تعيين كلمة المرور') }}</CardTitle>
        <CardDescription>{{ t('reset_password_description', 'Set a new password for your account.', 'عيّن كلمة مرور جديدة لحسابك.') }}</CardDescription>
      </CardHeader>
      <CardContent>
        <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
          <div class="grid gap-2">
            <Label for="password">{{ t('new_password', 'New password', 'كلمة مرور جديدة') }}</Label>
            <Input id="password" v-model="form.password" type="password" required />
            <span v-if="errors.password" class="text-red-500">{{ errors.password[0] }}</span>
          </div>
          <div class="grid gap-2">
            <Label for="confirm">{{ t('confirm_password', 'Confirm password', 'تأكيد كلمة المرور') }}</Label>
            <Input id="confirm" v-model="form.password_confirmation" type="password" required />
            <span v-if="errors.password_confirmation" class="text-red-500">{{ errors.password_confirmation[0] }}</span>
          </div>
          <span v-if="errors.otp" class="text-red-500">{{ errors.otp[0] }}</span>
          <span v-if="errors.identifier" class="text-red-500">{{ errors.identifier[0] }}</span>
          <Button type="submit" class="w-full" :disabled="loading">
            {{ loading ? t('updating', 'Updating...', 'جارٍ التحديث...') : t('update_password', 'Update password', 'تحديث كلمة المرور') }}
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
