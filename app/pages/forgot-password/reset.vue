<template>
  <AuthScreen
    :back="{ name: 'forgot-password-verify', query: { identifier: form.identifier, type: form.type } }"
    :title="t('reset_password', 'Change password', 'تغيير كلمة السر')"
    :subtitle="t('reset_password_description', 'You can now set a new password for your account.', 'الآن يمكنك كتابة كلمة السر الجديدة لحسابك.')"
  >
    <form class="flex flex-col gap-5" @submit.prevent="onSubmit">
      <div class="grid gap-2">
        <Label for="password">{{ t('new_password', 'New password', 'كلمة مرور جديدة') }}</Label>
        <AuthPasswordInput id="password" v-model="form.password" required minlength="8" />
        <span v-if="errors.password" class="text-xs text-destructive">{{ errors.password[0] }}</span>
      </div>
      <div class="grid gap-2">
        <Label for="confirm">{{ t('confirm_password', 'Confirm password', 'تأكيد كلمة المرور') }}</Label>
        <AuthPasswordInput id="confirm" v-model="form.password_confirmation" required minlength="8" />
        <span v-if="errors.password_confirmation" class="text-xs text-destructive">{{ errors.password_confirmation[0] }}</span>
      </div>
      <span v-if="errors.otp" class="text-xs text-destructive">{{ errors.otp[0] }}</span>
      <span v-if="errors.identifier" class="text-xs text-destructive">{{ errors.identifier[0] }}</span>
      <Button
        type="submit"
        size="lg"
        class="h-13 w-full rounded-control bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
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
const { user, login } = useSanctumAuth()

const redirectTarget = computed(() => safeAuthRedirect(route.query.redirect))

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
  if (form.value.password !== form.value.password_confirmation) {
    errors.value = {
      password_confirmation: [t('password_mismatch', 'The two passwords do not match.', 'كلمتا المرور غير متطابقتين.')]
    }
    return
  }
  loading.value = true
  try {
    await client('/api/change-forgot-password', {
      method: 'POST',
      body: form.value
    })
  } catch (error) {
    errors.value = error.data?.errors ?? {}
    // A code that expired between the screen before this one and this submit comes back
    // under `otp` — a field that lives on that screen. Staying here is a form that can
    // never pass; send them back to where a fresh code is one press away.
    if (errors.value.otp) {
      navigateTo({
        name: 'forgot-password-verify',
        query: {
          identifier: form.value.identifier,
          type: form.value.type,
          expired: '1',
          ...(redirectTarget.value === '/' ? {} : { redirect: redirectTarget.value })
        }
      })
    }
    loading.value = false
    return
  }

  // Changing the password does not start a session, so this signs them in with the one
  // they just chose rather than asking them to type it again on the screen behind this.
  try {
    if (user.value?.data?.is_guest) user.value = null
    await login({
      identifier: form.value.identifier,
      type: form.value.type,
      password: form.value.password,
      ...authDeviceMeta()
    })
    // `redirect.onLogin` is off, so the destination is this page's to name.
    await navigateTo(redirectTarget.value, { replace: true })
  } catch {
    // The password DID change; only the convenience sign-in failed. Signing in by hand
    // is honest — saying the reset failed would not be.
    navigateTo({ name: 'login', query: redirectTarget.value === '/' ? {} : { redirect: redirectTarget.value } })
  } finally {
    loading.value = false
  }
}
</script>
