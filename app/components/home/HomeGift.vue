<template>
  <!-- Off entirely when the studio is not selling gift credit — the same switch every
       other gift surface reads. -->
  <section v-if="packageActive" id="gift" class="relative overflow-hidden bg-[#FC8B8B] py-12 text-white">
    <!-- The hero's own line, static here: one drawn line runs through the page. -->
    <CardLineArt class="absolute inset-0 size-full opacity-30" />

    <div class="relative mx-auto grid max-w-6xl gap-8 px-6 lg:grid-cols-2 lg:items-center">
      <div>
        <p class="text-xs uppercase tracking-[0.2em] text-white/75">
          {{ t("gift_eyebrow", "Gift credit", "إهداء رصيد") }}
        </p>

        <h2 class="mt-2 font-display text-2xl font-bold sm:text-3xl">
          <template v-if="packageAmount">
            {{
              t("gift_new_title", "Gift :amount of credit", "اهداء رصيد :amount", {
                amount: format(packageAmount),
              })
            }}
          </template>
          <template v-else>
            {{ t("gift_eyebrow", "Gift credit", "إهداء رصيد") }}
          </template>
        </h2>

        <p class="mt-3 max-w-xl text-sm text-white/85">
          {{
            t(
              "gift_new_subtitle",
              "Send a credit gift to someone you love, to enjoy our pottery and ceramics workshops.",
              "أرسل هدية رصيد لأحبائك للاستمتاع بورشات الفخار والسيراميك",
            )
          }}
        </p>

        <Button
          as-child
          class="mt-6 h-14 rounded-2xl bg-white px-8 text-base text-[#FC8B8B] hover:bg-white/90"
        >
          <NuxtLink to="/gifts/new">
            {{ t("gift_send_cta", "Send a gift", "أرسل هدية") }}
          </NuxtLink>
        </Button>
      </div>

      <!-- The three steps the gift actually takes, in the order they happen. -->
      <ol class="grid gap-2">
        <li
          v-for="(step, index) in steps"
          :key="step"
          class="flex items-start gap-3 rounded-card bg-white/15 p-4"
        >
          <span
            class="flex size-7 shrink-0 items-center justify-center rounded-full bg-white/25 font-display text-xs font-bold text-white"
            dir="ltr"
          >{{ index + 1 }}</span>
          <p class="text-sm leading-snug text-white/90">{{ step }}</p>
        </li>
      </ol>
    </div>
  </section>
</template>

<script setup>
/**
 * Gift credit, on the home page. The copy is the gift pages' own — one wording for one
 * offer, so the section and the page a reader lands on agree.
 */
const { t } = useLang("web", "home");
const { format } = usePrice();
const { packageActive, packageAmount } = useGifts();

const steps = computed(() => [
  t(
    "gift_step_buy",
    "Pay for the gift and write who it is for.",
    "ادفع قيمة الهدية واكتب لمن هي.",
  ),
  t(
    "gift_step_share",
    "Send them the link — by WhatsApp, or however you like.",
    "أرسل لهم الرابط — عبر واتساب أو كما تحب.",
  ),
  t(
    "gift_step_claim",
    "They claim it, and the credit lands in their balance.",
    "يستلمونها، ويضاف الرصيد إلى محفظتهم.",
  ),
]);
</script>
