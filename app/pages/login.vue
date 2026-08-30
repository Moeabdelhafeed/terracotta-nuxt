<template>
  <div class="relative flex min-h-svh items-center justify-center bg-muted/40 p-6 pb-20">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <AppMedia
          v-if="logo"
          :src="logo"
          alt="Logo"
          class="mb-2 h-12 w-auto self-start object-contain"
        />
        <CardTitle class="text-2xl">{{ appUsers ? t('login_title', 'Login', 'تسجيل الدخول') : t('welcome', 'Welcome', 'مرحبًا') }}</CardTitle>
        <CardDescription>
          {{ appUsers
            ? t('login_description', 'Enter your :field below to sign in.', 'أدخل :field للدخول.', { field: identifierLabel.toLowerCase() })
            : t('guest_only_description', 'You are browsing as a guest.', 'أنت تتصفح كزائر.') }}
        </CardDescription>
      </CardHeader>
      <CardContent v-if="appUsers">
        <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
          <div v-if="identifierTypes.length > 1" class="flex gap-2">
            <Button
              v-for="kind in identifierTypes"
              :key="kind"
              type="button"
              size="sm"
              :variant="identifierType === kind ? 'default' : 'outline'"
              @click="identifierType = kind"
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
            <span
              v-if="checking"
              class="text-xs text-muted-foreground"
            >{{ t('checking', 'Checking...', 'جارٍ التحقق...') }}</span>
            <span
              v-else-if="identifierStatus === 'missing'"
              class="text-xs text-red-500"
            >{{ t('no_account_with_identifier', 'No account with this :field.', 'لا يوجد حساب بهذا الـ:field.', { field: identifierLabel.toLowerCase() }) }}</span>
            <span
              v-else-if="identifierStatus === 'suspended'"
              class="text-xs text-red-500"
            >{{ t('account_suspended', 'Account suspended. Contact support.', 'الحساب موقوف. تواصل مع الدعم.') }}</span>
            <span
              v-else-if="identifierStatus === 'pending_deletion'"
              class="text-xs text-amber-600"
            >{{ t('account_pending_deletion_hint', 'Account scheduled for deletion. Log in to restore.', 'الحساب مجدول للحذف. سجّل الدخول لاستعادته.') }}</span>
            <span
              v-else-if="identifierStatus === 'active'"
              class="text-xs text-green-600"
            >{{ t('account_found', 'Account found.', 'تم العثور على الحساب.') }}</span>
            <span
              v-if="identifierStatus === 'active' && linkedProviders.length"
              class="text-xs text-muted-foreground"
            >
              {{ t('account_linked_to', 'Linked to: :providers', 'مربوط بـ: :providers', { providers: linkedProviders.map(providerLabel).join(', ') }) }}
            </span>
            <span
              v-if="identifierStatus === 'active' && !hasPasswordOnAccount"
              class="text-xs text-amber-600"
            >
              {{ t('no_password_use_social', 'No password set. Use a social provider below.', 'لا توجد كلمة مرور. استخدم مزوّدًا اجتماعيًا أدناه.') }}
            </span>
            <span v-if="errors.identifier" class="text-xs text-red-500">{{ errors.identifier[0] }}</span>
          </div>
          <div v-if="isOtpMode && identifierStatus === 'missing'" class="grid gap-2">
            <Label for="name">{{ t('name', 'Name', 'الاسم') }}</Label>
            <Input id="name" v-model="form.name" type="text" :placeholder="t('placeholder_name', 'John Doe', 'محمد أحمد')" required />
            <span v-if="errors.name" class="text-xs text-red-500">{{ errors.name[0] }}</span>
          </div>
          <p v-if="errors.device_id" class="text-xs text-red-500">{{ errors.device_id[0] }}</p>
          <p v-if="errors.platform" class="text-xs text-red-500">{{ errors.platform[0] }}</p>
          <p v-if="errors.fcm_token" class="text-xs text-red-500">{{ errors.fcm_token[0] }}</p>
          <div v-if="!isOtpMode" class="grid gap-2">
            <div class="flex items-center justify-between">
              <Label for="password">{{ t('password', 'Password', 'كلمة المرور') }}</Label>
              <NuxtLink
                to="/forgot-password"
                class="text-xs text-muted-foreground underline-offset-4 hover:underline"
              >{{ t('forgot_password', 'Forgot password?', 'نسيت كلمة المرور؟') }}</NuxtLink>
            </div>
            <Input id="password" v-model="form.password" type="password" required />
            <span v-if="errors.password" class="text-xs text-red-500">{{ errors.password[0] }}</span>
          </div>
          <Button
            type="submit"
            class="w-full"
            :disabled="submitDisabled"
          >{{ submitLabel }}</Button>
        </form>
      </CardContent>
      <CardContent v-if="appUsers && socialAuthAvailable && socialProviders.length" class="flex flex-col gap-3">
        <div class="flex items-center gap-2">
          <span class="h-px flex-1 bg-border" />
          <span class="text-xs text-muted-foreground">
            {{ t('or_continue_with', 'Or continue with', 'أو المتابعة عبر') }}
          </span>
          <span class="h-px flex-1 bg-border" />
        </div>
        <SocialAuthButtons
          :providers="socialProviders"
          :loading="loading"
          @select="onSocial"
        />
        <span v-if="socialError" class="text-xs text-red-500">{{ socialError }}</span>
      </CardContent>
      <CardFooter v-if="appUsers && !isOtpMode" class="justify-center text-sm">
        <span class="text-muted-foreground">{{ t('no_account', 'No account?', 'ليس لديك حساب؟') }}&nbsp;</span>
        <NuxtLink
          to="/register"
          class="font-medium underline-offset-4 hover:underline"
        >{{ t('register', 'Register', 'إنشاء حساب') }}</NuxtLink>
      </CardFooter>
    </Card>

    <Teleport to="body">
      <div
        v-if="restoreDialogOpen"
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        role="dialog"
        aria-modal="true"
      >
        <div
          class="absolute inset-0 bg-black/50"
          @click="loading || (restoreDialogOpen = false)"
        />
        <div class="relative w-full max-w-md rounded-lg border bg-background p-6 shadow-lg">
          <h2 class="text-lg font-semibold">
            {{ t('account_pending_deletion_title', 'Restore account?', 'استعادة الحساب؟') }}
          </h2>
          <p class="mt-2 text-sm text-muted-foreground">
            {{ t('account_pending_deletion_body', 'This account is scheduled for deletion. Logging in will restore it.', 'هذا الحساب مجدول للحذف. تسجيل الدخول سيستعيده.') }}
          </p>
          <div class="mt-6 flex justify-end gap-2">
            <Button variant="outline" :disabled="loading" @click="restoreDialogOpen = false">
              {{ t('cancel', 'Cancel', 'إلغاء') }}
            </Button>
            <Button :disabled="loading" @click="confirmRestore">
              {{ loading ? t('signing_in', 'Signing in...', 'جارٍ تسجيل الدخول...') : t('restore_and_login', 'Restore & log in', 'استعادة وتسجيل الدخول') }}
            </Button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
definePageMeta({
  middleware: ['require-pre-auth'],
  name: 'login'
})

const { identifierLabel, identifierInputType, identifierPlaceholder, identifierTypes, defaultIdentifierType, labelFor, socialAuthAvailable, socialProviders, appUsers, isOtpMode } = useAuthConfig()

// Which kind of identifier the box holds. Sent on every request — the API rejects a
// value that does not match its declared type instead of guessing from the string.
const identifierType = ref(defaultIdentifierType.value)
watch(identifierTypes, (list) => {
  if (list.length && !list.includes(identifierType.value)) identifierType.value = list[0]
}, { immediate: true })
const { t } = useLang('web', 'auth')

const { mediaAsset } = useMedia('web', 'branding')
const logo = computed(() => mediaAsset('logo', '/logo.png'))

const errors = ref({})
const loading = ref(false)
const checking = ref(false)
const identifierStatus = ref(null) // 'missing' | 'active' | 'pending_deletion' | 'suspended'
const identifierMeta = ref({ has_password: true, social_providers: [], verified: false, is_guest: false })
const restoreDialogOpen = ref(false)
const socialError = ref('')

const linkedProviders = computed(() => identifierMeta.value.social_providers ?? [])
const hasPasswordOnAccount = computed(() => identifierMeta.value.has_password !== false)
const providerLabel = (p) => ({
  'google.com': 'Google',
  'apple.com': 'Apple',
  'facebook.com': 'Facebook',
  'twitter.com': 'Twitter',
  'github.com': 'GitHub',
  'microsoft.com': 'Microsoft',
  'yahoo.com': 'Yahoo',
}[p] ?? p)

const client = useApi()
const form = ref({ identifier: '', password: '', name: '' })

const submitDisabled = computed(() => {
  if (loading.value) return true
  if (identifierStatus.value === 'suspended') return true
  if (isOtpMode.value) {
    if (identifierStatus.value === 'missing' && !form.value.name) return true
    return false
  }
  if (identifierStatus.value === 'missing') return true
  if (identifierStatus.value === 'active' && !hasPasswordOnAccount.value) return true
  return false
})

const submitLabel = computed(() => {
  if (loading.value) return isOtpMode.value
    ? t('sending', 'Sending...', 'جارٍ الإرسال...')
    : t('signing_in', 'Signing in...', 'جارٍ تسجيل الدخول...')
  return isOtpMode.value
    ? t('send_code', 'Send code', 'إرسال الرمز')
    : t('sign_in', 'Sign in', 'تسجيل الدخول')
})

const { user, login, refreshIdentity } = useSanctumAuth()

const clearGuestUser = () => {
  if (user.value?.data?.is_guest) user.value = null
}

const persistTokenId = (tokenId) => {
  if (tokenId == null || !import.meta.client) return
  document.cookie = `current_token_id=${tokenId}; path=/; SameSite=Lax; max-age=${60 * 60 * 24 * 365}`
}





const detectDeviceMeta = () => {
  if (!import.meta.client) return { device_name: 'Web', platform: 'web' }
  const ua = navigator.userAgent || ''
  const uaData = navigator.userAgentData
  const browser = uaData?.brands?.find((b) => !/Not.?A.?Brand/i.test(b.brand))?.brand
    ?? (/Edg\//.test(ua) ? 'Edge'
      : /Chrome\//.test(ua) ? 'Chrome'
      : /Firefox\//.test(ua) ? 'Firefox'
      : /Safari\//.test(ua) ? 'Safari'
      : 'Browser')
  const os = uaData?.platform
    ?? (/Windows/.test(ua) ? 'Windows'
      : /Mac OS X|Macintosh/.test(ua) ? 'Mac'
      : /Android/.test(ua) ? 'Android'
      : /iPhone|iPad|iOS/.test(ua) ? 'iOS'
      : /Linux/.test(ua) ? 'Linux'
      : 'Unknown')
  return { device_name: `${browser} on ${os}`, platform: 'web' }
}

let debounce = null

watch(() => form.value.identifier, (val) => {
  identifierStatus.value = null
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
        body: { identifier: val, type: identifierType.value }
      })
      const data = res?.data ?? res ?? {}
      identifierMeta.value = {
        has_password: data.has_password !== false,
        social_providers: Array.isArray(data.social_providers) ? data.social_providers : [],
        verified: !!data.verified,
        is_guest: !!data.is_guest,
      }
      if (!data.exists) identifierStatus.value = 'missing'
      else if (data.suspended) identifierStatus.value = 'suspended'
      else if (data.pending_deletion) identifierStatus.value = 'pending_deletion'
      else identifierStatus.value = 'active'
    } catch {
      identifierStatus.value = null
      identifierMeta.value = { has_password: true, social_providers: [], verified: false, is_guest: false }
    } finally {
      checking.value = false
    }
  }, 500)
})

onUnmounted(() => {
  if (debounce) clearTimeout(debounce)
})

const performLogin = async () => {
  errors.value = {}
  loading.value = true
  try {
    clearGuestUser()
    const res = await login({ ...form.value, type: identifierType.value, ...detectDeviceMeta() }, true)
    persistTokenId(res?.data?.token_id ?? res?.token_id)
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    loading.value = false
  }
}

const performOtpRequest = async () => {
  errors.value = {}
  loading.value = true
  try {
    const body = { identifier: form.value.identifier, type: identifierType.value }
    if (identifierStatus.value === 'missing' && form.value.name) body.name = form.value.name
    await client('/api/login', { method: 'POST', body })
    navigateTo({ path: '/verify-login', query: { identifier: form.value.identifier, type: identifierType.value } })
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    loading.value = false
  }
}

const onSubmit = () => {
  if (identifierStatus.value === 'suspended') return
  if (isOtpMode.value) {
    performOtpRequest()
    return
  }
  if (identifierStatus.value === 'pending_deletion') {
    restoreDialogOpen.value = true
    return
  }
  performLogin()
}

const confirmRestore = async () => {
  await performLogin()
  restoreDialogOpen.value = false
}

const onSocial = async ({ idToken, error }) => {
  socialError.value = ''
  if (error) {
    socialError.value = error.message ?? String(error)
    return
  }
  loading.value = true
  try {
    const res = await client('/api/firebase-login', {
      method: 'POST',
      body: { token: idToken, ...detectDeviceMeta() },
    })
    const token = res?.data?.token ?? res?.token
    if (token) {
      const sanctum = useSanctumAppConfig()
      await sanctum?.tokenStorage?.set?.(useNuxtApp(), token)
    }
    persistTokenId(res?.data?.token_id ?? res?.token_id)
    await refreshIdentity()
    navigateTo({ name: 'home' })
  } catch (err) {
    const tokenErr = err?.data?.errors?.token?.[0]
    const map = {
      account_exists_use_password: t('err_account_exists_use_password', 'An account with this email exists. Use password to log in.', 'يوجد حساب بهذا البريد. استخدم كلمة المرور.'),
      social_max_accounts_reached: t('err_social_max_accounts_reached', 'Maximum linked accounts reached.', 'تم بلوغ الحد الأقصى للحسابات المربوطة.'),
      social_provider_not_allowed: t('err_social_provider_not_allowed', 'This provider is not allowed.', 'هذا المزوّد غير مسموح.'),
      invalid_firebase_token: t('err_invalid_firebase_token', 'Invalid sign-in token. Try again.', 'رمز الدخول غير صالح. حاول مجددًا.'),
      firebase_email_required: t('err_firebase_email_required', 'No email returned from provider.', 'لم يتم إرجاع بريد من المزوّد.'),
      social_auth_requires_email: t('err_social_auth_requires_email', 'Social login requires an email-based account.', 'يتطلب تسجيل الدخول الاجتماعي حسابًا بريدًا.'),
    }
    socialError.value = map[tokenErr] ?? tokenErr ?? err?.data?.message ?? err?.message ?? String(err)
  } finally {
    loading.value = false
  }
}
</script>
