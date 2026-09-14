<template>
  <main class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <!-- Gifting can be switched off entirely: the package goes inactive and quote/create
           refuse with `gift_unavailable`. Say so once, at the top, instead of letting the
           buyer fill a form that cannot be submitted. -->
      <section
        v-if="unavailable"
        class="mx-auto max-w-xl rounded-3xl border bg-card p-6 text-center sm:p-8"
      >
        <span
          class="mx-auto flex size-12 items-center justify-center rounded-2xl bg-brand-rust/10 text-brand-rust"
        >
          <LucideGift class="size-5" />
        </span>
        <h1 class="mt-5 font-display text-2xl font-semibold">
          {{
            t(
              "gift_off_title",
              "Gift credit is unavailable",
              "إهداء الرصيد غير متاح حاليًا",
            )
          }}
        </h1>
        <p class="mt-3 text-sm text-muted-foreground">
          {{
            unavailableMessage ||
            t(
              "gift_off_body",
              "Gifting is switched off right now. Please check back later.",
              "خدمة الإهداء متوقفة حاليًا. يرجى المحاولة لاحقًا.",
            )
          }}
        </p>
        <Button as-child variant="outline" class="mt-6 h-12 rounded-xl px-8">
          <NuxtLink to="/gifts">{{
            t("gifts_title", "My gifts", "هداياي")
          }}</NuxtLink>
        </Button>
      </section>

      <template v-else>
        <header class="mx-auto max-w-xl text-center">
          <p class="text-xs uppercase tracking-[0.2em] text-muted-foreground">
            {{ t("gift_eyebrow", "Gift credit", "إهداء رصيد") }}
          </p>
          <h1 class="mt-3 font-display text-3xl font-semibold sm:text-4xl">
            <span v-if="packageAmount">{{
              t(
                "gift_new_title",
                "Gift :amount of credit",
                "اهداء رصيد :amount",
                { amount: format(packageAmount) },
              )
            }}</span>
            <AppSkeleton v-else class="mx-auto h-9 w-64" />
          </h1>
          <p class="mt-3 text-muted-foreground">
            {{
              t(
                "gift_new_subtitle",
                "Send a credit gift to someone you love, to enjoy our pottery and ceramics workshops.",
                "أرسل هدية رصيد لأحبائك للاستمتاع بورشات الفخار والسيراميك",
              )
            }}
          </p>
        </header>

        <!-- Step two of the same purchase, not a new page: the hold is already placed and
             the countdown is running, so the form is out of the way but the summary stays. -->
        <div
          v-if="gift"
          class="mx-auto mt-10 grid max-w-4xl gap-6 lg:grid-cols-[1fr_22rem] lg:items-start"
        >
          <section class="rounded-3xl border bg-card p-6 sm:p-8">
            <h2 class="font-display text-2xl font-semibold">
              {{ t("gift_pay_title", "Payment", "الدفع") }}
            </h2>
            <p class="mt-2 text-sm text-muted-foreground">
              {{
                t(
                  "gift_pay_body",
                  "Confirm the gift and pay to get your share link.",
                  "أكّد الهدية وادفع للحصول على رابط المشاركة.",
                )
              }}
            </p>

            <dl
              class="mt-6 flex flex-col gap-2 rounded-2xl bg-brand-mist/40 p-4 text-sm"
            >
              <div class="flex items-center justify-between gap-4">
                <dt class="text-muted-foreground">
                  {{ t("gift_recipient", "For", "المهدى له") }}
                </dt>
                <dd class="font-medium">{{ gift.recipient_name }}</dd>
              </div>
              <div
                v-if="gift.recipient_phone"
                class="flex items-center justify-between gap-4"
              >
                <dt class="text-muted-foreground">
                  {{ t("gift_recipient_phone", "Phone", "رقم الهاتف") }}
                </dt>
                <dd class="font-medium" dir="ltr">
                  {{ gift.recipient_phone }}
                </dd>
              </div>
            </dl>

            <div class="mt-6">
              <CheckoutPaymentHold
                :amount-due="gift.amount_due"
                :payment-status="gift.payment_status"
                :expires-at="gift.payment_expires_at"
                :pay="payGift"
                restart-to="/gifts/new"
                @paid="onPaid"
              />
            </div>
          </section>

          <CheckoutSummary
            :quote="summaryQuote"
            :title="t('gift_summary', 'Gift summary', 'ملخص الهدية')"
          />
        </div>

        <!-- Step one: who it is for, what it says, and what it costs. -->
        <form
          v-else
          class="mx-auto mt-10 grid max-w-4xl gap-6 lg:grid-cols-[1fr_22rem] lg:items-start"
          @submit.prevent="purchase"
        >
          <section
            class="flex flex-col gap-5 rounded-3xl border bg-card p-6 sm:p-8"
          >
            <div class="flex flex-col gap-2">
              <Label for="recipient_name">{{
                t("gift_recipient_name", "Recipient's name", "اسم المهدى له")
              }}</Label>
              <Input
                id="recipient_name"
                v-model="form.recipient_name"
                type="text"
                maxlength="255"
                required
                class="h-12 rounded-xl text-base"
                :placeholder="
                  t('gift_recipient_name_ph', 'e.g. Sara', 'مثال: سارة')
                "
              />
              <span
                v-if="fieldError(errors, 'recipient_name')"
                class="text-xs text-destructive"
                >{{ fieldError(errors, "recipient_name") }}</span
              >
            </div>

            <div class="flex flex-col gap-2">
              <Label for="recipient_phone">
                {{ t("gift_recipient_phone", "Phone", "رقم الهاتف") }}
                <span class="text-xs font-normal text-muted-foreground"
                  >({{ t("optional", "optional", "اختياري") }})</span
                >
              </Label>
              <AuthPhoneInput
                id="recipient_phone"
                v-model="form.recipient_phone"
                :allowed="allowedPhoneCountries"
              />
              <p class="text-xs text-muted-foreground">
                {{
                  t(
                    "gift_phone_hint",
                    "For your own record, and to open WhatsApp with the link ready. Nothing is sent automatically.",
                    "لسجلك الخاص، ولفتح واتساب والرابط جاهز. لا يُرسل شيء تلقائيًا.",
                  )
                }}
              </p>
              <span
                v-if="fieldError(errors, 'recipient_phone')"
                class="text-xs text-destructive"
                >{{ fieldError(errors, "recipient_phone") }}</span
              >
            </div>

            <div class="flex flex-col gap-2">
              <Label for="gift_message">
                {{ t("gift_message", "Message to them", "رسالة اليها") }}
                <span class="text-xs font-normal text-muted-foreground"
                  >({{ t("optional", "optional", "اختياري") }})</span
                >
              </Label>
              <textarea
                id="gift_message"
                v-model="form.message"
                rows="4"
                maxlength="1000"
                class="w-full resize-y rounded-xl border border-input bg-transparent px-4 py-3 text-base shadow-xs outline-none transition-[color,box-shadow] placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
                :placeholder="
                  t(
                    'gift_message_ph',
                    'Write your message here...',
                    'اكتب رسالتك هنا...',
                  )
                "
              />
              <div class="flex items-center justify-between gap-4">
                <span
                  v-if="fieldError(errors, 'message')"
                  class="text-xs text-destructive"
                  >{{ fieldError(errors, "message") }}</span
                >
                <span class="ms-auto text-xs tabular-nums text-muted-foreground"
                  >{{ form.message.length }}/1000</span
                >
              </div>
            </div>

            <div class="h-px bg-border" />

            <CheckoutDiscountCodeInput
              v-model="discountCode"
              :errors="discountErrors"
              :disabled="busy"
            />
            <CheckoutWalletToggle v-model="useWallet" :disabled="busy" />
          </section>

          <aside class="flex flex-col gap-4">
            <CheckoutSummary
              :quote="summaryQuote"
              :title="t('gift_summary', 'Gift summary', 'ملخص الهدية')"
            />

            <p
              v-if="giftValue"
              class="rounded-2xl bg-brand-green/10 px-4 py-3 text-sm text-brand-green"
            >
              {{
                t(
                  "gift_value_note",
                  "They receive :amount in wallet credit.",
                  "سيصله رصيد بقيمة :amount في المحفظة.",
                  { amount: format(giftValue) },
                )
              }}
            </p>

            <span v-if="topError" class="text-sm text-destructive">{{
              topError
            }}</span>

            <Button
              type="submit"
              class="h-12 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
              :disabled="busy || !quote"
            >
              <LucideGift class="size-4" />
              {{
                creating
                  ? t("please_wait", "Please wait...", "يرجى الانتظار...")
                  : t("gift_pay_cta", "Pay", "الدفع")
              }}
            </Button>

            <Button
              as-child
              type="button"
              variant="outline"
              class="h-12 rounded-xl"
            >
              <NuxtLink to="/gifts">{{
                t("close", "Close", "اغلاق")
              }}</NuxtLink>
            </Button>
          </aside>
        </form>
      </template>
    </div>
  </main>
</template>

<script setup>
/**
 * Buying gift credit. The package is a fixed amount decided by the backend, so the only
 * things the buyer chooses are who it is for, what it says, and how it is paid — which
 * makes this the shortest of the four two-phase checkouts: quote → create (hold) → pay.
 *
 * The frame labels a single field «اسم المهدى له» and prefills it with a phone number.
 * The API takes both — `recipient_name` (required) and `recipient_phone` (optional) —
 * and they mean different things, so the one field is split into two here.
 *
 * There is no payment gateway: the frame's Apple Pay / G Pay / VISA tiles have nothing
 * behind them, and `POST /api/gifts/{id}/pay` settles on its own. `<CheckoutPaymentHold>` is the
 * whole pay step.
 */
definePageMeta({
  middleware: ["auth-mode", "require-registered", "verified"],
  name: "gift-new",
});

const { t } = useLang("web", "gifts");
const { format } = usePrice();
const { allowedPhoneCountries } = useAuthConfig();
const {
  packageAmount,
  packageActive,
  packageStatus,
  quote: quoteGift,
  create,
  pay,
} = useGifts();

const crumbs = computed(() => [
  { label: t("gifts_title", "My gifts", "هداياي"), to: "/gifts" },
  { label: t("gift_new_short", "New gift", "هدية جديدة") },
]);

const form = ref({ recipient_name: "", recipient_phone: "", message: "" });
const discountCode = ref("");
const useWallet = ref(false);

const quote = ref(null);
const gift = ref(null);
const quoting = ref(false);
const discountErrors = ref({});

const {
  submit: submitCreate,
  pending: creating,
  errors,
  error: createError,
} = useSubmit();

const busy = computed(() => quoting.value || creating.value);

// The gift is a fixed credit amount — there is nothing to deliver, so the summary's
// delivery row is meaningless here. `null` is the "this flow has no delivery" signal.
const summaryQuote = computed(() =>
  quote.value ? { ...quote.value, delivery_fee: null } : null,
);
const giftValue = computed(
  () => quote.value?.gift_value ?? packageAmount.value,
);

const unavailableMessage = ref("");
const unavailable = computed(
  () =>
    unavailableMessage.value !== "" ||
    (packageStatus.value === "success" && !packageActive.value),
);

const topError = computed(
  () => fieldError(errors.value, "gift") || createError.value,
);

/**
 * The server owns every number, so every input that can move one re-quotes. Only the
 * wallet flag and the discount code do — the recipient's name and message are notes.
 */
const runQuote = async () => {
  quoting.value = true;
  try {
    const res = await quoteGift({
      use_wallet: useWallet.value,
      discount_code: discountCode.value || null,
    });
    quote.value = res?.data ?? null;
    discountErrors.value = {};
  } catch (err) {
    const normalized = normalizeApiError(err);
    if (fieldError(normalized, "gift"))
      unavailableMessage.value = normalized.message;
    discountErrors.value = normalized.errors;
    // A refused code must not leave a stale total on screen; the component drops the code
    // and this watcher fires again without it.
    if (!fieldError(normalized, "discount_code")) quote.value = null;
  } finally {
    quoting.value = false;
  }
};

watch([useWallet, discountCode], runQuote);
// A code the buyer is retyping should not keep showing the refusal of the last one.
watch(discountCode, (code) => {
  if (code) discountErrors.value = {};
});

onMounted(runQuote);

const purchase = async () => {
  try {
    const { data } = await submitCreate(() =>
      create({
        recipient_name: form.value.recipient_name,
        message: form.value.message || null,
        recipient_phone: form.value.recipient_phone || null,
        use_wallet: useWallet.value,
        discount_code: discountCode.value || null,
      }),
    );

    quote.value = { ...quote.value, ...data };

    // Settled at create — the wallet or a discount covered the whole package. There is
    // no hold and nothing to pay: `/pay` must not be called.
    if (isZeroMoney(data.amount_due)) {
      await navigateTo({ path: `/gifts/${data.id}`, query: { new: "1" } });
      return;
    }

    gift.value = data;
  } catch (err) {
    // `errors.gift` on create is `gift_unavailable` — gifting went off between the quote
    // and the button. The whole form is moot, so the page flips to the off state.
    if (fieldError(err, "gift")) unavailableMessage.value = err.message;
    discountErrors.value = err?.errors ?? {};
  }
};

const payGift = () => pay(gift.value.id);

const onPaid = (res) => {
  navigateTo({ path: `/gifts/${gift.value.id}`, query: { new: "1" } });
  return res;
};

useSeoMeta({
  title: () => t("gift_new_short", "New gift", "هدية جديدة"),
  robots: "noindex, nofollow",
});
</script>
