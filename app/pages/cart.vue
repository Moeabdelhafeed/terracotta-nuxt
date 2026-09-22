<template>
  <main class="bg-background">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <h1 class="font-display text-3xl font-semibold sm:text-4xl">
        {{ t("cart_title", "My cart", "عربيتي") }}
      </h1>

      <div
        v-if="(pending || !mounted) && !items.length"
        class="mt-8 grid gap-6 lg:grid-cols-[1fr_20rem] lg:items-start"
        aria-busy="true"
      >
        <div class="flex flex-col gap-4">
          <AppSkeleton
            v-for="n in 3"
            :key="n"
            class="h-32 w-full rounded-card!"
          />
        </div>
        <AppSkeleton class="h-48 w-full rounded-sheet!" />
      </div>

      <!-- A basket that failed to load is not an empty basket: "your cart is empty"
           told to someone whose request 500'd hides whatever is actually in it. -->
      <AppLoadError v-else-if="error" :error="error" :retry="refresh" class="mt-8" />

      <div
        v-else-if="!items.length"
        class="mx-auto mt-8 max-w-xl rounded-sheet border bg-card p-8 text-center sm:p-12"
      >
        <span
          class="mx-auto flex size-14 items-center justify-center rounded-card bg-brand-terracotta/10 text-brand-terracotta"
        >
          <LucideShoppingBag class="size-6" />
        </span>
        <p class="mt-4 font-display text-xl font-semibold">
          {{ t("cart_empty_title", "Your cart is empty", "عربيتك فاضية") }}
        </p>
        <p class="mt-2 text-sm text-muted-foreground">
          {{
            t(
              "cart_empty_body",
              "Pick a piece from the shop and it will show up here.",
              "اختر قطعة من المتجر وستظهر هنا.",
            )
          }}
        </p>
        <Button
          as-child
          class="mt-6 h-12 rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
        >
          <NuxtLink to="/shop">{{
            t("browse_shop", "Browse the shop", "تصفح المتجر")
          }}</NuxtLink>
        </Button>
      </div>

      <div
        v-else
        class="mt-8 grid gap-6 lg:grid-cols-[1fr_20rem] lg:items-start"
      >
        <ShopCartLines />

        <aside class="rounded-sheet border bg-card p-6 sm:p-8 lg:sticky lg:top-6">
          <div class="flex items-center justify-between gap-4">
            <span class="text-sm text-muted-foreground">{{
              t("summary_total", "Total", "الإجمالي", { subGroup: "checkout" })
            }}</span>
            <span
              class="font-display text-xl font-black text-primary sm:text-2xl"
              >{{ format(total) }}</span
            >
          </div>
          <p class="mt-1 text-xs text-muted-foreground">
            {{
              t(
                "cart_total_note",
                "Delivery, discounts and your wallet are applied at checkout.",
                "يُحتسب التوصيل والخصومات والمحفظة عند الدفع.",
              )
            }}
          </p>

          <p
            v-if="hasOutOfStock"
            class="mt-4 flex items-start gap-2 rounded-card bg-destructive/10 px-4 py-3 text-sm text-destructive"
          >
            <LucideAlertCircle class="mt-0.5 size-4 shrink-0" />
            <span>{{
              t(
                "cart_blocked",
                "One of these pieces can no longer be fulfilled. Adjust or remove it to continue.",
                "إحدى هذه القطع لم تعد متوفرة. عدّلها أو أزلها للمتابعة.",
              )
            }}</span>
          </p>

          <Button
            type="button"
            :disabled="!canCheckout"
            class="mt-6 h-12 w-full bg-brand-terracotta text-base hover:bg-brand-terracotta/90"
            @click="onPay"
          >
            {{
              isRegistered
                ? // "Pay" names a figure that is not what gets charged: the cart total is
                  // goods only — delivery, any discount and the wallet are all settled at
                  // checkout, so a 200 basket with a 15 delivery fee said "Pay 200" and
                  // then took 215.
                  t("checkout_with_total", "Checkout — :amount", "إتمام الشراء — :amount", {
                    amount: format(total),
                  })
                : t(
                    "sign_in_to_check_out",
                    "Sign in to check out",
                    "سجّل الدخول لإتمام الشراء",
                  )
            }}
          </Button>
        </aside>
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ["auth-mode"],
  name: "cart",
});

/**
 * The basket. Lines that can no longer be fulfilled stay visible and greyed — they are
 * the reason the pay button is dead, so hiding them would hide the fix. Totals here are
 * goods only; delivery, discounts and the wallet are the checkout quote's business.
 *
 * A visitor without an account gets the same basket out of localStorage, but paying still
 * needs a real account — the button sends them to sign in and back to checkout.
 */
const { t } = useLang("web", "shop");
const { format } = usePrice();
const { items, total, hasOutOfStock, canCheckout, pending, error, refresh } =
  useCart();
const { isRegistered, account } = useIsRegistered();

// The local basket only exists after hydration; without this the empty panel flashes.
const mounted = useMounted();

/**
 * Both gates here rather than at `/checkout`: finding out you need an account, or that
 * the account needs verifying, at the payment step is worse than being told now.
 */
const onPay = () => {
  if (!isRegistered.value) return useLoginPrompt().ask("/checkout");
  if (!account.value?.verified_at) return navigateTo({ name: "verify" });
  return navigateTo("/checkout");
};

const crumbs = computed(() => [
  {
    to: "/",
    label: t("nav_home", "Home", "الرئيسية", { subGroup: "general" }),
  },
  {
    to: "/shop",
    label: t("nav_shop", "Shop", "المتجر", { subGroup: "general" }),
  },
  { label: t("cart_title", "My cart", "عربيتي") },
]);

useSeoMeta({
  title: () => t("cart_title", "My cart", "عربيتي"),
  robots: "noindex",
});
</script>
