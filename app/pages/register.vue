<template>
  <AuthScreen
    back="/login"
    :title="t('create_account_title', 'Welcome to Terracotta', 'اهلا بك بتيراكوتا')"
    :subtitle="t('register_description', 'Enter details below to register.', 'أدخل البيانات أدناه للتسجيل.')"
  >
    <template v-if="created">
      <AppConfetti />
      <div class="flex flex-col items-center gap-4 text-center">
        <span class="flex size-16 items-center justify-center rounded-full bg-success/15 text-brand-green">
          <LucideCheck class="size-8" />
        </span>
        <h2 data-test="register-success" class="font-display text-2xl font-semibold text-foreground">
          {{ t('account_created_success', 'Your account is ready', 'تم انشاء الحساب بنجاح') }}
        </h2>
        <p class="text-sm leading-relaxed text-muted-foreground">
          {{ t('register_success_body', 'Every workshop sets its own deadline for cancelling or rescheduling. You will see yours on the booking itself.', 'لكل ورشة موعد نهائي خاص بها للإلغاء أو تغيير الموعد، وستجده على الحجز نفسه.') }}
        </p>
        <Button size="lg" class="h-13 w-full rounded-control bg-brand-terracotta text-base hover:bg-brand-terracotta/90" @click="onContinue">
          {{ t('continue', 'Continue', 'استكمال') }}
        </Button>
      </div>
    </template>

    <form v-else class="flex flex-col gap-5" @submit.prevent="onSubmit">
      <div class="grid gap-2">
        <Label for="name">{{ t('name', 'Name', 'الاسم') }}</Label>
        <Input id="name" v-model="form.name" type="text" class="h-12 rounded-field text-base" :placeholder="t('placeholder_name', 'John Doe', 'محمد أحمد')" required />
        <span v-if="errors.name" class="text-xs text-destructive">{{ errors.name[0] }}</span>
      </div>

      <div v-if="isMultiIdentifier" class="grid gap-2">
        <Label>{{ t('sign_up_with', 'Sign up with', 'سجّل عبر') }}</Label>
        <div class="flex flex-wrap gap-2">
          <Button
            v-for="kind in identifiers"
            :key="kind"
            type="button"
            size="sm"
            class="rounded-control"
            :variant="identifierKind === kind ? 'default' : 'outline'"
            @click="identifierKind = kind"
          >
            {{ labelFor(kind) }}
          </Button>
        </div>
      </div>

      <div class="grid gap-2">
        <Label :for="identifierKind">{{ labelFor(identifierKind) }}</Label>
        <AuthPhoneInput
          v-if="identifierKind === 'phone'"
          :id="identifierKind"
          v-model="form.identifier"
          :allowed="allowedPhoneCountries"
        />
        <Input
          v-else
          :id="identifierKind"
          v-model="form.identifier"
          :type="inputTypeFor(identifierKind)"
          :placeholder="placeholderFor(identifierKind)"
          class="h-12 rounded-field text-base"
          required
        />
        <span
          v-if="checking"
          class="text-xs text-muted-foreground"
        >{{ t('checking', 'Checking...', 'جارٍ التحقق...') }}</span>
        <template v-else-if="identifierTaken">
          <span class="text-xs text-destructive">
            {{ t('identifier_already_taken', 'This :field is already in use.', 'هذا الـ:field مستخدم بالفعل.', { field: labelFor(identifierKind).toLowerCase() }) }}
          </span>
          <NuxtLink
            to="/login"
            class="text-xs font-medium text-brand-terracotta underline-offset-4 hover:underline"
          >{{ t('go_to_login', 'Go to login', 'الذهاب لتسجيل الدخول') }}</NuxtLink>
        </template>
        <span v-if="emailDomainRejected" class="text-xs text-destructive">
          {{ t('email_domain_not_allowed', 'Use an address ending in :domains.', 'استخدم بريدًا ينتهي بـ :domains.', { domains: allowedDomainList }) }}
        </span>
        <span v-if="errors.identifier" class="text-xs text-destructive">{{ errors.identifier[0] }}</span>
      </div>

      <div v-if="showsExtraField('username')" class="grid gap-2">
        <Label for="username">
          {{ labelFor('username') }}
          <span v-if="!isExtraRequired('username')" class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
        </Label>
        <Input id="username" v-model="form.username" type="text" class="h-12 rounded-field text-base" :placeholder="placeholderFor('username')" :required="isExtraRequired('username')" />
        <span v-if="errors.username" class="text-xs text-destructive">{{ errors.username[0] }}</span>
      </div>
      <div v-if="showsExtraField('email')" class="grid gap-2">
        <Label for="email_extra">
          {{ labelFor('email') }}
          <span v-if="!isExtraRequired('email')" class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
        </Label>
        <Input id="email_extra" v-model="form.email" type="email" class="h-12 rounded-field text-base" :placeholder="placeholderFor('email')" :required="isExtraRequired('email')" />
        <span v-if="errors.email" class="text-xs text-destructive">{{ errors.email[0] }}</span>
      </div>
      <div v-if="showsExtraField('phone')" class="grid gap-2">
        <Label for="phone_extra">
          {{ labelFor('phone') }}
          <span v-if="!isExtraRequired('phone')" class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
        </Label>
        <AuthPhoneInput id="phone_extra" v-model="form.phone" :allowed="allowedPhoneCountries" />
        <span v-if="errors.phone" class="text-xs text-destructive">{{ errors.phone[0] }}</span>
      </div>

      <div class="grid gap-2">
        <Label for="password">{{ t('password', 'Password', 'كلمة المرور') }}</Label>
        <AuthPasswordInput id="password" v-model="form.password" required minlength="8" />
        <span v-if="errors.password" class="text-xs text-destructive">{{ errors.password[0] }}</span>
      </div>
      <div class="grid gap-2">
        <Label for="confirm">{{ t('confirm_password', 'Confirm password', 'تأكيد كلمة المرور') }}</Label>
        <AuthPasswordInput id="confirm" v-model="form.password_confirmation" required minlength="8" />
        <span v-if="errors.password_confirmation" class="text-xs text-destructive">{{ errors.password_confirmation[0] }}</span>
      </div>
      <div class="grid gap-2">
        <div class="flex items-start gap-2">
        <Checkbox id="policy" v-model="form.policy_agreed" class="mt-0.5 shrink-0" />
        <!-- A plain <label>, not the shadcn one: that component is `flex items-center`,
             so this sentence became three flex items — prefix, terms link, privacy link —
             each wrapping in its own column, with the "و" stranded between them as a
             fourth. A sentence has to lay out as a sentence. -->
        <label for="policy" class="text-sm leading-relaxed font-normal text-muted-foreground">
          {{ t('policy_agreement_prefix', 'I agree to the', 'أوافق على') }}
          <button
            type="button"
            data-test="open-terms"
            class="text-brand-terracotta underline-offset-4 hover:underline"
            @click.prevent="openPage = 'terms'"
          >{{ termsPage?.name || termsTitle }}</button>
          {{ t('and', 'and', 'و') }}
          <!-- The privacy policy opens the same way the terms do: both are CMS pages that
               are always there, and sending somebody to a new tab mid-registration means
               coming back to a form they have to fill in again. -->
          <button
            type="button"
            data-test="open-privacy"
            class="text-brand-terracotta underline-offset-4 hover:underline"
            @click.prevent="openPage = 'privacy'"
          >{{ privacyPage?.name || privacyTitle }}</button>
        </label>
        </div>
        <span v-if="errors.policy_agreed" class="text-xs text-destructive">{{ errors.policy_agreed[0] }}</span>
      </div>

      <AuthFormError :message="formError" />

      <Button
        type="submit"
        size="lg"
        class="h-13 w-full rounded-control bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
        :disabled="loading || identifierTaken || checking"
      >
        {{ loading ? t('creating', 'Creating...', 'جارٍ الإنشاء...') : t('create_account', 'Create account', 'إنشاء حساب') }}
      </Button>
    </form>
    <p v-if="!created" class="mt-6 text-center text-sm">
      <span class="text-muted-foreground">{{ t('have_account', 'Have account?', 'لديك حساب؟') }}&nbsp;</span>
      <NuxtLink
        :to="{ path: '/login', query: redirectTarget === '/' ? {} : { redirect: redirectTarget } }"
        class="font-medium text-brand-terracotta underline-offset-4 hover:underline"
      >
        {{ t('sign_in', 'Sign in', 'تسجيل الدخول') }}
      </NuxtLink>
    </p>
    <AccountPageModal
      v-if="openPage"
      :key="openPage"
      :slug="openPage"
      :title="openPage === 'terms' ? termsTitle : privacyTitle"
      @close="openPage = null"
    />
  </AuthScreen>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-pre-auth', 'password-mode-only'],
  name: 'register'
})

const { identifiers, isMultiIdentifier, showsExtraField, isExtraRequired, inputTypeFor, placeholderFor, labelFor, allowedPhoneCountries, allowedEmailDomains, isEmailDomainAllowed } = useAuthConfig()
const { t } = useLang('web', 'auth')

const { bySlug } = usePages()
const termsPage = computed(() => bySlug('terms'))
const privacyPage = computed(() => bySlug('privacy'))
const termsTitle = computed(() => t('terms_and_conditions', 'Terms & Conditions', 'الشروط والأحكام'))
const privacyTitle = computed(() => t('privacy_policy', 'Privacy Policy', 'سياسة الخصوصية'))

// Which CMS document the dialog is showing, if any: 'terms' | 'privacy' | null.
const openPage = ref(null)

const route = useRoute()
const redirectTarget = computed(() => safeAuthRedirect(route.query.redirect))

const errors = ref({})
// 429 from the auth throttle and 403 carry a message and no `errors` map.
const formError = ref('')
const loading = ref(false)
const created = ref(false)
const checking = ref(false)
const identifierTaken = ref(false)

const client = useApi()
const { user, login, refreshIdentity } = useSanctumAuth()

const identifierKind = ref(identifiers.value[0] ?? 'email')
watch(identifiers, (list) => {
  if (list.length && !list.includes(identifierKind.value)) {
    identifierKind.value = list[0]
  }
}, { immediate: true })

const form = ref({
  name: '',
  identifier: '',
  username: '',
  email: '',
  phone: '',
  password: '',
  password_confirmation: '',
  policy_agreed: false
})

const allowedDomainList = computed(() =>
  Array.isArray(allowedEmailDomains.value) ? allowedEmailDomains.value.join(', ') : ''
)
// The backend enforces the same list; this is so the customer is told before the request.
const emailDomainRejected = computed(() =>
  identifierKind.value === 'email' && !!form.value.identifier && !isEmailDomainAllowed(form.value.identifier)
)

let debounce = null
watch(() => form.value.identifier, (val) => {
  identifierTaken.value = false
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
        body: { identifier: val, type: identifierKind.value }
      })
      const data = res?.data ?? res ?? {}
      identifierTaken.value = !!data.exists
    } catch {
      identifierTaken.value = false
    } finally {
      checking.value = false
    }
  }, 500)
})

onUnmounted(() => {
  if (debounce) clearTimeout(debounce)
})

const buildBody = () => {
  const body = {
    name: form.value.name,
    identifier: form.value.identifier,
    // The API never infers the kind from the value — the picker (or the single
    // configured identifier) is what says whether this is an email or a phone.
    type: identifierKind.value,
    password: form.value.password,
    password_confirmation: form.value.password_confirmation,
    policy_agreed: form.value.policy_agreed,
  }
  const include = (kind) => {
    if (!showsExtraField(kind)) return false
    if (isExtraRequired(kind)) return true
    return !!form.value[kind]
  }
  if (include('username')) body.username = form.value.username
  if (include('email')) body.email = form.value.email
  if (include('phone')) body.phone = form.value.phone
  return body
}

const onSubmit = async () => {
  errors.value = {}
  formError.value = ''
  if (!form.value.policy_agreed) {
    errors.value = { policy_agreed: [t('policy_required', 'Accept the terms to continue.', 'وافق على الشروط للمتابعة.')] }
    return
  }
  if (form.value.password !== form.value.password_confirmation) {
    errors.value = { password_confirmation: [t('password_mismatch', 'The two passwords do not match.', 'كلمتا المرور غير متطابقتين.')] }
    return
  }
  if (emailDomainRejected.value) return
  loading.value = true
  const body = buildBody()
  try {
    const res = await client('/api/register', { method: 'POST', body })
    if (user.value?.data?.is_guest) user.value = null
    // Registering already hands back a session. Calling `/api/login` on top of it would
    // spend one of the five-per-minute auth attempts for nothing. A verification-required
    // install answers without a token instead — that shape does need the sign-in.
    const data = res?.data ?? res ?? {}
    if (data.token) {
      const sanctum = useSanctumAppConfig()
      await sanctum?.tokenStorage?.set?.(useNuxtApp(), data.token)
      await refreshIdentity()
    } else {
      await login({
        identifier: form.value.identifier,
        type: identifierKind.value,
        password: form.value.password,
        ...authDeviceMeta()
      })
    }
    const registered = user.value?.data ?? user.value ?? {}
    // A verification-required install hands back an unverified session plus an OTP —
    // the code screen is the next step, not the celebration.
    if (registered.verified_at || registered.is_verified) created.value = true
    else navigateTo({ name: 'verify' })
  } catch (error) {
    const normalized = normalizeApiError(error)
    errors.value = normalized.errors
    formError.value = Object.keys(normalized.errors).length ? '' : normalized.message
  } finally {
    loading.value = false
  }
}

const onContinue = () => navigateTo(redirectTarget.value)
</script>
