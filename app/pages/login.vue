<template>
  <div>
    <AuthScreen
      :title="
        appUsers
          ? t('login_welcome_title', 'Welcome back', 'اهلا بعودتك')
          : t('welcome', 'Welcome', 'مرحبًا')
      "
      :subtitle="
        appUsers
          ? t(
              'login_description',
              'Enter your :field below to sign in.',
              'أدخل :field للدخول.',
              { field: identifierLabel.toLowerCase() },
            )
          : t(
              'guest_only_description',
              'You are browsing as a guest.',
              'أنت تتصفح كزائر.',
            )
      "
    >
      <template v-if="appUsers">
        <form class="flex flex-col gap-5" @submit.prevent="onSubmit">
          <div v-if="identifierTypes.length > 1" class="flex flex-wrap gap-2">
            <Button
              v-for="kind in identifierTypes"
              :key="kind"
              type="button"
              size="sm"
              class="rounded-control"
              :variant="identifierType === kind ? 'default' : 'outline'"
              @click="identifierType = kind"
              >{{ labelFor(kind) }}</Button
            >
          </div>

          <div class="grid gap-2">
            <Label for="identifier">{{ identifierLabel }}</Label>
            <!-- Keyed off the kind selected above, not `identifierInputType`: that is
                 derived from the config and falls back to plain text whenever the project
                 accepts more than one identifier, which left "Phone" with no country-code
                 picker. A number typed without its country code normalizes to null on the
                 backend, so the customer was told their account did not exist. -->
            <AuthPhoneInput
              v-if="identifierType === 'phone'"
              id="identifier"
              v-model="form.identifier"
              :allowed="allowedPhoneCountries"
            />
            <Input
              v-else
              id="identifier"
              v-model="form.identifier"
              :type="identifierType === 'email' ? 'email' : identifierInputType"
              :placeholder="identifierPlaceholder"
              class="h-12 rounded-field text-base"
              required
            />
            <span v-if="checking" class="text-xs text-muted-foreground">{{
              t("checking", "Checking...", "جارٍ التحقق...")
            }}</span>
            <span
              v-else-if="identifierStatus === 'missing'"
              class="text-xs text-destructive"
              >{{
                t(
                  "no_account_with_identifier",
                  "No account with this :field.",
                  "لا يوجد حساب بهذا الـ:field.",
                  { field: identifierLabel.toLowerCase() },
                )
              }}</span
            >
            <span
              v-else-if="identifierStatus === 'active'"
              class="text-xs text-brand-green"
              >{{
                t("account_found", "Account found.", "تم العثور على الحساب.")
              }}</span
            >
            <span
              v-if="identifierStatus === 'active' && linkedProviders.length"
              class="text-xs text-muted-foreground"
            >
              {{
                t(
                  "account_linked_to",
                  "Linked to: :providers",
                  "مربوط بـ: :providers",
                  { providers: linkedProviders.map(providerLabel).join(", ") },
                )
              }}
            </span>
            <span
              v-if="identifierStatus === 'active' && !hasPasswordOnAccount"
              class="text-xs text-warning"
            >
              {{
                t(
                  "no_password_use_social",
                  "No password set. Use a social provider below.",
                  "لا توجد كلمة مرور. استخدم مزوّدًا اجتماعيًا أدناه.",
                )
              }}
            </span>
            <span v-if="errors.identifier" class="text-xs text-destructive">{{
              errors.identifier[0]
            }}</span>
          </div>
          <div
            v-if="isOtpMode && identifierStatus === 'missing'"
            class="grid gap-2"
          >
            <Label for="name">{{ t("name", "Name", "الاسم") }}</Label>
            <Input
              id="name"
              v-model="form.name"
              type="text"
              class="h-12 rounded-field text-base"
              :placeholder="t('placeholder_name', 'John Doe', 'محمد أحمد')"
              required
            />
            <span v-if="errors.name" class="text-xs text-destructive">{{
              errors.name[0]
            }}</span>
          </div>
          <p v-if="errors.device_id" class="text-xs text-destructive">
            {{ errors.device_id[0] }}
          </p>
          <p v-if="errors.platform" class="text-xs text-destructive">
            {{ errors.platform[0] }}
          </p>
          <p v-if="errors.fcm_token" class="text-xs text-destructive">
            {{ errors.fcm_token[0] }}
          </p>
          <div v-if="!isOtpMode" class="grid gap-2">
            <div class="flex items-center justify-between">
              <Label for="password">{{
                t("password", "Password", "كلمة المرور")
              }}</Label>
              <NuxtLink
                :to="{
                  path: '/forgot-password',
                  query: {
                    ...(form.identifier
                      ? { identifier: form.identifier, type: identifierType }
                      : {}),
                    ...(redirectTarget === '/'
                      ? {}
                      : { redirect: redirectTarget }),
                  },
                }"
                class="text-xs font-medium text-brand-terracotta underline-offset-4 hover:underline"
                >{{
                  t("forgot_password", "Forgot password?", "نسيت كلمة السر؟")
                }}</NuxtLink
              >
            </div>
            <AuthPasswordInput id="password" v-model="form.password" required />
            <span v-if="errors.password" class="text-xs text-destructive">{{
              errors.password[0]
            }}</span>
          </div>
          <AuthFormError :message="formError" />

          <Button
            type="submit"
            size="lg"
            class="h-13 w-full rounded-control bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
            :disabled="submitDisabled"
            >{{ submitLabel }}</Button
          >
        </form>
      </template>
      <template
        v-if="appUsers && socialAuthAvailable && socialProviders.length"
      >
        <div class="my-6 flex items-center gap-2">
          <span class="h-px flex-1 bg-border" />
          <span class="text-xs text-muted-foreground">
            {{ t("or_continue_with", "Or continue with", "أو المتابعة عبر") }}
          </span>
          <span class="h-px flex-1 bg-border" />
        </div>
        <div class="flex flex-col gap-3">
          <SocialAuthButtons
            :providers="socialProviders"
            :loading="loading"
            @select="onSocial"
          />
          <span v-if="socialError" class="text-xs text-destructive">{{
            socialError
          }}</span>
        </div>
      </template>
      <p v-if="appUsers && !isOtpMode" class="mt-6 text-center text-sm">
        <span class="text-muted-foreground"
          >{{ t("no_account", "No account?", "ليس لديك حساب؟") }}&nbsp;</span
        >
        <NuxtLink
          :to="{
            path: '/register',
            query:
              redirectTarget === '/' ? {} : { redirect: redirectTarget },
          }"
          class="font-medium text-brand-terracotta underline-offset-4 hover:underline"
          >{{ t("register", "Register", "إنشاء حساب") }}</NuxtLink
        >
      </p>
      <p class="mt-4 text-center text-xs text-muted-foreground">
        {{
          t(
            "login_terms_prefix",
            "By signing in you accept our",
            "بتسجيل الدخول فإنك توافق على",
          )
        }}
        <button
          type="button"
          data-test="open-terms"
          class="text-brand-terracotta underline-offset-4 hover:underline"
          @click="openPage = 'terms'"
        >
          {{ termsTitle }}
        </button>
        {{ t("and", "and", "و") }}
        <!-- Both documents, both opened the same way: they are CMS pages that are always
             there, and either one is part of what signing in accepts. -->
        <button
          type="button"
          data-test="open-privacy"
          class="text-brand-terracotta underline-offset-4 hover:underline"
          @click="openPage = 'privacy'"
        >
          {{ privacyTitle }}
        </button>
      </p>
      <AccountPageModal
        v-if="openPage"
        :key="openPage"
        :slug="openPage"
        :title="openPage === 'terms' ? termsTitle : privacyTitle"
        @close="openPage = null"
      />
    </AuthScreen>

  </div>
</template>

<script setup>
definePageMeta({
  middleware: ["require-pre-auth"],
  name: "login",
});

const {
  identifierLabel,
  identifierInputType,
  identifierPlaceholder,
  identifierTypes,
  defaultIdentifierType,
  labelFor,
  socialAuthAvailable,
  socialProviders,
  appUsers,
  isOtpMode,
  allowedPhoneCountries,
} = useAuthConfig();

// Which kind of identifier the box holds. Sent on every request — the API rejects a
// value that does not match its declared type instead of guessing from the string.
const identifierType = ref(defaultIdentifierType.value);
watch(
  identifierTypes,
  (list) => {
    if (list.length && !list.includes(identifierType.value))
      identifierType.value = list[0];
  },
  { immediate: true },
);
const { t } = useLang("web", "auth");

const errors = ref({});
// 429 (the auth throttle), 403 (deactivated account) and 500 all arrive with a `message`
// and no `errors` map, so reading only `error.data.errors` showed the customer nothing.
const formError = ref("");
const loading = ref(false);
const checking = ref(false);
const identifierStatus = ref(null); // 'missing' | 'active'
const identifierMeta = ref({
  has_password: true,
  social_providers: [],
  verified: false,
  is_guest: false,
});
const socialError = ref("");
const termsTitle = computed(() =>
  t("terms_and_conditions", "Terms & Conditions", "الشروط والأحكام"),
);
const privacyTitle = computed(() =>
  t("privacy_policy", "Privacy Policy", "سياسة الخصوصية"),
);

// Which CMS document the dialog is showing, if any: 'terms' | 'privacy' | null.
const openPage = ref(null);

const linkedProviders = computed(
  () => identifierMeta.value.social_providers ?? [],
);
const hasPasswordOnAccount = computed(
  () => identifierMeta.value.has_password !== false,
);
const providerLabel = (p) =>
  ({
    "google.com": "Google",
    "apple.com": "Apple",
    "facebook.com": "Facebook",
    "twitter.com": "Twitter",
    "github.com": "GitHub",
    "microsoft.com": "Microsoft",
    "yahoo.com": "Yahoo",
  })[p] ?? p;

const client = useApi();
const form = ref({ identifier: "", password: "", name: "" });

const submitDisabled = computed(() => {
  if (loading.value) return true;
  if (isOtpMode.value) {
    if (identifierStatus.value === "missing" && !form.value.name) return true;
    return false;
  }
  if (identifierStatus.value === "missing") return true;
  if (identifierStatus.value === "active" && !hasPasswordOnAccount.value)
    return true;
  return false;
});

const submitLabel = computed(() => {
  if (loading.value)
    return isOtpMode.value
      ? t("sending", "Sending...", "جارٍ الإرسال...")
      : t("signing_in", "Signing in...", "جارٍ تسجيل الدخول...");
  return isOtpMode.value
    ? t("send_code", "Send code", "إرسال الرمز")
    : t("sign_in", "Sign in", "تسجيل الدخول");
});

const { user, login, refreshIdentity } = useSanctumAuth();
const route = useRoute();

// Where the visitor was headed before they were asked to sign in — a gift claim link
// sends `?redirect=/gift/<token>`. Only ever a path on this site; see `safeAuthRedirect`.
const redirectTarget = computed(() => safeAuthRedirect(route.query.redirect));

const clearGuestUser = () => {
  if (user.value?.data?.is_guest) user.value = null;
};

const persistTokenId = (tokenId) => {
  if (tokenId == null || !import.meta.client) return;
  document.cookie = `current_token_id=${tokenId}; path=/; SameSite=Lax; max-age=${60 * 60 * 24 * 365}`;
};

let debounce = null;

watch(
  () => form.value.identifier,
  (val) => {
    identifierStatus.value = null;
    if (debounce) clearTimeout(debounce);
    if (!val || val.length < 3) {
      checking.value = false;
      return;
    }
    checking.value = true;
    debounce = setTimeout(async () => {
      try {
        const res = await client("/api/check-identifier", {
          method: "POST",
          body: { identifier: val, type: identifierType.value },
        });
        const data = res?.data ?? res ?? {};
        identifierMeta.value = {
          has_password: data.has_password !== false,
          social_providers: Array.isArray(data.social_providers)
            ? data.social_providers
            : [],
          verified: !!data.verified,
          is_guest: !!data.is_guest,
        };
        // `exists` is the only verdict this endpoint gives. It reports neither
        // suspension (that surfaces as a 403 on login, shown via `formError`) nor a
        // pending deletion — deleting an account here is immediate and permanent, so
        // there is nothing to restore.
        identifierStatus.value = data.exists ? "active" : "missing";
      } catch {
        identifierStatus.value = null;
        identifierMeta.value = {
          has_password: true,
          social_providers: [],
          verified: false,
          is_guest: false,
        };
      } finally {
        checking.value = false;
      }
    }, 500);
  },
);

onUnmounted(() => {
  if (debounce) clearTimeout(debounce);
});

const performLogin = async () => {
  errors.value = {};
  formError.value = "";
  loading.value = true;
  try {
    clearGuestUser();
    const res = await login(
      { ...form.value, type: identifierType.value, ...authDeviceMeta() },
      true,
    );
    persistTokenId(res?.data?.token_id ?? res?.token_id);
    // `login` has already sent them to `redirect.onLogin`; this is the second half of
    // the journey they were on.
    if (redirectTarget.value !== "/")
      await navigateTo(redirectTarget.value, { replace: true });
  } catch (error) {
    const normalized = normalizeApiError(error);
    errors.value = normalized.errors;
    formError.value = Object.keys(normalized.errors).length
      ? ""
      : normalized.message;
  } finally {
    loading.value = false;
  }
};

const performOtpRequest = async () => {
  errors.value = {};
  formError.value = "";
  loading.value = true;
  try {
    const body = {
      identifier: form.value.identifier,
      type: identifierType.value,
    };
    if (identifierStatus.value === "missing" && form.value.name)
      body.name = form.value.name;
    await client("/api/login", { method: "POST", body });
    navigateTo({
      path: "/verify-login",
      query: {
        identifier: form.value.identifier,
        type: identifierType.value,
        ...(redirectTarget.value === "/"
          ? {}
          : { redirect: redirectTarget.value }),
      },
    });
  } catch (error) {
    const normalized = normalizeApiError(error);
    errors.value = normalized.errors;
    formError.value = Object.keys(normalized.errors).length
      ? ""
      : normalized.message;
  } finally {
    loading.value = false;
  }
};

const onSubmit = () => {
  if (isOtpMode.value) {
    performOtpRequest();
    return;
  }
  performLogin();
};

const onSocial = async ({ idToken, error }) => {
  socialError.value = "";
  if (error) {
    socialError.value = error.message ?? String(error);
    return;
  }
  loading.value = true;
  try {
    const res = await client("/api/firebase-login", {
      method: "POST",
      body: { token: idToken, ...authDeviceMeta() },
    });
    const token = res?.data?.token ?? res?.token;
    if (token) {
      const sanctum = useSanctumAppConfig();
      await sanctum?.tokenStorage?.set?.(useNuxtApp(), token);
    }
    persistTokenId(res?.data?.token_id ?? res?.token_id);
    await refreshIdentity();
    navigateTo(redirectTarget.value);
  } catch (err) {
    const tokenErr = err?.data?.errors?.token?.[0];
    const map = {
      account_exists_use_password: t(
        "err_account_exists_use_password",
        "An account with this email exists. Use password to log in.",
        "يوجد حساب بهذا البريد. استخدم كلمة المرور.",
      ),
      social_max_accounts_reached: t(
        "err_social_max_accounts_reached",
        "Maximum linked accounts reached.",
        "تم بلوغ الحد الأقصى للحسابات المربوطة.",
      ),
      social_provider_not_allowed: t(
        "err_social_provider_not_allowed",
        "This provider is not allowed.",
        "هذا المزوّد غير مسموح.",
      ),
      invalid_firebase_token: t(
        "err_invalid_firebase_token",
        "Invalid sign-in token. Try again.",
        "رمز الدخول غير صالح. حاول مجددًا.",
      ),
      firebase_email_required: t(
        "err_firebase_email_required",
        "No email returned from provider.",
        "لم يتم إرجاع بريد من المزوّد.",
      ),
      social_auth_requires_email: t(
        "err_social_auth_requires_email",
        "Social login requires an email-based account.",
        "يتطلب تسجيل الدخول الاجتماعي حسابًا بريدًا.",
      ),
    };
    socialError.value =
      map[tokenErr] ??
      tokenErr ??
      err?.data?.message ??
      err?.message ??
      String(err);
  } finally {
    loading.value = false;
  }
};
</script>
