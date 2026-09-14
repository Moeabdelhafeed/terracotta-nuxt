<template>
  <div class="rounded-2xl border bg-card p-5">
    <!-- Settled on creation: the wallet (or a full discount) covered everything. -->
    <div v-if="state === 'settled'" class="flex items-start gap-3">
      <span
        class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-brand-green/10 text-brand-green"
      >
        <LucideCheckCircle2 class="size-5" />
      </span>
      <div>
        <p class="font-display text-base font-semibold text-foreground">
          {{ t("hold_settled_title", "All paid", "تم الدفع بالكامل") }}
        </p>
        <p class="mt-1 text-sm text-muted-foreground">
          {{
            t(
              "hold_settled_body",
              "Nothing left to pay — you are all set.",
              "لا يوجد مبلغ متبقٍ — كل شيء جاهز.",
            )
          }}
        </p>
      </div>
    </div>

    <!-- The hold lapsed: the sweeper returns seat / stock / wallet / discount; start over. -->
    <div v-else-if="state === 'expired'" class="flex flex-col gap-4">
      <div class="flex items-start gap-3">
        <span
          class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-destructive/10 text-destructive"
        >
          <LucideTimerOff class="size-5" />
        </span>
        <div>
          <p class="font-display text-base font-semibold text-foreground">
            {{
              t(
                "hold_expired_title",
                "Payment window closed",
                "انتهت مهلة الدفع",
              )
            }}
          </p>
          <p class="mt-1 text-sm text-muted-foreground">
            {{
              expiredMessage ||
              t(
                "hold_expired_body",
                "This payment window has closed. Please start again.",
                "انتهت مهلة الدفع. يرجى البدء من جديد.",
              )
            }}
          </p>
        </div>
      </div>
      <Button
        v-if="restartTo"
        as-child
        class="h-12 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
      >
        <NuxtLink :to="restartTo">{{
          restartLabel || t("start_again", "Start again", "البدء من جديد")
        }}</NuxtLink>
      </Button>
    </div>

    <!-- Held: count down to `payment_expires_at`, then pay. -->
    <div v-else class="flex flex-col gap-4">
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <span
            class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-brand-rust/10 text-brand-rust"
          >
            <LucideTimer class="size-5" />
          </span>
          <div>
            <p class="text-sm font-medium text-foreground">
              {{ t("hold_reserved", "Reserved for you", "محجوز لك") }}
            </p>
            <p class="text-xs text-muted-foreground">
              {{
                t(
                  "hold_pay_within",
                  "Complete payment before the timer runs out.",
                  "أكمل الدفع قبل انتهاء الوقت.",
                )
              }}
            </p>
          </div>
        </div>
        <span
          class="font-display text-2xl font-semibold tabular-nums"
          :class="remaining <= 60 ? 'text-destructive' : 'text-foreground'"
          dir="ltr"
          >{{ clock }}</span
        >
      </div>

      <div
        class="flex items-center justify-between gap-3 rounded-xl bg-brand-mist/40 px-4 py-3"
      >
        <span class="text-sm text-muted-foreground">{{
          t("summary_amount_due", "Amount due", "المبلغ المستحق")
        }}</span>
        <span class="font-display text-lg font-black text-primary sm:text-xl">{{
          format(amountDue)
        }}</span>
      </div>

      <span v-if="errorText" class="text-xs text-destructive">{{
        errorText
      }}</span>

      <Button
        type="button"
        class="h-12 w-full rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
        :disabled="paying"
        @click="onPay"
      >
        {{
          paying
            ? t("paying", "Paying...", "جارٍ الدفع...")
            : t("pay_now", "Pay now", "ادفع الآن")
        }}
      </Button>
    </div>
  </div>
</template>

<script setup>
/**
 * The pay step every held purchase shares (workshop booking, shop order, gift).
 *
 * Give it the object the create call returned — `amount_due`, `payment_status`,
 * `payment_expires_at` — and a `pay` handler that calls the flow's `/pay` route. It
 * decides which of three states to show:
 *
 *  - settled  — `amount_due` is `"0.00"` (or already paid): no button, no countdown.
 *  - held     — countdown from `payment_expires_at`; a pay button that is disabled while
 *               a call is in flight, so a double tap sends one request (and `/pay` is
 *               idempotent server-side anyway).
 *  - expired  — the clock hit zero, or the server answered `payment_hold_expired`.
 *
 * The client's clock is not the source of truth: when it reaches zero the component
 * emits `expired` so the page refetches and lets the server's answer decide.
 */
const props = defineProps({
  amountDue: { type: [String, Number], default: "0.00" },
  paymentStatus: { type: String, default: "unpaid" },
  expiresAt: { type: String, default: null },
  /** `async () => response` — should call the flow's `/pay` endpoint. */
  pay: { type: Function, required: true },
  /** Where "Start again" goes once the hold has lapsed. */
  restartTo: { type: [String, Object], default: null },
  restartLabel: { type: String, default: "" },
});

const emit = defineEmits(["paid", "expired", "error"]);

const { t } = useLang("web", "checkout");
const { format } = usePrice();

const paying = ref(false);
const errorText = ref("");
const expiredMessage = ref("");
const forcedExpired = ref(false);
const now = ref(Date.now());

const expiresMs = computed(() =>
  props.expiresAt ? new Date(props.expiresAt).getTime() : NaN,
);
const remaining = computed(() =>
  Number.isNaN(expiresMs.value)
    ? 0
    : Math.max(0, Math.floor((expiresMs.value - now.value) / 1000)),
);

const state = computed(() => {
  if (props.paymentStatus === "paid" || isZeroMoney(props.amountDue))
    return "settled";
  if (forcedExpired.value) return "expired";
  if (!props.expiresAt || remaining.value <= 0) return "expired";
  return "held";
});

const clock = computed(() => {
  const m = Math.floor(remaining.value / 60);
  const s = remaining.value % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
});

let timer = null;
const tick = () => {
  now.value = Date.now();
};

onMounted(() => {
  tick();
  timer = setInterval(tick, 1000);
});
onBeforeUnmount(() => {
  if (timer) clearInterval(timer);
});

watch(state, (value, previous) => {
  if (value === "expired" && previous === "held") emit("expired");
});

const onPay = async () => {
  if (paying.value) return;
  paying.value = true;
  errorText.value = "";
  try {
    const res = await props.pay();
    emit("paid", res);
  } catch (err) {
    const normalized = err?.errors ? err : normalizeApiError(err);
    // The server is the authority on the window: its refusal flips the state even if the
    // local clock still shows seconds left.
    const holdKeys = ["booking", "order", "gift"];
    const holdMessage = holdKeys
      .map((key) => fieldError(normalized, key))
      .find(Boolean);
    if (normalized.status === 422 && holdMessage) {
      expiredMessage.value = holdMessage;
      forcedExpired.value = true; // the state watcher emits `expired`
    } else {
      errorText.value =
        normalized.message ||
        t(
          "payment_failed",
          "Payment failed. Please try again.",
          "فشل الدفع. حاول مرة أخرى.",
        );
      emit("error", normalized);
    }
  } finally {
    paying.value = false;
  }
};
</script>
