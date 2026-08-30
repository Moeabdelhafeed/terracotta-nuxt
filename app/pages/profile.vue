<template>
  <div class="min-h-svh bg-muted/40 p-6">
    <div class="mx-auto flex max-w-2xl flex-col gap-6">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold">{{ t('profile', 'Profile', 'الملف الشخصي') }}</h1>
          <p class="text-sm text-muted-foreground">{{ t('manage_your_account', 'Manage your account.', 'إدارة حسابك.') }}</p>
        </div>
        <div class="flex gap-2">
          <Button variant="outline" as-child>
            <NuxtLink to="/">{{ t('home', 'Home', 'الرئيسية') }}</NuxtLink>
          </Button>
          <Button v-if="multiSession" variant="outline" as-child>
            <NuxtLink to="/devices">{{ t('active_devices', 'Active devices', 'الأجهزة النشطة') }}</NuxtLink>
          </Button>
          <Button
            variant="destructive"
            :disabled="loggingOut"
            @click="handleLogout"
          >{{ loggingOut ? t('logging_out', 'Logging out...', 'جارٍ تسجيل الخروج...') : t('logout', 'Logout', 'تسجيل الخروج') }}</Button>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{{ t('account_info', 'Account info', 'معلومات الحساب') }}</CardTitle>
          <CardDescription>{{ t('account_info_description', 'Your current account record.', 'بيانات حسابك الحالية.') }}</CardDescription>
        </CardHeader>
        <CardContent>
          <div v-if="profile" class="flex flex-col gap-2 text-sm">
            <div
              v-for="[key, value] in entries"
              :key="key"
              class="flex justify-between gap-4 border-b pb-2 last:border-0"
            >
              <span
                class="font-medium capitalize text-muted-foreground"
              >{{ key.replace(/_/g, ' ') }}</span>
              <span class="text-right break-all">{{ formatValue(value) }}</span>
            </div>
          </div>
          <p v-else class="text-sm text-muted-foreground">{{ t('loading', 'Loading...', 'جارٍ التحميل...') }}</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{{ t('update_profile', 'Update profile', 'تحديث الملف') }}</CardTitle>
          <CardDescription>{{ t('update_profile_description', 'Change your account details.', 'غيّر بيانات حسابك.') }}</CardDescription>
        </CardHeader>
        <CardContent>
          <form class="flex flex-col gap-4" @submit.prevent="onUpdateProfile">
            <div class="grid gap-2">
              <Label for="name">{{ t('name', 'Name', 'الاسم') }}</Label>
              <Input id="name" v-model="profileForm.name" type="text" />
              <span
                v-if="profileErrors.name"
                class="text-xs text-red-500"
              >{{ profileErrors.name[0] }}</span>
            </div>

            <div v-if="hasUsername" class="grid gap-2">
              <Label for="profile_username">
                {{ labelFor('username') }}
                <span
                  v-if="!isExtraRequired('username')"
                  class="text-xs text-muted-foreground"
                >{{ t('optional', '(optional)', '(اختياري)') }}</span>
              </Label>
              <Input
                id="profile_username"
                v-model="profileForm.username"
                type="text"
                :placeholder="placeholderFor('username')"
              />
              <span
                v-if="profileErrors.username"
                class="text-xs text-red-500"
              >{{ profileErrors.username[0] }}</span>
            </div>

            <div v-if="hasEmail" class="grid gap-2">
              <Label for="profile_email">
                {{ labelFor('email') }}
                <span
                  v-if="!isExtraRequired('email')"
                  class="text-xs text-muted-foreground"
                >{{ t('optional', '(optional)', '(اختياري)') }}</span>
              </Label>
              <Input
                id="profile_email"
                v-model="profileForm.email"
                type="email"
                :placeholder="placeholderFor('email')"
              />
              <span
                v-if="profileErrors.email"
                class="text-xs text-red-500"
              >{{ profileErrors.email[0] }}</span>
            </div>

            <div v-if="hasPhone" class="grid gap-2">
              <Label for="profile_phone">
                {{ labelFor('phone') }}
                <span
                  v-if="!isExtraRequired('phone')"
                  class="text-xs text-muted-foreground"
                >{{ t('optional', '(optional)', '(اختياري)') }}</span>
              </Label>
              <Input
                id="profile_phone"
                v-model="profileForm.phone"
                type="tel"
                :placeholder="placeholderFor('phone')"
              />
              <span
                v-if="profileErrors.phone"
                class="text-xs text-red-500"
              >{{ profileErrors.phone[0] }}</span>
            </div>

            <p v-if="profileSaved" class="text-xs text-green-600">{{ t('saved', 'Saved.', 'تم الحفظ.') }}</p>
            <Button
              type="submit"
              :disabled="profileLoading"
            >{{ profileLoading ? t('saving', 'Saving...', 'جارٍ الحفظ...') : t('save_changes', 'Save changes', 'حفظ التغييرات') }}</Button>
          </form>
        </CardContent>
      </Card>

      <Card v-if="!isOtpMode">
        <CardHeader>
          <CardTitle>{{ hasPassword ? t('change_password', 'Change password', 'تغيير كلمة المرور') : t('set_password', 'Set password', 'تعيين كلمة المرور') }}</CardTitle>
          <CardDescription>{{ hasPassword ? t('change_password_description', 'Revokes all other sessions.', 'يلغي كل الجلسات الأخرى.') : t('set_password_description', 'Add a password so you can log in without a social provider.', 'أضف كلمة مرور لتسجيل الدخول بدون مزوّد اجتماعي.') }}</CardDescription>
        </CardHeader>
        <CardContent>
          <form class="flex flex-col gap-4" @submit.prevent="onChangePassword">
            <div v-if="hasPassword" class="grid gap-2">
              <Label for="old_password">{{ t('current_password', 'Current password', 'كلمة المرور الحالية') }}</Label>
              <Input
                id="old_password"
                v-model="passwordForm.old_password"
                type="password"
                required
              />
              <span
                v-if="passwordErrors.old_password"
                class="text-xs text-red-500"
              >{{ passwordErrors.old_password[0] }}</span>
            </div>
            <div class="grid gap-2">
              <Label for="new_password">{{ t('new_password', 'New password', 'كلمة مرور جديدة') }}</Label>
              <Input id="new_password" v-model="passwordForm.password" type="password" required />
              <span
                v-if="passwordErrors.password"
                class="text-xs text-red-500"
              >{{ passwordErrors.password[0] }}</span>
            </div>
            <div class="grid gap-2">
              <Label for="confirm_password">{{ t('confirm_password', 'Confirm password', 'تأكيد كلمة المرور') }}</Label>
              <Input
                id="confirm_password"
                v-model="passwordForm.password_confirmation"
                type="password"
                required
              />
              <span
                v-if="passwordErrors.password_confirmation"
                class="text-xs text-red-500"
              >{{ passwordErrors.password_confirmation[0] }}</span>
            </div>
            <p v-if="passwordSaved" class="text-xs text-green-600">{{ t('password_updated', 'Password updated.', 'تم تحديث كلمة المرور.') }}</p>
            <Button
              type="submit"
              :disabled="passwordLoading"
            >{{ passwordLoading ? t('updating', 'Updating...', 'جارٍ التحديث...') : t('update_password', 'Update password', 'تحديث كلمة المرور') }}</Button>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{{ t('change_kind', 'Change :kind', 'تغيير :kind', { kind: identifierKindLabel.toLowerCase() }) }}</CardTitle>
          <CardDescription>{{ t('change_kind_description', 'OTP-protected :kind change.', 'تغيير :kind محمي برمز.', { kind: identifierKindLabel.toLowerCase() }) }}</CardDescription>
        </CardHeader>
        <CardContent>
          <div class="flex flex-col gap-4">
            <div v-if="isMultiIdentifier" class="grid gap-2">
              <Label>{{ t('change_which', 'Change which', 'تغيير ماذا') }}</Label>
              <div class="flex flex-wrap gap-2">
                <Button
                  v-for="kind in identifiers"
                  :key="kind"
                  type="button"
                  size="sm"
                  :variant="identifierKind === kind ? 'default' : 'outline'"
                  @click="identifierKind = kind"
                >{{ labelFor(kind) }}</Button>
              </div>
            </div>
            <div class="grid gap-2">
              <Label for="new_identifier">{{ t('new_kind', 'New :kind', ':kind جديد', { kind: identifierKindLabel.toLowerCase() }) }}</Label>
              <Input
                id="new_identifier"
                v-model="identifierForm.new_identifier"
                :type="inputTypeFor(identifierKind)"
                :placeholder="placeholderFor(identifierKind)"
              />
              <span
                v-if="identifierErrors.new_identifier || identifierErrors.type"
                class="text-xs text-red-500"
              >{{ (identifierErrors.new_identifier ?? identifierErrors.type)[0] }}</span>
            </div>
            <Button
              :disabled="identifierLoading || otpSent"
              @click="onRequestIdentifierChange"
            >{{ identifierLoading ? t('sending', 'Sending...', 'جارٍ الإرسال...') : (otpSent ? t('otp_sent', 'OTP sent', 'تم إرسال الرمز') : t('send_otp', 'Send OTP', 'إرسال الرمز')) }}</Button>

            <div v-if="otpSent" class="flex flex-col gap-4 border-t pt-4">
              <div class="grid gap-2">
                <Label for="identifier_otp">{{ t('otp', 'OTP', 'الرمز') }}</Label>
                <Input
                  id="identifier_otp"
                  v-model="identifierForm.otp"
                  type="text"
                  inputmode="numeric"
                  placeholder="123456"
                />
                <span
                  v-if="identifierErrors.otp"
                  class="text-xs text-red-500"
                >{{ identifierErrors.otp[0] }}</span>
              </div>
              <p
                v-if="identifierSaved"
                class="text-xs text-green-600"
              >{{ t('kind_updated', ':kind updated.', 'تم تحديث :kind.', { kind: identifierKindLabel }) }}</p>
              <Button
                :disabled="identifierVerifying"
                @click="onVerifyIdentifierChange"
              >{{ identifierVerifying ? t('verifying', 'Verifying...', 'جارٍ التحقق...') : t('verify_and_save', 'Verify & save', 'تحقق واحفظ') }}</Button>
              <button
                type="button"
                class="text-xs text-muted-foreground underline-offset-4 hover:underline"
                @click="otpSent = false"
              >{{ t('cancel', 'Cancel', 'إلغاء') }}</button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card v-if="socialAuthAvailable && socialProviders.length">
        <CardHeader>
          <CardTitle>{{ t('social_accounts', 'Social accounts', 'الحسابات الاجتماعية') }}</CardTitle>
          <CardDescription>
            {{ t('manage_social_providers', 'Connect or disconnect providers linked to your account.', 'اربط أو افصل المزودين المرتبطين بحسابك.') }}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div class="flex flex-col gap-3">
            <p
              v-if="!hasPassword"
              class="rounded-md border border-amber-300 bg-amber-50 p-3 text-xs text-amber-800 dark:border-amber-700 dark:bg-amber-950 dark:text-amber-200"
            >
              {{ t('set_password_cta', 'Set a password to enable email/password login and to allow disconnecting your last social provider.', 'عيّن كلمة مرور لتفعيل تسجيل الدخول بالبريد/كلمة المرور وللسماح بفك ربط آخر مزوّد اجتماعي.') }}
            </p>
            <div v-if="socialLoading" class="text-sm text-muted-foreground">{{ t('loading', 'Loading...', 'جارٍ التحميل...') }}</div>
            <ul v-else class="flex flex-col gap-2">
              <li
                v-for="p in socialProviders"
                :key="p"
                class="flex items-center justify-between rounded-md border p-3 text-sm"
              >
                <div class="flex flex-col">
                  <span class="font-medium">{{ providerLabel(p) }}</span>
                  <span v-if="findLinked(p)" class="text-xs text-muted-foreground">{{ findLinked(p).email ?? findLinked(p).name }}</span>
                </div>
                <template v-if="findLinked(p)">
                  <Button
                    variant="outline"
                    size="sm"
                    :disabled="unlinking === p || (linkedProviders.length === 1 && !hasPassword)"
                    @click="onUnlinkSocial(p)"
                  >{{ unlinking === p ? t('unlinking', 'Unlinking...', 'جارٍ فك الربط...') : t('disconnect', 'Disconnect', 'فك الربط') }}</Button>
                </template>
                <template v-else>
                  <Button
                    variant="default"
                    size="sm"
                    :disabled="!canLinkMore || connecting === p"
                    @click="onConnectProvider(p)"
                  >{{ connecting === p ? t('connecting', 'Connecting...', 'جارٍ الربط...') : t('connect', 'Connect', 'ربط') }}</Button>
                </template>
              </li>
            </ul>
            <p
              v-if="!canLinkMore && maxSocialAccounts > 0"
              class="text-xs text-muted-foreground"
            >{{ t('linked_accounts_limit_reached', 'Linked accounts limit reached (:max).', 'تم بلوغ الحد الأقصى للحسابات المربوطة (:max).', { max: maxSocialAccounts }) }}</p>
            <span v-if="socialErrors.token" class="text-xs text-red-500">{{ socialErrorText('token') }}</span>
            <span v-if="socialErrors.provider" class="text-xs text-red-500">{{ socialErrorText('provider') }}</span>
          </div>
        </CardContent>
      </Card>

      <Card class="border-destructive">
        <CardHeader>
          <CardTitle class="text-destructive">{{ t('danger_zone', 'Danger zone', 'منطقة الخطر') }}</CardTitle>
          <CardDescription>{{ t('delete_account_description', 'Permanently delete your account.', 'حذف حسابك نهائيًا.') }}</CardDescription>
        </CardHeader>
        <CardContent>
          <Button
            variant="destructive"
            :disabled="deleting"
            @click="deleteDialogOpen = true"
          >{{ deleting ? t('deleting', 'Deleting...', 'جارٍ الحذف...') : t('delete_account', 'Delete account', 'حذف الحساب') }}</Button>
        </CardContent>
      </Card>
    </div>

    <Teleport to="body">
      <div
        v-if="deleteDialogOpen"
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        role="dialog"
        aria-modal="true"
      >
        <div
          class="absolute inset-0 bg-black/50"
          @click="deleting || (deleteDialogOpen = false)"
        />
        <div class="relative w-full max-w-md rounded-lg border bg-background p-6 shadow-lg">
          <h2 class="text-lg font-semibold text-destructive">
            {{ t('delete_account', 'Delete account', 'حذف الحساب') }}
          </h2>
          <p class="mt-2 text-sm text-muted-foreground">
            {{ t('delete_account_confirm', 'Permanently delete your account? This cannot be undone.', 'حذف الحساب نهائيًا؟ لا يمكن التراجع.') }}
          </p>
          <div class="mt-6 flex justify-end gap-2">
            <Button variant="outline" :disabled="deleting" @click="deleteDialogOpen = false">
              {{ t('cancel', 'Cancel', 'إلغاء') }}
            </Button>
            <Button variant="destructive" :disabled="deleting" @click="confirmDeleteAccount">
              {{ deleting ? t('deleting', 'Deleting...', 'جارٍ الحذف...') : t('delete_account', 'Delete account', 'حذف الحساب') }}
            </Button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'profile'
})

const { user, logout, refreshIdentity } = useSanctumAuth()
const client = useApi()
const {
  identifiers,
  isMultiIdentifier,
  hasUsername,
  hasEmail,
  hasPhone,
  isExtraRequired,
  labelFor,
  inputTypeFor,
  placeholderFor,
  socialAuthAvailable,
  socialProviders,
  maxSocialAccounts,
  multiSession,
  isOtpMode,
} = useAuthConfig()
const { t } = useLang('web', 'profile')
const { signInWithProvider } = useFirebaseAuth()

const identifierKind = ref(identifiers.value[0] ?? 'email')
watch(identifiers, (list) => {
  if (list.length && !list.includes(identifierKind.value)) {
    identifierKind.value = list[0]
  }
}, { immediate: true })

const identifierKindLabel = computed(() => labelFor(identifierKind.value))

const profile = computed(() => user.value?.data ?? user.value ?? null)

const entries = computed(() => {
  if (!profile.value) return []
  return Object.entries(profile.value).filter(([, v]) => typeof v !== 'object' || v === null)
})

const formatValue = (v) => {
  if (v === null || v === undefined || v === '') return '—'
  if (typeof v === 'boolean') return v ? 'Yes' : 'No'
  return String(v)
}

const loggingOut = ref(false)
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

const profileForm = ref({ name: '', username: '', email: '', phone: '' })
const profileErrors = ref({})
const profileLoading = ref(false)
const profileSaved = ref(false)

watchEffect(() => {
  const p = profile.value
  if (!p) return
  profileForm.value = {
    name: p.name ?? '',
    username: p.username ?? '',
    email: p.email ?? '',
    phone: p.phone ?? '',
  }
})

const buildProfileBody = () => {
  const body = { name: profileForm.value.name }
  const include = (kind, has) => {
    if (!has) return false
    if (isExtraRequired(kind)) return true
    return !!profileForm.value[kind]
  }
  if (include('username', hasUsername.value)) body.username = profileForm.value.username
  if (include('email', hasEmail.value)) body.email = profileForm.value.email
  if (include('phone', hasPhone.value)) body.phone = profileForm.value.phone
  return body
}

const onUpdateProfile = async () => {
  profileErrors.value = {}
  profileSaved.value = false
  profileLoading.value = true
  try {
    await client('/api/update-profile', { method: 'PUT', body: buildProfileBody() })
    await refreshIdentity()
    profileSaved.value = true
  } catch (error) {
    profileErrors.value = error.data?.errors ?? {}
  } finally {
    profileLoading.value = false
  }
}

const passwordForm = ref({ old_password: '', password: '', password_confirmation: '' })
const passwordErrors = ref({})
const passwordLoading = ref(false)
const passwordSaved = ref(false)

const onChangePassword = async () => {
  passwordErrors.value = {}
  passwordSaved.value = false
  passwordLoading.value = true
  try {
    const body = {
      password: passwordForm.value.password,
      password_confirmation: passwordForm.value.password_confirmation,
      ...(hasPassword.value ? { old_password: passwordForm.value.old_password } : {}),
    }
    await client('/api/change-password', { method: 'POST', body })
    passwordSaved.value = true
    passwordForm.value = { old_password: '', password: '', password_confirmation: '' }
    await refreshIdentity()
  } catch (error) {
    passwordErrors.value = error.data?.errors ?? {}
  } finally {
    passwordLoading.value = false
  }
}

const identifierForm = ref({ new_identifier: '', otp: '' })
const identifierErrors = ref({})
const identifierLoading = ref(false)
const identifierVerifying = ref(false)
const identifierSaved = ref(false)
const otpSent = ref(false)

const onRequestIdentifierChange = async () => {
  identifierErrors.value = {}
  identifierLoading.value = true
  try {
    await client('/api/request-identifier-change', {
      method: 'POST',
      // The picker above (or the single configured identifier) declares the kind; the
      // API validates against it instead of guessing, so a phone must carry its country code.
      body: { new_identifier: identifierForm.value.new_identifier, type: identifierKind.value }
    })
    otpSent.value = true
  } catch (error) {
    identifierErrors.value = error.data?.errors ?? {}
  } finally {
    identifierLoading.value = false
  }
}

const onVerifyIdentifierChange = async () => {
  identifierErrors.value = {}
  identifierSaved.value = false
  identifierVerifying.value = true
  try {
    await client('/api/verify-identifier-change', {
      method: 'POST',
      body: { ...identifierForm.value, type: identifierKind.value }
    })
    await refreshIdentity()
    identifierSaved.value = true
    otpSent.value = false
    identifierForm.value = { new_identifier: '', otp: '' }
  } catch (error) {
    identifierErrors.value = error.data?.errors ?? {}
  } finally {
    identifierVerifying.value = false
  }
}

const socialErrors = ref({})
const connecting = ref(null)
const unlinking = ref(null)

const {
  data: socialData,
  pending: socialLoading,
  refresh: loadSocialAccounts,
} = useApiFetch('/api/social-accounts', {
  key: 'social-accounts',
})

// Tolerate both shapes: data is array OR { social_accounts: [...] }
const socialAccounts = computed(() => {
  const d = socialData.value?.data ?? socialData.value
  if (Array.isArray(d)) return d
  return d?.social_accounts ?? []
})

const linkedProviders = computed(() => socialAccounts.value.map((a) => a.provider))
const findLinked = (p) => socialAccounts.value.find((a) => a.provider === p)
const hasPassword = computed(() => !!profile.value?.has_password)

const canLinkMore = computed(() => {
  if (!maxSocialAccounts.value) return true
  return socialAccounts.value.length < maxSocialAccounts.value
})

const socialErrorMap = computed(() => ({
  invalid_firebase_token: t('err_invalid_firebase_token', 'Invalid sign-in token.', 'رمز الدخول غير صالح.'),
  social_provider_not_allowed: t('err_social_provider_not_allowed', 'This provider is not allowed.', 'هذا المزوّد غير مسموح.'),
  social_email_mismatch: t('err_social_email_mismatch', 'Provider email does not match your account.', 'بريد المزوّد لا يطابق حسابك.'),
  social_account_already_linked: t('err_social_account_already_linked', 'This account is already linked to another user.', 'هذا الحساب مربوط بمستخدم آخر.'),
  social_provider_already_linked: t('err_social_provider_already_linked', 'Provider already linked.', 'هذا المزوّد مربوط بالفعل.'),
  social_max_accounts_reached: t('err_social_max_accounts_reached', 'Maximum linked accounts reached.', 'تم بلوغ الحد الأقصى للحسابات المربوطة.'),
  social_auth_requires_email: t('err_social_auth_requires_email', 'Social login requires an email-based account.', 'يتطلب تسجيل الدخول الاجتماعي حسابًا بريدًا.'),
  social_provider_not_linked: t('err_social_provider_not_linked', 'Provider is not currently linked.', 'هذا المزوّد غير مربوط حاليًا.'),
  cannot_unlink_last_social_account: t('err_cannot_unlink_last_social_account', 'Set a password before unlinking your last social provider.', 'عيّن كلمة مرور قبل فك ربط آخر مزوّد.'),
}))

const socialErrorText = (key) => {
  const raw = socialErrors.value?.[key]?.[0]
  if (!raw) return ''
  return socialErrorMap.value[raw] ?? raw
}

const providerLabel = (p) => ({
  'google.com': 'Google',
  'apple.com': 'Apple',
  'facebook.com': 'Facebook',
  'twitter.com': 'Twitter',
  'github.com': 'GitHub',
  'microsoft.com': 'Microsoft',
  'yahoo.com': 'Yahoo',
}[p] ?? p)

const onConnectProvider = async (p) => {
  socialErrors.value = {}
  connecting.value = p
  try {
    const { idToken } = await signInWithProvider(p)
    await client('/api/link-social-account', {
      method: 'POST',
      body: { token: idToken },
    })
    await loadSocialAccounts()
    await refreshIdentity()
  } catch (error) {
    socialErrors.value = error?.data?.errors ?? { token: [error?.message ?? String(error)] }
  } finally {
    connecting.value = null
  }
}

const onUnlinkSocial = async (provider) => {
  socialErrors.value = {}
  unlinking.value = provider
  try {
    await client('/api/unlink-social-account', {
      method: 'DELETE',
      body: { provider }
    })
    await loadSocialAccounts()
    await refreshIdentity()
  } catch (error) {
    socialErrors.value = error.data?.errors ?? {}
  } finally {
    unlinking.value = null
  }
}

onMounted(() => {
  if (socialAuthAvailable.value) loadSocialAccounts()
})

const deleting = ref(false)
const deleteDialogOpen = ref(false)
const confirmDeleteAccount = async () => {
  deleting.value = true
  try {
    await client('/api/delete-account', { method: 'DELETE' })
    await logout().catch(() => { })
    if (import.meta.client) document.cookie = 'current_token_id=; path=/; max-age=0'
    navigateTo({ name: 'login' })
  } catch {
    deleting.value = false
  } finally {
    deleteDialogOpen.value = false
  }
}
</script>
