<template>
  <div class="flex min-h-svh items-center justify-center bg-muted/40 p-6">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle class="text-2xl">{{ t('create_account', 'Create account', 'إنشاء حساب') }}</CardTitle>
        <CardDescription>{{ t('register_description', 'Enter details below to register.', 'أدخل البيانات أدناه للتسجيل.') }}</CardDescription>
      </CardHeader>
      <CardContent>
        <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
          <div class="grid gap-2">
            <Label for="name">{{ t('name', 'Name', 'الاسم') }}</Label>
            <Input id="name" v-model="form.name" type="text" :placeholder="t('placeholder_name', 'John Doe', 'محمد أحمد')" required />
            <span v-if="errors.name" class="text-red-500">{{ errors.name[0] }}</span>
          </div>

          <div v-if="isMultiIdentifier" class="grid gap-2">
            <Label>{{ t('sign_up_with', 'Sign up with', 'سجّل عبر') }}</Label>
            <div class="flex flex-wrap gap-2">
              <Button
                v-for="kind in identifiers"
                :key="kind"
                type="button"
                size="sm"
                :variant="identifierKind === kind ? 'default' : 'outline'"
                @click="identifierKind = kind"
              >
                {{ labelFor(kind) }}
              </Button>
            </div>
          </div>

          <div class="grid gap-2">
            <Label :for="identifierKind">{{ labelFor(identifierKind) }}</Label>
            <Input
              :id="identifierKind"
              v-model="form.identifier"
              :type="inputTypeFor(identifierKind)"
              :placeholder="placeholderFor(identifierKind)"
              required
            />
            <span
              v-if="checking"
              class="text-xs text-muted-foreground"
            >{{ t('checking', 'Checking...', 'جارٍ التحقق...') }}</span>
            <template v-else-if="identifierTaken">
              <span class="text-xs text-red-500">
                {{ t('identifier_already_taken', 'This :field is already in use.', 'هذا الـ:field مستخدم بالفعل.', { field: labelFor(identifierKind).toLowerCase() }) }}
              </span>
              <NuxtLink
                to="/login"
                class="text-xs font-medium underline-offset-4 hover:underline"
              >{{ t('go_to_login', 'Go to login', 'الذهاب لتسجيل الدخول') }}</NuxtLink>
            </template>
            <span v-if="errors.identifier" class="text-red-500">{{ errors.identifier[0] }}</span>
          </div>

          <div v-if="showsExtraField('username')" class="grid gap-2">
            <Label for="username">
              {{ labelFor('username') }}
              <span v-if="!isExtraRequired('username')" class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
            </Label>
            <Input id="username" v-model="form.username" type="text" :placeholder="placeholderFor('username')" :required="isExtraRequired('username')" />
            <span v-if="errors.username" class="text-red-500">{{ errors.username[0] }}</span>
          </div>
          <div v-if="showsExtraField('email')" class="grid gap-2">
            <Label for="email_extra">
              {{ labelFor('email') }}
              <span v-if="!isExtraRequired('email')" class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
            </Label>
            <Input id="email_extra" v-model="form.email" type="email" :placeholder="placeholderFor('email')" :required="isExtraRequired('email')" />
            <span v-if="errors.email" class="text-red-500">{{ errors.email[0] }}</span>
          </div>
          <div v-if="showsExtraField('phone')" class="grid gap-2">
            <Label for="phone_extra">
              {{ labelFor('phone') }}
              <span v-if="!isExtraRequired('phone')" class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
            </Label>
            <Input id="phone_extra" v-model="form.phone" type="tel" :placeholder="placeholderFor('phone')" :required="isExtraRequired('phone')" />
            <span v-if="errors.phone" class="text-red-500">{{ errors.phone[0] }}</span>
          </div>

          <div class="grid gap-2">
            <Label for="password">{{ t('password', 'Password', 'كلمة المرور') }}</Label>
            <Input id="password" v-model="form.password" type="password" required />
            <span v-if="errors.password" class="text-red-500">{{ errors.password[0] }}</span>
          </div>
          <div class="grid gap-2">
            <Label for="confirm">{{ t('confirm_password', 'Confirm password', 'تأكيد كلمة المرور') }}</Label>
            <Input id="confirm" v-model="form.password_confirmation" type="password" required />
            <span v-if="errors.password_confirmation" class="text-red-500">{{ errors.password_confirmation[0] }}</span>
          </div>
          <div class="flex items-center gap-2">
            <Checkbox id="policy" v-model="form.policy_agreed" required />
            <Label for="policy" class="text-sm font-normal">
              {{ t('policy_agreement', 'I agree to the terms and privacy policy', 'أوافق على الشروط وسياسة الخصوصية') }}
            </Label>
            <span v-if="errors.policy_agreed" class="text-red-500">{{ errors.policy_agreed[0] }}</span>
          </div>
          <Button type="submit" class="w-full" :disabled="loading || identifierTaken || checking">
            {{ loading ? t('creating', 'Creating...', 'جارٍ الإنشاء...') : t('create_account', 'Create account', 'إنشاء حساب') }}
          </Button>
        </form>
      </CardContent>
      <CardFooter class="justify-center text-sm">
        <span class="text-muted-foreground">{{ t('have_account', 'Have account?', 'لديك حساب؟') }}&nbsp;</span>
        <NuxtLink to="/login" class="font-medium underline-offset-4 hover:underline">
          {{ t('sign_in', 'Sign in', 'تسجيل الدخول') }}
        </NuxtLink>
      </CardFooter>
    </Card>
  </div>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-pre-auth', 'password-mode-only'],
  name: 'register'
})

const { identifiers, isMultiIdentifier, showsExtraField, isExtraRequired, inputTypeFor, placeholderFor, labelFor } = useAuthConfig()
const { t } = useLang('web', 'auth')

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
    navigateTo({ name: 'home' })
  } catch (error) {
    errors.value = error.data?.errors ?? {}
  } finally {
    loading.value = false
  }
}
</script>
