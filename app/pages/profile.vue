<template>
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-3">
        <h1 class="font-display text-2xl font-bold text-foreground">
          {{ t("profile", "My account", "حسابي") }}
        </h1>

        <div class="rounded-2xl border bg-card p-5">
          <div class="flex items-center gap-3">
            <div
              class="flex size-14 shrink-0 items-center justify-center rounded-full bg-brand-rust text-lg font-semibold text-white"
            >
              {{ initials }}
            </div>
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <p
                  class="truncate font-display text-lg font-semibold text-foreground"
                >
                  {{ profile?.name || "—" }}
                </p>
                <button
                  type="button"
                  class="text-brand-rust/80 transition-colors hover:text-brand-rust"
                  :aria-label="t('edit_name', 'Edit name', 'تعديل الاسم')"
                  @click="openEditName"
                >
                  <LucidePencil class="size-4" />
                </button>
              </div>
              <p class="truncate text-sm text-muted-foreground" dir="ltr">
                {{
                  profile?.phone || profile?.email || profile?.username || ""
                }}
              </p>
            </div>
          </div>

          <NuxtLink
            to="/wallet"
            class="mt-4 flex items-center justify-between rounded-xl bg-brand-mist/60 px-4 py-3 transition-colors hover:bg-brand-mist"
          >
            <span
              class="flex items-center gap-2 text-sm font-medium text-foreground"
            >
              <LucideWallet class="size-4 text-brand-rust" />
              {{ t("my_wallet", "My wallet", "محفظتي") }}
            </span>
            <span
              class="flex items-center gap-1 text-sm font-semibold text-brand-rust"
            >
              {{ formatPrice(profile?.wallet_balance) }}
              <LucideChevronRight class="size-4 rtl:-scale-x-100" />
            </span>
          </NuxtLink>
        </div>

        <NuxtLink
          v-for="row in hubRows"
          :key="row.to"
          :to="row.to"
          :data-test="`hub-${row.to.slice(1)}`"
          class="group flex items-center justify-between rounded-2xl border bg-card p-4 text-sm font-medium text-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        >
          <span class="flex items-center gap-3">
            <component
              :is="row.icon"
              class="size-5 text-foreground/70 group-hover:text-accent-foreground"
            />
            {{ row.label }}
          </span>
          <span class="flex items-center gap-2">
            <span
              v-if="row.badge"
              data-test="unread-badge"
              class="min-w-5 rounded-full bg-brand-rust px-1.5 py-0.5 text-center text-xs font-semibold text-white"
              dir="ltr"
              >{{ row.badge }}</span
            >
            <LucideChevronRight
              class="size-4 text-muted-foreground rtl:-scale-x-100 group-hover:text-accent-foreground"
            />
          </span>
        </NuxtLink>

        <NuxtLink
          v-if="multiSession"
          to="/devices"
          class="group flex items-center justify-between rounded-2xl border bg-card p-4 text-sm font-medium text-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        >
          <span class="flex items-center gap-3">
            <LucideMonitorSmartphone
              class="size-5 text-foreground/70 group-hover:text-accent-foreground"
            />
            {{ t("active_devices", "Active devices", "الأجهزة النشطة") }}
          </span>
          <LucideChevronRight
            class="size-4 text-muted-foreground rtl:-scale-x-100 group-hover:text-accent-foreground"
          />
        </NuxtLink>

        <button
          v-if="socialAuthAvailable && socialProviders.length"
          type="button"
          class="group flex items-center justify-between rounded-2xl border bg-card p-4 text-start text-sm font-medium text-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          @click="socialOpen = true"
        >
          <span class="flex items-center gap-3">
            <LucideLink2
              class="size-5 text-foreground/70 group-hover:text-accent-foreground"
            />
            {{ t("social_accounts", "Social accounts", "الحسابات الاجتماعية") }}
          </span>
          <LucideChevronRight
            class="size-4 text-muted-foreground rtl:-scale-x-100 group-hover:text-accent-foreground"
          />
        </button>

        <button
          v-if="!isOtpMode"
          type="button"
          class="group flex items-center justify-between rounded-2xl border bg-card p-4 text-start text-sm font-medium text-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          @click="openChangePassword"
        >
          <span class="flex items-center gap-3">
            <LucideLock
              class="size-5 text-foreground/70 group-hover:text-accent-foreground"
            />
            {{
              hasPassword
                ? t("change_password", "Change password", "تغيير كلمة السر")
                : t("set_password", "Set password", "تعيين كلمة المرور")
            }}
          </span>
          <LucideChevronRight
            class="size-4 text-muted-foreground rtl:-scale-x-100 group-hover:text-accent-foreground"
          />
        </button>

        <button
          type="button"
          class="group flex items-center justify-between rounded-2xl border bg-card p-4 text-start text-sm font-medium text-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          @click="openChangeIdentifier"
        >
          <span class="flex items-center gap-3">
            <LucideSmartphone
              class="size-5 text-foreground/70 group-hover:text-accent-foreground"
            />
            {{
              t("change_kind", "Change :kind", "تغيير :kind", {
                kind: identifierKindLabel.toLowerCase(),
              })
            }}
          </span>
          <LucideChevronRight
            class="size-4 text-muted-foreground rtl:-scale-x-100 group-hover:text-accent-foreground"
          />
        </button>

        <button
          type="button"
          class="group flex items-center justify-between rounded-2xl border bg-card p-4 text-start text-sm font-medium text-foreground transition-colors hover:bg-accent hover:text-accent-foreground disabled:opacity-50"
          :disabled="loggingOut"
          @click="handleLogout"
        >
          <span class="flex items-center gap-3">
            <LucideLogOut
              class="size-5 text-foreground/70 group-hover:text-accent-foreground"
            />
            {{
              loggingOut
                ? t("logging_out", "Logging out...", "جارٍ تسجيل الخروج...")
                : t("logout", "Sign out", "تسجيل الخروج")
            }}
          </span>
          <LucideChevronRight
            class="size-4 text-muted-foreground rtl:-scale-x-100 group-hover:text-accent-foreground"
          />
        </button>

        <button
          type="button"
          class="flex items-center justify-between rounded-2xl border bg-card p-4 text-start text-sm font-medium text-destructive transition-colors hover:bg-destructive/10 disabled:opacity-50"
          :disabled="deleting"
          @click="deleteDialogOpen = true"
        >
          <span class="flex items-center gap-3">
            <LucideTrash2 class="size-5" />
            {{
              deleting
                ? t("deleting", "Deleting...", "جارٍ الحذف...")
                : t("delete_account", "Delete account", "حذف الحساب")
            }}
          </span>
          <LucideChevronRight class="size-4 rtl:-scale-x-100" />
        </button>
      </div>
    </div>

    <!-- Edit name (+ any other identifier extras the config still asks for) -->
    <Teleport to="body">
      <div
        v-if="editNameOpen"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 py-10"
        role="dialog"
        aria-modal="true"
      >
        <div
          class="absolute inset-0 bg-black/50"
          @click="profileLoading || (editNameOpen = false)"
        />
        <div
          class="relative w-full max-w-md rounded-2xl border bg-background p-6 shadow-lg"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span
                class="flex size-9 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust"
              >
                <LucidePencil class="size-4" />
              </span>
              <h2 class="font-display text-lg font-semibold text-foreground">
                {{ t("edit_name", "Edit name", "تعديل الاسم") }}
              </h2>
            </div>
            <button
              type="button"
              class="text-muted-foreground transition-colors hover:text-foreground"
              @click="editNameOpen = false"
            >
              <LucideX class="size-5" />
            </button>
          </div>

          <form
            class="mt-5 flex flex-col gap-4"
            @submit.prevent="onUpdateProfile"
          >
            <div class="grid gap-2">
              <Input
                id="name"
                v-model="profileForm.name"
                type="text"
                class="h-12 rounded-xl text-base"
              />
              <span
                v-if="profileErrors.name"
                class="text-xs text-destructive"
                >{{ profileErrors.name[0] }}</span
              >
            </div>

            <div v-if="hasUsername" class="grid gap-2">
              <Label for="profile_username">
                {{ labelFor("username") }}
                <span
                  v-if="!isExtraRequired('username')"
                  class="text-xs text-muted-foreground"
                  >{{ t("optional", "(optional)", "(اختياري)") }}</span
                >
              </Label>
              <Input
                id="profile_username"
                v-model="profileForm.username"
                type="text"
                class="h-12 rounded-xl text-base"
                :placeholder="placeholderFor('username')"
              />
              <span
                v-if="profileErrors.username"
                class="text-xs text-destructive"
                >{{ profileErrors.username[0] }}</span
              >
            </div>

            <div v-if="hasEmail" class="grid gap-2">
              <Label for="profile_email">
                {{ labelFor("email") }}
                <span
                  v-if="!isExtraRequired('email')"
                  class="text-xs text-muted-foreground"
                  >{{ t("optional", "(optional)", "(اختياري)") }}</span
                >
              </Label>
              <Input
                id="profile_email"
                v-model="profileForm.email"
                type="email"
                class="h-12 rounded-xl text-base"
                :placeholder="placeholderFor('email')"
              />
              <span
                v-if="profileErrors.email"
                class="text-xs text-destructive"
                >{{ profileErrors.email[0] }}</span
              >
            </div>

            <div v-if="hasPhone" class="grid gap-2">
              <Label for="profile_phone">
                {{ labelFor("phone") }}
                <span
                  v-if="!isExtraRequired('phone')"
                  class="text-xs text-muted-foreground"
                  >{{ t("optional", "(optional)", "(اختياري)") }}</span
                >
              </Label>
              <AuthPhoneInput
                id="profile_phone"
                v-model="profileForm.phone"
                :allowed="allowedPhoneCountries"
              />
              <span
                v-if="profileErrors.phone"
                class="text-xs text-destructive"
                >{{ profileErrors.phone[0] }}</span
              >
            </div>

            <div class="mt-2 flex gap-3">
              <Button
                type="button"
                variant="outline"
                class="h-12 flex-1 rounded-xl text-base"
                :disabled="profileLoading"
                @click="editNameOpen = false"
              >
                {{ t("cancel", "Cancel", "إلغاء") }}
              </Button>
              <Button
                type="submit"
                class="h-12 flex-1 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
                :disabled="profileLoading"
              >
                {{
                  profileLoading
                    ? t("saving", "Saving...", "جارٍ الحفظ...")
                    : t("save", "Save", "حفظ")
                }}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- Change password -->
    <Teleport to="body">
      <div
        v-if="changePasswordOpen"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 py-10"
        role="dialog"
        aria-modal="true"
      >
        <div
          class="absolute inset-0 bg-black/50"
          @click="passwordLoading || (changePasswordOpen = false)"
        />
        <div
          class="relative w-full max-w-md rounded-2xl border bg-background p-6 shadow-lg"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span
                class="flex size-9 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust"
              >
                <LucideLock class="size-4" />
              </span>
              <h2 class="font-display text-lg font-semibold text-foreground">
                {{
                  hasPassword
                    ? t("change_password", "Change password", "تغيير كلمة السر")
                    : t("set_password", "Set password", "تعيين كلمة المرور")
                }}
              </h2>
            </div>
            <button
              type="button"
              class="text-muted-foreground transition-colors hover:text-foreground"
              @click="changePasswordOpen = false"
            >
              <LucideX class="size-5" />
            </button>
          </div>
          <p class="mt-1 text-sm text-muted-foreground">
            {{
              hasPassword
                ? t(
                    "change_password_description",
                    "Revokes all other sessions.",
                    "يلغي كل الجلسات الأخرى.",
                  )
                : t(
                    "set_password_description",
                    "Add a password so you can log in without a social provider.",
                    "أضف كلمة مرور لتسجيل الدخول بدون مزوّد اجتماعي.",
                  )
            }}
          </p>

          <form
            class="mt-5 flex flex-col gap-4"
            @submit.prevent="onChangePassword"
          >
            <div v-if="hasPassword" class="grid gap-2">
              <Label for="old_password">{{
                t("current_password", "Current password", "كلمة المرور الحالية")
              }}</Label>
              <AuthPasswordInput
                id="old_password"
                v-model="passwordForm.old_password"
                required
              />
              <span
                v-if="passwordErrors.old_password"
                class="text-xs text-destructive"
                >{{ passwordErrors.old_password[0] }}</span
              >
            </div>
            <div class="grid gap-2">
              <Label for="new_password">{{
                t("new_password", "New password", "كلمة مرور جديدة")
              }}</Label>
              <AuthPasswordInput
                id="new_password"
                v-model="passwordForm.password"
                required
              />
              <span
                v-if="passwordErrors.password"
                class="text-xs text-destructive"
                >{{ passwordErrors.password[0] }}</span
              >
            </div>
            <div class="grid gap-2">
              <Label for="confirm_password">{{
                t("confirm_password", "Confirm password", "تأكيد كلمة المرور")
              }}</Label>
              <AuthPasswordInput
                id="confirm_password"
                v-model="passwordForm.password_confirmation"
                required
              />
              <span
                v-if="passwordErrors.password_confirmation"
                class="text-xs text-destructive"
                >{{ passwordErrors.password_confirmation[0] }}</span
              >
            </div>

            <div class="mt-2 flex gap-3">
              <Button
                type="button"
                variant="outline"
                class="h-12 flex-1 rounded-xl text-base"
                :disabled="passwordLoading"
                @click="changePasswordOpen = false"
              >
                {{ t("cancel", "Cancel", "إلغاء") }}
              </Button>
              <Button
                type="submit"
                class="h-12 flex-1 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
                :disabled="passwordLoading"
              >
                {{
                  passwordLoading
                    ? t("saving", "Saving...", "جارٍ الحفظ...")
                    : t("save", "Save", "حفظ")
                }}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- Change phone/email (identifier), OTP-protected -->
    <Teleport to="body">
      <div
        v-if="changeIdentifierOpen"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 py-10"
        role="dialog"
        aria-modal="true"
      >
        <div
          class="absolute inset-0 bg-black/50"
          @click="
            identifierLoading ||
            identifierVerifying ||
            (changeIdentifierOpen = false)
          "
        />
        <div
          class="relative w-full max-w-md rounded-2xl border bg-background p-6 shadow-lg"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span
                class="flex size-9 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust"
              >
                <LucideSmartphone class="size-4" />
              </span>
              <h2 class="font-display text-lg font-semibold text-foreground">
                {{
                  t("change_kind", "Change :kind", "تغيير :kind", {
                    kind: identifierKindLabel.toLowerCase(),
                  })
                }}
              </h2>
            </div>
            <button
              type="button"
              class="text-muted-foreground transition-colors hover:text-foreground"
              @click="changeIdentifierOpen = false"
            >
              <LucideX class="size-5" />
            </button>
          </div>
          <p class="mt-1 text-sm text-muted-foreground">
            {{
              t(
                "change_kind_description",
                "OTP-protected :kind change.",
                "تغيير :kind محمي برمز.",
                { kind: identifierKindLabel.toLowerCase() },
              )
            }}
          </p>

          <div class="mt-5 flex flex-col gap-4">
            <div v-if="isMultiIdentifier" class="flex flex-wrap gap-2">
              <Button
                v-for="kind in identifiers"
                :key="kind"
                type="button"
                size="sm"
                class="rounded-xl"
                :variant="identifierKind === kind ? 'default' : 'outline'"
                @click="identifierKind = kind"
                >{{ labelFor(kind) }}</Button
              >
            </div>
            <div class="grid gap-2">
              <Label
                :for="
                  identifierKind === 'phone'
                    ? 'new_identifier_phone'
                    : 'new_identifier'
                "
                >{{
                  t("new_kind", "New :kind", ":kind جديد", {
                    kind: identifierKindLabel.toLowerCase(),
                  })
                }}</Label
              >
              <AuthPhoneInput
                v-if="identifierKind === 'phone'"
                id="new_identifier_phone"
                v-model="identifierForm.new_identifier"
                :allowed="allowedPhoneCountries"
              />
              <Input
                v-else
                id="new_identifier"
                v-model="identifierForm.new_identifier"
                :type="inputTypeFor(identifierKind)"
                class="h-12 rounded-xl text-base"
                :placeholder="placeholderFor(identifierKind)"
              />
              <span
                v-if="identifierErrors.new_identifier || identifierErrors.type"
                class="text-xs text-destructive"
                >{{
                  (identifierErrors.new_identifier ?? identifierErrors.type)[0]
                }}</span
              >
            </div>

            <div v-if="!otpSent" class="mt-2 flex gap-3">
              <Button
                type="button"
                variant="outline"
                class="h-12 flex-1 rounded-xl text-base"
                @click="changeIdentifierOpen = false"
              >
                {{ t("cancel", "Cancel", "إلغاء") }}
              </Button>
              <Button
                class="h-12 flex-1 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
                :disabled="identifierLoading"
                @click="onRequestIdentifierChange"
              >
                {{
                  identifierLoading
                    ? t("sending", "Sending...", "جارٍ الإرسال...")
                    : t("send_otp", "Send OTP", "إرسال الرمز")
                }}
              </Button>
            </div>

            <div v-else class="flex flex-col items-center gap-4 border-t pt-4">
              <AuthOtpInput v-model="identifierForm.otp" />
              <span
                v-if="identifierErrors.otp"
                class="text-xs text-destructive"
                >{{ identifierErrors.otp[0] }}</span
              >
              <Button
                class="h-12 w-full rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
                :disabled="identifierVerifying"
                @click="onVerifyIdentifierChange"
                >{{
                  identifierVerifying
                    ? t("verifying", "Verifying...", "جارٍ التحقق...")
                    : t("verify_and_save", "Verify & save", "تحقق واحفظ")
                }}</Button
              >
              <button
                type="button"
                class="text-xs text-muted-foreground underline-offset-4 hover:underline"
                @click="otpSent = false"
              >
                {{ t("cancel", "Cancel", "إلغاء") }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Social accounts -->
    <Teleport to="body">
      <div
        v-if="socialOpen"
        class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 py-10"
        role="dialog"
        aria-modal="true"
      >
        <div class="absolute inset-0 bg-black/50" @click="socialOpen = false" />
        <div
          class="relative w-full max-w-md rounded-2xl border bg-background p-6 shadow-lg"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span
                class="flex size-9 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust"
              >
                <LucideLink2 class="size-4" />
              </span>
              <h2 class="font-display text-lg font-semibold text-foreground">
                {{
                  t("social_accounts", "Social accounts", "الحسابات الاجتماعية")
                }}
              </h2>
            </div>
            <button
              type="button"
              class="text-muted-foreground transition-colors hover:text-foreground"
              @click="socialOpen = false"
            >
              <LucideX class="size-5" />
            </button>
          </div>
          <p class="mt-1 text-sm text-muted-foreground">
            {{
              t(
                "manage_social_providers",
                "Connect or disconnect providers linked to your account.",
                "اربط أو افصل المزودين المرتبطين بحسابك.",
              )
            }}
          </p>

          <div class="mt-5 flex flex-col gap-3">
            <p
              v-if="!hasPassword"
              class="rounded-xl bg-brand-rust/10 p-3 text-xs text-brand-rust"
            >
              {{
                t(
                  "set_password_cta",
                  "Set a password to enable email/password login and to allow disconnecting your last social provider.",
                  "عيّن كلمة مرور لتفعيل تسجيل الدخول بالبريد/كلمة المرور وللسماح بفك ربط آخر مزوّد اجتماعي.",
                )
              }}
            </p>
            <div v-if="socialLoading" class="text-sm text-muted-foreground">
              {{ t("loading", "Loading...", "جارٍ التحميل...") }}
            </div>
            <ul v-else class="flex flex-col gap-2">
              <li
                v-for="p in socialProviders"
                :key="p"
                class="flex items-center justify-between gap-3 rounded-xl border p-3 text-sm"
              >
                <div class="flex min-w-0 flex-col">
                  <span class="font-medium text-foreground">{{
                    providerLabel(p)
                  }}</span>
                  <span
                    v-if="findLinked(p)"
                    class="truncate text-xs text-muted-foreground"
                    >{{ findLinked(p).email ?? findLinked(p).name }}</span
                  >
                </div>
                <template v-if="findLinked(p)">
                  <Button
                    variant="outline"
                    size="sm"
                    class="rounded-xl"
                    :disabled="
                      unlinking === p ||
                      (linkedProviders.length === 1 && !hasPassword)
                    "
                    @click="onUnlinkSocial(p)"
                    >{{
                      unlinking === p
                        ? t("unlinking", "Unlinking...", "جارٍ فك الربط...")
                        : t("disconnect", "Disconnect", "فك الربط")
                    }}</Button
                  >
                </template>
                <template v-else>
                  <Button
                    size="sm"
                    class="rounded-xl bg-brand-rust hover:bg-brand-rust/90"
                    :disabled="!canLinkMore || connecting === p"
                    @click="onConnectProvider(p)"
                    >{{
                      connecting === p
                        ? t("connecting", "Connecting...", "جارٍ الربط...")
                        : t("connect", "Connect", "ربط")
                    }}</Button
                  >
                </template>
              </li>
            </ul>
            <p
              v-if="!canLinkMore && maxSocialAccounts > 0"
              class="text-xs text-muted-foreground"
            >
              {{
                t(
                  "linked_accounts_limit_reached",
                  "Linked accounts limit reached (:max).",
                  "تم بلوغ الحد الأقصى للحسابات المربوطة (:max).",
                  { max: maxSocialAccounts },
                )
              }}
            </p>
            <span v-if="socialErrors.token" class="text-xs text-destructive">{{
              socialErrorText("token")
            }}</span>
            <span
              v-if="socialErrors.provider"
              class="text-xs text-destructive"
              >{{ socialErrorText("provider") }}</span
            >
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Delete account -->
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
        <div
          class="relative w-full max-w-md rounded-2xl border bg-background p-6 shadow-lg"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span
                class="flex size-9 items-center justify-center rounded-xl bg-destructive/10 text-destructive"
              >
                <LucideTrash2 class="size-4" />
              </span>
              <h2 class="font-display text-lg font-semibold text-destructive">
                {{ t("delete_account", "Delete account", "حذف الحساب") }}
              </h2>
            </div>
            <button
              type="button"
              class="text-muted-foreground transition-colors hover:text-foreground"
              @click="deleteDialogOpen = false"
            >
              <LucideX class="size-5" />
            </button>
          </div>
          <p class="mt-2 text-sm text-muted-foreground">
            {{
              t(
                "delete_account_confirm",
                "Permanently delete your account? This cannot be undone.",
                "حذف الحساب نهائيًا؟ لا يمكن التراجع.",
              )
            }}
          </p>
          <div class="mt-6 flex flex-col gap-3 sm:flex-row">
            <Button
              variant="outline"
              class="h-12 flex-1 rounded-xl text-base"
              :disabled="deleting"
              @click="deleteDialogOpen = false"
            >
              {{ t("cancel", "Cancel", "إلغاء") }}
            </Button>
            <Button
              variant="destructive"
              class="h-12 flex-1 rounded-xl text-base"
              :disabled="deleting"
              @click="confirmDeleteAccount"
            >
              {{
                deleting
                  ? t("deleting", "Deleting...", "جارٍ الحذف...")
                  : t("delete_account", "Delete account", "حذف الحساب")
              }}
            </Button>
          </div>
        </div>
      </div>
    </Teleport>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ["auth-mode", "require-registered", "verified"],
  name: "profile",
});

const { user, logout, refreshIdentity } = useSanctumAuth();
const { format: formatPrice } = usePrice();
const client = useApi();
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
  allowedPhoneCountries,
} = useAuthConfig();
const { t } = useLang("web", "profile");
const { signInWithProvider } = useFirebaseAuth();

const editNameOpen = ref(false);
const changePasswordOpen = ref(false);
const changeIdentifierOpen = ref(false);
const socialOpen = ref(false);

const identifierKind = ref(identifiers.value[0] ?? "email");
watch(
  identifiers,
  (list) => {
    if (list.length && !list.includes(identifierKind.value)) {
      identifierKind.value = list[0];
    }
  },
  { immediate: true },
);

const identifierKindLabel = computed(() => labelFor(identifierKind.value));

// Every account destination lives on this hub — nothing is reachable only by typing a URL.
const { unreadCount } = useUnreadCount();
const hubRows = computed(() => [
  {
    to: "/orders",
    icon: "LucideShoppingBag",
    label: t("my_orders", "My orders", "طلباتي"),
  },
  {
    to: "/bookings",
    icon: "LucideCalendarDays",
    label: t("my_bookings", "My workshops", "ورشاتي"),
  },
  {
    to: "/my-gallery",
    icon: "LucideImages",
    label: t("my_gallery", "My gallery", "معرضي"),
  },
  {
    to: "/favorites",
    icon: "LucideHeart",
    label: t("my_favorites", "My favourites", "منتجاتي المفضلة"),
  },
  {
    to: "/gifts",
    icon: "LucideGift",
    label: t("my_gifts", "My gifts", "هداياي"),
  },
  {
    to: "/addresses",
    icon: "LucideMapPin",
    label: t("my_addresses", "My addresses", "عناويني"),
  },
  {
    to: "/notifications",
    icon: "LucideBell",
    label: t("notifications_title", "Notifications", "الإشعارات"),
    badge: unreadCount.value || 0,
  },
  {
    to: "/complaints",
    icon: "LucideMessageSquareWarning",
    label: t("complaints_title", "Complaints", "الشكاوى"),
  },
]);

const profile = computed(() => user.value?.data ?? user.value ?? null);
const initials = computed(
  () => (profile.value?.name || "").trim().charAt(0).toUpperCase() || "•",
);

const loggingOut = ref(false);
const handleLogout = async () => {
  loggingOut.value = true;
  try {
    await logout();
    if (import.meta.client)
      document.cookie = "current_token_id=; path=/; max-age=0";
    navigateTo({ name: "login" });
  } finally {
    loggingOut.value = false;
  }
};

const profileForm = ref({ name: "", username: "", email: "", phone: "" });
const profileErrors = ref({});
const profileLoading = ref(false);

watchEffect(() => {
  const p = profile.value;
  if (!p) return;
  profileForm.value = {
    name: p.name ?? "",
    username: p.username ?? "",
    email: p.email ?? "",
    phone: p.phone ?? "",
  };
});

const openEditName = () => {
  profileErrors.value = {};
  editNameOpen.value = true;
};

const buildProfileBody = () => {
  const body = { name: profileForm.value.name };
  const include = (kind, has) => {
    if (!has) return false;
    if (isExtraRequired(kind)) return true;
    return !!profileForm.value[kind];
  };
  if (include("username", hasUsername.value))
    body.username = profileForm.value.username;
  if (include("email", hasEmail.value)) body.email = profileForm.value.email;
  if (include("phone", hasPhone.value)) body.phone = profileForm.value.phone;
  return body;
};

const onUpdateProfile = async () => {
  profileErrors.value = {};
  profileLoading.value = true;
  try {
    await client("/api/update-profile", {
      method: "PUT",
      body: buildProfileBody(),
    });
    await refreshIdentity();
    editNameOpen.value = false;
  } catch (error) {
    profileErrors.value = error.data?.errors ?? {};
  } finally {
    profileLoading.value = false;
  }
};

const passwordForm = ref({
  old_password: "",
  password: "",
  password_confirmation: "",
});
const passwordErrors = ref({});
const passwordLoading = ref(false);

const openChangePassword = () => {
  passwordErrors.value = {};
  passwordForm.value = {
    old_password: "",
    password: "",
    password_confirmation: "",
  };
  changePasswordOpen.value = true;
};

const onChangePassword = async () => {
  passwordErrors.value = {};
  passwordLoading.value = true;
  try {
    const body = {
      password: passwordForm.value.password,
      password_confirmation: passwordForm.value.password_confirmation,
      ...(hasPassword.value
        ? { old_password: passwordForm.value.old_password }
        : {}),
    };
    await client("/api/change-password", { method: "POST", body });
    passwordForm.value = {
      old_password: "",
      password: "",
      password_confirmation: "",
    };
    await refreshIdentity();
    changePasswordOpen.value = false;
  } catch (error) {
    passwordErrors.value = error.data?.errors ?? {};
  } finally {
    passwordLoading.value = false;
  }
};

const identifierForm = ref({ new_identifier: "", otp: "" });
const identifierErrors = ref({});
const identifierLoading = ref(false);
const identifierVerifying = ref(false);
const otpSent = ref(false);

const openChangeIdentifier = () => {
  identifierErrors.value = {};
  identifierForm.value = { new_identifier: "", otp: "" };
  otpSent.value = false;
  changeIdentifierOpen.value = true;
};

const onRequestIdentifierChange = async () => {
  identifierErrors.value = {};
  identifierLoading.value = true;
  try {
    await client("/api/request-identifier-change", {
      method: "POST",
      // The picker above (or the single configured identifier) declares the kind; the
      // API validates against it instead of guessing, so a phone must carry its country code.
      body: {
        new_identifier: identifierForm.value.new_identifier,
        type: identifierKind.value,
      },
    });
    otpSent.value = true;
  } catch (error) {
    identifierErrors.value = error.data?.errors ?? {};
  } finally {
    identifierLoading.value = false;
  }
};

const onVerifyIdentifierChange = async () => {
  identifierErrors.value = {};
  identifierVerifying.value = true;
  try {
    await client("/api/verify-identifier-change", {
      method: "POST",
      body: { ...identifierForm.value, type: identifierKind.value },
    });
    await refreshIdentity();
    otpSent.value = false;
    identifierForm.value = { new_identifier: "", otp: "" };
    changeIdentifierOpen.value = false;
  } catch (error) {
    identifierErrors.value = error.data?.errors ?? {};
  } finally {
    identifierVerifying.value = false;
  }
};

const socialErrors = ref({});
const connecting = ref(null);
const unlinking = ref(null);

const {
  data: socialData,
  pending: socialLoading,
  refresh: loadSocialAccounts,
} = useApiFetch("/api/social-accounts", {
  key: "social-accounts",
});

// Tolerate both shapes: data is array OR { social_accounts: [...] }
const socialAccounts = computed(() => {
  const d = socialData.value?.data ?? socialData.value;
  if (Array.isArray(d)) return d;
  return d?.social_accounts ?? [];
});

const linkedProviders = computed(() =>
  socialAccounts.value.map((a) => a.provider),
);
const findLinked = (p) => socialAccounts.value.find((a) => a.provider === p);
const hasPassword = computed(() => !!profile.value?.has_password);

const canLinkMore = computed(() => {
  if (!maxSocialAccounts.value) return true;
  return socialAccounts.value.length < maxSocialAccounts.value;
});

const socialErrorMap = computed(() => ({
  invalid_firebase_token: t(
    "err_invalid_firebase_token",
    "Invalid sign-in token.",
    "رمز الدخول غير صالح.",
  ),
  social_provider_not_allowed: t(
    "err_social_provider_not_allowed",
    "This provider is not allowed.",
    "هذا المزوّد غير مسموح.",
  ),
  social_email_mismatch: t(
    "err_social_email_mismatch",
    "Provider email does not match your account.",
    "بريد المزوّد لا يطابق حسابك.",
  ),
  social_account_already_linked: t(
    "err_social_account_already_linked",
    "This account is already linked to another user.",
    "هذا الحساب مربوط بمستخدم آخر.",
  ),
  social_provider_already_linked: t(
    "err_social_provider_already_linked",
    "Provider already linked.",
    "هذا المزوّد مربوط بالفعل.",
  ),
  social_max_accounts_reached: t(
    "err_social_max_accounts_reached",
    "Maximum linked accounts reached.",
    "تم بلوغ الحد الأقصى للحسابات المربوطة.",
  ),
  social_auth_requires_email: t(
    "err_social_auth_requires_email",
    "Social login requires an email-based account.",
    "يتطلب تسجيل الدخول الاجتماعي حسابًا بريدًا.",
  ),
  social_provider_not_linked: t(
    "err_social_provider_not_linked",
    "Provider is not currently linked.",
    "هذا المزوّد غير مربوط حاليًا.",
  ),
  cannot_unlink_last_social_account: t(
    "err_cannot_unlink_last_social_account",
    "Set a password before unlinking your last social provider.",
    "عيّن كلمة مرور قبل فك ربط آخر مزوّد.",
  ),
}));

const socialErrorText = (key) => {
  const raw = socialErrors.value?.[key]?.[0];
  if (!raw) return "";
  return socialErrorMap.value[raw] ?? raw;
};

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

const onConnectProvider = async (p) => {
  socialErrors.value = {};
  connecting.value = p;
  try {
    const { idToken } = await signInWithProvider(p);
    await client("/api/link-social-account", {
      method: "POST",
      body: { token: idToken },
    });
    await loadSocialAccounts();
    await refreshIdentity();
  } catch (error) {
    socialErrors.value = error?.data?.errors ?? {
      token: [error?.message ?? String(error)],
    };
  } finally {
    connecting.value = null;
  }
};

const onUnlinkSocial = async (provider) => {
  socialErrors.value = {};
  unlinking.value = provider;
  try {
    await client("/api/unlink-social-account", {
      method: "DELETE",
      body: { provider },
    });
    await loadSocialAccounts();
    await refreshIdentity();
  } catch (error) {
    socialErrors.value = error.data?.errors ?? {};
  } finally {
    unlinking.value = null;
  }
};

onMounted(() => {
  if (socialAuthAvailable.value) loadSocialAccounts();
});

const deleting = ref(false);
const deleteDialogOpen = ref(false);
const confirmDeleteAccount = async () => {
  deleting.value = true;
  try {
    await client("/api/delete-account", { method: "DELETE" });
    await logout().catch(() => {});
    if (import.meta.client)
      document.cookie = "current_token_id=; path=/; max-age=0";
    navigateTo({ name: "login" });
  } catch {
    deleting.value = false;
  } finally {
    deleteDialogOpen.value = false;
  }
};
</script>
