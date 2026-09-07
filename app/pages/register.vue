<template>
  <AuthScreen
    back="/login"
    :title="t('create_account_title', 'Welcome to Terracotta', 'اهلا بك بتيراكوتا')"
    :subtitle="t('register_description', 'Enter details below to register.', 'أدخل البيانات أدناه للتسجيل.')"
  >
    <form class="flex flex-col gap-5" @submit.prevent="onSubmit">
      <div class="grid gap-2">
        <Label for="name">{{ t('name', 'Name', 'الاسم') }}</Label>
        <Input id="name" v-model="form.name" type="text" class="h-12 rounded-xl text-base" :placeholder="t('placeholder_name', 'John Doe', 'محمد أحمد')" required />
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
            class="rounded-full"
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
          class="h-12 rounded-xl text-base"
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
            class="text-xs font-medium text-brand-rust underline-offset-4 hover:underline"
          >{{ t('go_to_login', 'Go to login', 'الذهاب لتسجيل الدخول') }}</NuxtLink>
        </template>
        <span v-if="errors.identifier" class="text-xs text-destructive">{{ errors.identifier[0] }}</span>
      </div>

      <div v-if="showsExtraField('username')" class="grid gap-2">
        <Label for="username">
          {{ labelFor('username') }}
          <span v-if="!isExtraRequired('username')" class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
        </Label>
        <Input id="username" v-model="form.username" type="text" class="h-12 rounded-xl text-base" :placeholder="placeholderFor('username')" :required="isExtraRequired('username')" />
        <span v-if="errors.username" class="text-xs text-destructive">{{ errors.username[0] }}</span>
      </div>
      <div v-if="showsExtraField('email')" class="grid gap-2">
        <Label for="email_extra">
          {{ labelFor('email') }}
          <span v-if="!isExtraRequired('email')" class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
        </Label>
        <Input id="email_extra" v-model="form.email" type="email" class="h-12 rounded-xl text-base" :placeholder="placeholderFor('email')" :required="isExtraRequired('email')" />
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
        <AuthPasswordInput id="password" v-model="form.password" required />
        <span v-if="errors.password" class="text-xs text-destructive">{{ errors.password[0] }}</span>
      </div>
      <div class="grid gap-2">
        <Label for="confirm">{{ t('confirm_password', 'Confirm password', 'تأكيد كلمة المرور') }}</Label>
        <AuthPasswordInput id="confirm" v-model="form.password_confirmation" required />
        <span v-if="errors.password_confirmation" class="text-xs text-destructive">{{ errors.password_confirmation[0] }}</span>
      </div>
      <div class="flex items-start gap-2">
        <Checkbox id="policy" v-model="form.policy_agreed" required class="mt-0.5" />
        <Label for="policy" class="text-sm font-normal text-muted-foreground">
          {{ t('policy_agreement_prefix', 'I agree to the', 'أوافق على') }}
          <button
            type="button"
            data-test="open-terms"
            class="text-brand-rust underline-offset-4 hover:underline"
            @click.prevent="termsOpen = true"
          >{{ termsPage?.name || t('terms_and_conditions', 'Terms & Conditions', 'الشروط والأحكام') }}</button>
          {{ t('and', 'and', 'و') }}
          <NuxtLink
            v-if="privacyPage"
            to="/privacy"
            target="_blank"
            class="text-brand-rust underline-offset-4 hover:underline"
          >{{ privacyPage.name }}</NuxtLink>
          <span v-else>{{ t('privacy_policy', 'Privacy Policy', 'سياسة الخصوصية') }}</span>
        </Label>
        <span v-if="errors.policy_agreed" class="text-xs text-destructive">{{ errors.policy_agreed[0] }}</span>
      </div>
      <Button
        type="submit"
        size="lg"
        class="h-13 w-full rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
        :disabled="loading || identifierTaken || checking"
      >
        {{ loading ? t('creating', 'Creating...', 'جارٍ الإنشاء...') : t('create_account', 'Create account', 'إنشاء حساب') }}
      </Button>
    </form>
    <p class="mt-6 text-center text-sm">
      <span class="text-muted-foreground">{{ t('have_account', 'Have account?', 'لديك حساب؟') }}&nbsp;</span>
      <NuxtLink to="/login" class="font-medium text-brand-rust underline-offset-4 hover:underline">
        {{ t('sign_in', 'Sign in', 'تسجيل الدخول') }}
      </NuxtLink>
    </p>
    <AccountTermsModal v-model:open="termsOpen" />
  </AuthScreen>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-pre-auth', 'password-mode-only'],
  name: 'register'
})

const { identifiers, isMultiIdentifier, showsExtraField, isExtraRequired, inputTypeFor, placeholderFor, labelFor, allowedPhoneCountries } = useAuthConfig()
const { t } = useLang('web', 'auth')

const { bySlug } = usePages()
const termsPage = computed(() => bySlug('terms'))
const privacyPage = computed(() => bySlug('privacy'))
const termsOpen = ref(false)

const errors = ref({})
const loading = ref(false)
const checking = ref(false)
const identifierTaken = ref(false)

const client = useApi()
const { user, login } = useSanctumAuth()

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
  loading.value = true
  const body = buildBody()
  try {
    await client('/api/register', { method: 'POST', body })
    if (user.value?.data?.is_guest) user.value = null
    await login({ identifier: form.value.identifier, type: identifierKind.value, password: form.value.password })
    // A verification-required install hands back an unverified session plus an OTP —
    // the code screen is the next step, not the home page.
    const registered = user.value?.data ?? user.value ?? {}
    navigateTo({ name: registered.verified_at || registered.is_verified ? 'home' : 'verify' })
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    loading.value = false
  }
}
</script>
