<template>
  <main class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />

    <AppConfetti v-if="celebrate" @done="celebrate = false" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div v-if="pending && !gift" aria-busy="true">
        <div class="mx-auto flex max-w-xl flex-col items-center gap-4">
          <AppSkeleton class="size-16 !rounded-full" />
          <AppSkeleton class="h-9 w-2/3" />
        </div>
        <div class="mt-8 grid gap-6 lg:grid-cols-[1fr_22rem] lg:items-start">
          <AppSkeleton class="h-40 w-full !rounded-3xl" />
          <AppSkeleton class="h-40 w-full !rounded-3xl" />
        </div>
      </div>

      <section v-else-if="!gift" class="mx-auto max-w-xl rounded-3xl border bg-card p-6 text-center sm:p-8">
        <h1 class="font-display text-2xl font-semibold">
          {{ t('gift_missing_title', 'Gift not found', 'الهدية غير موجودة') }}
        </h1>
        <p class="mt-3 text-sm text-muted-foreground">
          {{ t('gift_missing_body', 'This gift is not on your account.', 'هذه الهدية ليست ضمن حسابك.') }}
        </p>
        <Button as-child variant="outline" class="mt-6 h-12 rounded-xl px-8">
          <NuxtLink to="/gifts">{{ t('gifts_title', 'My gifts', 'هداياي') }}</NuxtLink>
        </Button>
      </section>

      <template v-else>
        <header class="mx-auto max-w-xl text-center">
          <span
            class="mx-auto flex size-16 items-center justify-center rounded-full"
            :class="cancelled ? 'bg-brand-mist text-muted-foreground' : 'bg-brand-green/10 text-brand-green'"
          >
            <LucideGift class="size-7" />
          </span>

          <h1 class="mt-5 font-display text-3xl font-semibold sm:text-4xl">
            <template v-if="cancelled">{{ t('gift_cancelled_title', 'This gift was cancelled', 'تم إلغاء هذه الهدية') }}</template>
            <template v-else-if="gift.is_redeemed">{{ t('gift_used_title', 'Redeemed', 'تم الاستخدام') }}</template>
            <template v-else-if="held">{{ t('gift_pay_title', 'Payment', 'الدفع') }}</template>
            <template v-else>{{ t('gift_success_title', 'Gift purchased!', 'تم شراء الهدية!') }}</template>
          </h1>

          <p class="mt-3 text-muted-foreground">
            <template v-if="cancelled">{{ t('gift_cancelled_body', 'The payment window closed before it was paid, so the link no longer works.', 'انتهت مهلة الدفع قبل إتمامه، لذلك لم يعد الرابط يعمل.') }}</template>
            <template v-else-if="gift.is_redeemed">{{ t('gift_used_body', 'Redeemed on :date.', 'تم استخدامها بتاريخ :date.', { date: formatDate(gift.redeemed_at) }) }}</template>
            <template v-else-if="held">{{ t('gift_pay_body', 'Confirm the gift and pay to get your share link.', 'أكّد الهدية وادفع للحصول على رابط المشاركة.') }}</template>
            <template v-else>{{ t('gift_success_body', 'Copy the link and send it to whoever the gift is for, so they can enjoy our Terracotta workshops.', 'الرجاء نسخ الرابط و ارساله لمتلقي الهدية و الاستمتاع بورشات تيراكوتا') }}</template>
          </p>
        </header>

        <div class="mt-8 grid gap-6 lg:grid-cols-[1fr_22rem] lg:items-start">
          <div class="flex min-w-0 flex-col gap-6">
            <!-- The hold is still running: same pay step as the purchase page, so a buyer
                 who navigated away can finish here. -->
            <CheckoutPaymentHold
              v-if="held"
              :amount-due="gift.amount_due"
              :payment-status="gift.payment_status"
              :expires-at="gift.payment_expires_at"
              :pay="payGift"
              restart-to="/gifts/new"
              @paid="onPaid"
              @expired="refresh()"
            />

            <!-- Paid and unclaimed: the link is the product. -->
            <section v-else-if="!cancelled" class="rounded-3xl border bg-card p-6 sm:p-8">
              <GiftShare
                v-if="!gift.is_redeemed"
                :share-url="gift.share_url"
                :recipient-phone="gift.recipient_phone"
                :recipient-name="gift.recipient_name"
              />
              <p v-else class="rounded-2xl bg-brand-green/10 px-4 py-4 text-center text-sm font-medium text-brand-green">
                {{ t('gift_used_note', 'The credit is already in their wallet — the link is spent.', 'تم إضافة الرصيد إلى محفظتهم — الرابط مستخدم.') }}
              </p>
            </section>

            <dl class="flex flex-col gap-2 rounded-3xl border bg-card p-6 text-sm sm:p-8">
              <div class="flex items-center justify-between gap-4">
                <dt class="text-muted-foreground">{{ t('gift_recipient', 'For', 'المهدى له') }}</dt>
                <dd class="font-medium">{{ gift.recipient_name }}</dd>
              </div>
              <div v-if="gift.recipient_phone" class="flex items-center justify-between gap-4">
                <dt class="text-muted-foreground">{{ t('gift_recipient_phone', 'Phone', 'رقم الجوال') }}</dt>
                <dd class="font-medium" dir="ltr">{{ gift.recipient_phone }}</dd>
              </div>
              <div v-if="gift.message" class="flex flex-col gap-1 border-t pt-2">
                <dt class="text-muted-foreground">{{ t('gift_message', 'Message to them', 'رسالة اليها') }}</dt>
                <dd class="whitespace-pre-line break-words">{{ gift.message }}</dd>
              </div>
              <div class="flex items-center justify-between gap-4 border-t pt-2">
                <dt class="text-muted-foreground">{{ t('gift_credit', 'Credit', 'الرصيد') }}</dt>
                <dd class="font-display text-lg font-semibold text-primary">{{ format(gift.amount) }}</dd>
              </div>
            </dl>
          </div>

          <aside class="flex flex-col gap-4">
            <CheckoutSummary :quote="summaryQuote" :title="t('gift_summary', 'Gift summary', 'ملخص الهدية')" />

            <Button as-child variant="outline" class="h-12 rounded-xl">
              <NuxtLink to="/gifts">{{ t('close', 'Close', 'اغلاق') }}</NuxtLink>
            </Button>
          </aside>
        </div>
      </template>
    </div>
  </main>
</template>

<script setup>
/**
 * One gift the buyer owns — the success screen right after a purchase and the detail page
 * afterwards, because they show the same thing: the share link, who it is for, and what
 * it cost.
 *
 * There is no `GET /api/gifts/{id}` (an integer id 404s on the public token route), so
 * the row comes out of `GET /api/gifts`. `?new=1` is what the purchase flow sets to earn
 * the confetti; a reload without it shows the same page, quietly.
 */
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'gift-detail',
})

const route = useRoute()
const { t } = useLang('web', 'gifts')
const { format } = usePrice()
const { formatDate } = useDateFormat()
const { list, pay } = useGifts()

const { items, pending, refresh } = list()

const gift = computed(() => items.value.find((row) => String(row.id) === String(route.params.id)) ?? null)

const cancelled = computed(() => gift.value?.status === 'cancelled')
const held = computed(() => gift.value?.status === 'awaiting_payment' && !isZeroMoney(gift.value.amount_due))

// A gift has nothing to deliver; `null` tells the summary to drop the row.
const summaryQuote = computed(() => (gift.value ? { ...gift.value, delivery_fee: null } : null))

const celebrate = ref(false)
onMounted(() => {
  if (route.query.new && gift.value && !held.value) celebrate.value = true
})

const crumbs = computed(() => [
  { label: t('gifts_title', 'My gifts', 'هداياي'), to: '/gifts' },
  { label: gift.value?.recipient_name ?? t('gift_detail_title', 'Gift', 'الهدية') },
])

const payGift = () => pay(gift.value.id)

const onPaid = async () => {
  await refresh()
  celebrate.value = true
}

useSeoMeta({ title: () => t('gift_detail_title', 'Gift', 'الهدية'), robots: 'noindex, nofollow' })
</script>
