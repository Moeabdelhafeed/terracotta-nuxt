<template>
  <!--
    The link always lands here, app or no app: the curtain, the card and the message ARE the
    gift — a memory, not a hop on the way to the wallet. So the site deliberately has no
    Universal Links / App Links for /gift (no public/.well-known association files), which
    would have sent a phone with the app straight past this page. The app is reached from
    the Claim button instead (see claimGift()).
  -->
  <div>
    <!-- Opened by hand: the gift is behind it, and tapping the mark is the opening of it. -->
    <AppCurtain
      :label="t('gift_open', 'Tap to open your gift', 'اضغط لفتح هديتك')"
      color="#E7938D"
      @opened="celebrate = true"
    />

    <!-- Only once the wrapper is off, and only for a gift there is still something to
         celebrate about — paper over "already claimed" would be a joke at the reader's
         expense. -->
    <AppConfetti
      v-if="celebrate && gift?.is_claimable"
      @done="celebrate = false"
    />

    <main
      ref="root"
      class="relative isolate flex min-h-svh flex-col items-center justify-center overflow-hidden bg-brand-blush px-6 py-16 text-white"
    >
      <!-- The line the rest of the site is drawn with. Decorative only. -->
      <BrandLine class="-z-10 text-white/40" />

      <!-- The glyph, not the CMS's drawn logo: this page is the mark on a colour, exactly
           as the splash paints it — one filled shape taking the ink around it — and a PNG
           of the light logo is a picture of a mark rather than the mark. -->
      <BrandMark ref="mark" class="h-14 w-auto text-white sm:h-16" />

      <div
        ref="card"
        class="mt-8 w-full max-w-md rounded-[2rem] bg-background p-8 text-center text-foreground shadow-2xl sm:p-10"
      >
        <!-- The gift itself. Shown whether or not it can still be claimed: the buyer may be
           checking it landed, or the recipient re-opening their own link. -->
        <template v-if="gift">
          <p class="text-sm text-muted-foreground">{{ fromLine }}</p>

          <p
            class="mt-4 font-display text-5xl font-black leading-none text-brand-blush"
          >
            {{ format(gift.amount) }}
          </p>

          <!-- The buyer's own words, rendered as written — never translated. -->
          <p
            v-if="gift.message"
            class="mt-6 text-lg leading-relaxed break-words"
          >
            “{{ gift.message }}”
          </p>

          <p
            v-if="gift.recipient_name"
            class="mt-4 text-sm text-muted-foreground"
          >
            {{ toLine }}
          </p>

          <div class="my-8 h-px bg-border" />

          <!-- Just claimed, by this visitor. Shown before the "already claimed" branch on
             purpose: the API now says the gift is spent, and telling the person who spent
             it that somebody else got there first would be a lie. -->
          <div v-if="credited" class="flex flex-col gap-4">
            <p
              class="rounded-2xl bg-brand-green/10 px-4 py-4 text-sm font-medium text-brand-green"
            >
              {{
                t(
                  "gift_redeem_done",
                  ":amount has been added to your wallet.",
                  "تمت إضافة :amount إلى محفظتك.",
                  { amount: format(credited.amount) },
                )
              }}
            </p>
            <p class="font-display text-3xl font-black text-foreground">
              {{ format(credited.wallet_balance) }}
            </p>
            <p class="text-xs text-muted-foreground">
              {{
                t("gift_wallet_balance", "Your wallet balance", "رصيد محفظتك")
              }}
            </p>
            <Button
              as-child
              size="lg"
              class="h-14 w-full rounded-2xl bg-brand-blush text-base text-white hover:bg-brand-blush"
            >
              <NuxtLink to="/wallet">{{
                t("gift_go_wallet", "Go to my wallet", "الذهاب إلى محفظتي")
              }}</NuxtLink>
            </Button>
          </div>

          <!-- Claimed: say so plainly and drop the buttons. Who claimed it is not in the
             response, deliberately. -->
          <p
            v-else-if="!gift.is_claimable"
            class="rounded-2xl bg-brand-blush/15 px-4 py-4 text-sm font-medium text-brand-blush"
          >
            {{
              t(
                "gift_claimed",
                "This gift has already been claimed.",
                "تم استلام هذه الهدية من قبل.",
              )
            }}
          </p>

          <template v-else>
            <!-- One button, three routes — see claimGift(). The credit lands in a wallet,
               so on the website there has to be one: a signed-in registered account. -->
            <Button
              size="lg"
              class="h-14 w-full rounded-2xl bg-brand-blush text-base text-white hover:bg-brand-blush"
              :disabled="redeeming || openingApp"
              @click="claimGift"
            >
              {{
                redeeming || openingApp
                  ? t("please_wait", "Please wait...", "يرجى الانتظار...")
                  : canRedeem || appLink
                    ? t("gift_redeem", "Claim your gift", "استلام الهدية")
                    : t(
                        "gift_redeem_sign_in",
                        "Sign in to claim your gift",
                        "سجّل الدخول لاستلام الهدية",
                      )
              }}
            </Button>

            <!-- The server's own words: it is the only thing that knows whether this gift is
               already spent, unpaid, or the buyer's own. -->
            <p v-if="redeemError" class="mt-4 text-sm text-destructive">
              {{ redeemError }}
            </p>


            <div v-if="gift.store_links?.length" class="mt-6">
              <p class="text-xs text-muted-foreground">
                {{
                  t(
                    "gift_get_app",
                    "Do not have the app yet?",
                    "ليس لديك التطبيق بعد؟",
                  )
                }}
              </p>
              <ul class="mt-3 flex flex-wrap items-center justify-center gap-3">
                <li v-for="link in gift.store_links" :key="link.type">
                  <a
                    :href="link.url"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="inline-flex h-11 items-center rounded-xl border px-4 text-sm font-medium transition-colors hover:bg-brand-mist"
                    >{{ storeLabel(link.type) }}</a
                  >
                </li>
              </ul>
            </div>
          </template>
        </template>

        <!-- An unknown token, or a gift the buyer never paid for. The API does not tell the
           two apart, and neither does this. -->
        <template v-else-if="notFound">
          <h1 class="font-display text-2xl font-semibold">
            {{
              t(
                "gift_invalid_title",
                "This gift link isn't valid",
                "رابط الهدية غير صالح",
              )
            }}
          </h1>
          <p class="mt-3 text-sm text-muted-foreground">
            {{
              t(
                "gift_invalid_body",
                "Check the link you were sent, or ask whoever sent it.",
                "تأكد من الرابط الذي وصلك، أو اسأل من أرسله.",
              )
            }}
          </p>
        </template>

        <!-- Never an empty gift shell: "you have been sent 0.00" reads worse than an error. -->
        <template v-else>
          <h1 class="font-display text-2xl font-semibold">
            {{
              t(
                "gift_error_title",
                "We could not open this gift",
                "تعذّر فتح الهدية",
              )
            }}
          </h1>
          <p class="mt-3 text-sm text-muted-foreground">
            {{
              t(
                "gift_error_body",
                "Something went wrong on our side. Try again in a moment.",
                "حدث خطأ لدينا. حاول مرة أخرى بعد قليل.",
              )
            }}
          </p>
          <Button
            variant="outline"
            class="mt-6 h-12 rounded-xl px-8"
            @click="refresh()"
          >
            {{ t("try_again", "Try again", "حاول مرة أخرى") }}
          </Button>
        </template>
      </div>

      <!-- A keepsake of the gift, whatever state it is in: the card as a PDF to keep. -->
      <button
        v-if="gift"
        type="button"
        class="mt-8 inline-flex h-12 items-center gap-2 rounded-2xl border border-white/70 px-6 text-sm font-medium text-white transition-colors hover:bg-white/10 disabled:opacity-60"
        :disabled="saving"
        data-test="gift-save-pdf"
        @click="savePdf"
      >
        <LucideDownload class="size-4" aria-hidden="true" />
        {{
          saving
            ? t("gift_pdf_preparing", "Preparing…", "جارٍ التجهيز…")
            : t("gift_save_pdf", "Save the gift as PDF", "حفظ الهدية بصيغة PDF")
        }}
      </button>

      <NuxtLink
        to="/"
        class="mt-6 text-sm text-white/80 underline-offset-4 transition-colors hover:text-white hover:underline"
      >
        {{
          t("gift_explore", "See what Terracotta makes", "تعرّف على تيراكوتا")
        }}
      </NuxtLink>
    </main>
  </div>
</template>

<script setup>
definePageMeta({
  // No site chrome: the recipient followed a link to one thing.
  layout: "bare",
});

// The gift page has a ground of its own, unlike the rest of the site. Set on the body too
// so an overscroll bounce does not flash white behind it.
useHead({ bodyAttrs: { class: "bg-brand-blush" } });

const route = useRoute();
const { t, dir } = useLang("web", "home");
const { format } = usePrice();

/**
 * Server-rendered on purpose: WhatsApp and iMessage fetch the link to build a preview
 * card and run no JavaScript. The call goes to our own server route, which holds the API
 * token — see server/api/gift/[token].get.js.
 */
const {
  data: gift,
  error,
  refresh,
} = await useFetch(() => `/api/gift/${route.params.token}`, {
  key: () => `gift-${route.params.token}`,
});

const notFound = computed(() => error.value?.statusCode === 404);

const fromLine = computed(() =>
  gift.value?.from
    ? t("gift_from", ":name sent you a gift", ":name أرسل لك هدية", {
        name: gift.value.from,
      })
    : t("gift_from_someone", "You have been sent a gift", "وصلتك هدية"),
);

const toLine = computed(() =>
  gift.value?.recipient_name
    ? t("gift_to", "For :name", "إلى :name", { name: gift.value.recipient_name })
    : "",
);

/**
 * The card as a PDF the recipient keeps (see utils/giftPdf.js). The same words the page
 * shows, in the reader's language, and never the link: the token is the gift.
 */
const saving = ref(false);

// The site's own address under the card, so a printed copy says where it came from.
const siteHost = (() => {
  try {
    return new URL(useSiteConfig().url).host;
  } catch {
    return "";
  }
})();

const savePdf = async () => {
  if (saving.value || !gift.value) return;
  saving.value = true;
  try {
    await saveGiftPdf(
      {
        from: fromLine.value,
        amount: format(gift.value.amount),
        message: gift.value.message,
        to: toLine.value,
        footer: siteHost,
      },
      { dir: dir.value, fileName: "terracotta-gift.pdf" },
    );
  } finally {
    saving.value = false;
  }
};

/**
 * Claiming. The face amount lands in the redeemer's wallet — not what the buyer paid,
 * which this page never sees — and it happens exactly once, so the button is disabled for
 * the duration of the call and the server is the authority on every refusal.
 */
const { redeem } = useGifts();

/**
 * `deep_link` is the app's custom scheme (`terracotta://gift/{token}`), null until the app
 * handles it and GIFT_APP_DEEP_LINK is set. Phones only: the scheme means nothing on a
 * desktop.
 */
const { os } = useDevice();

const appLink = computed(() =>
  ["ios", "android"].includes(os.value)
    ? (gift.value?.deep_link ?? null)
    : null,
);

// A guest session is an anonymous device, not an account with a ledger — it cannot hold
// wallet credit, so it is sent through sign-in like a visitor with no session at all.
const { isRegistered: canRedeem } = useIsRegistered();

/**
 * The claim moves money into the reader's wallet, and every other screen reads that
 * balance off the identity. The ledger is not touched here: this page is public, and a
 * visitor with no session would only earn a 401 for it.
 */
const { refreshIdentity } = useSanctumAuth();

const redeeming = ref(false);
const redeemError = ref("");
const credited = ref(null);

const claim = async () => {
  if (redeeming.value) return;
  redeeming.value = true;
  redeemError.value = "";
  try {
    const res = await redeem(route.params.token);
    credited.value = res?.data ?? null;
    celebrate.value = true;
    refreshIdentity().catch(() => {});
  } catch (err) {
    const normalized = normalizeApiError(err);
    // `errors.gift` carries all four refusals — already redeemed, not paid, your own
    // gift, gifting switched off — already localized.
    redeemError.value = fieldError(normalized, "gift") || normalized.message;
    // Someone else may have claimed it in the meantime; let the server's fresh answer
    // redraw the page rather than leaving a live-looking button under the error.
    await refresh();
  } finally {
    redeeming.value = false;
  }
};

/**
 * `redirect` is a SAME-ORIGIN RELATIVE PATH, never an absolute URL — sign-in sends the
 * reader wherever it points, so anything off-site would be an open redirect on a page
 * strangers are handed by link.
 *
 * The same intent is also parked in `sessionStorage` against this exact token: the query
 * is lost the moment sign-in becomes a cold start (an OTP in another tab, the app taking
 * over the link), and the parked copy is what survives that.
 */
const goSignIn = () => {
  rememberPendingGift(route.params.token);
  return navigateTo({
    path: "/login",
    query: { redirect: `/gift/${route.params.token}` },
  });
};

onMounted(() => {
  if (
    canRedeem.value &&
    gift.value?.is_claimable &&
    takePendingGift(route.params.token)
  )
    claim();
});

/**
 * The Claim button. Signed in here already → claimed here, in one tap: it is the same
 * account and the same wallet the app shows, so nothing is lost by not opening the app.
 * Otherwise, on a phone, the app is tried first and it claims the gift itself. If it
 * doesn't open (not installed, or she cancelled iOS's "Open in Terracotta?"), she signs
 * in on the website, and the parked token claims the gift when she comes back here.
 */
const openingApp = ref(false);

const claimGift = async () => {
  if (canRedeem.value) return claim();

  if (appLink.value) {
    openingApp.value = true;
    const opened = await openApp(appLink.value);
    openingApp.value = false;
    if (opened) {
      // Back from the app, the page shows what happened there (claimed, most likely).
      const reload = () => {
        if (document.visibilityState !== "visible") return;
        document.removeEventListener("visibilitychange", reload);
        refresh();
      };
      document.addEventListener("visibilitychange", reload);
      return;
    }
  }

  return goSignIn();
};

const storeLabel = (type) =>
  ({
    app_store: t("app_store", "App Store", "آب ستور"),
    google_play: t("google_play", "Google Play", "جوجل بلاي"),
    app_gallery: t("app_gallery", "AppGallery", "آب جاليري"),
  })[type] ?? type;

const celebrate = ref(false);

const root = ref(null);
const mark = ref(null);
const card = ref(null);

onMounted(() => {
  const gsap = useGSAP();
  const mm = gsap.matchMedia();

  // The card arrives rather than appearing — the one flourish the page gets, and only for
  // visitors who have not asked for less motion.
  mm.add("(prefers-reduced-motion: no-preference)", () => {
    gsap.from([mark.value?.$el ?? mark.value, card.value], {
      opacity: 0,
      y: 28,
      scale: 0.97,
      duration: 0.7,
      stagger: 0.12,
      ease: "power2.out",
    });
  });

  onBeforeUnmount(() => mm.revert());
});

/**
 * The token is the entitlement — whoever holds it can claim the gift — and previews get
 * screenshotted and forwarded, so it appears in no tag. A claimed or dead link previews
 * generically rather than as a live offer, and the page is never indexed.
 */
const previewTitle = computed(() => {
  if (!gift.value?.is_claimable)
    return t(
      "gift_generic_title",
      "A gift from Terracotta",
      "هدية من تيراكوتا",
    );

  return gift.value.from
    ? t("gift_from", ":name sent you a gift", ":name أرسل لك هدية", {
        name: gift.value.from,
      })
    : t("gift_from_someone", "You have been sent a gift", "وصلتك هدية");
});

const previewDescription = computed(() =>
  gift.value?.is_claimable
    ? t(
        "gift_og_description",
        "A :amount gift from Terracotta",
        "هدية بقيمة :amount من تيراكوتا",
        { amount: format(gift.value.amount) },
      )
    : t(
        "gift_og_generic",
        "Handmade pottery, workshops and pieces from our studio.",
        "فخار مصنوع يدويًا، ورشات وقطع من الاستوديو.",
      ),
);

/**
 * The card WhatsApp and iMessage draw when the link is pasted. They fetch the page with no
 * JavaScript, which is why it is server-rendered, and they want an absolute image URL with
 * its dimensions declared — without those the preview falls back to a small thumbnail.
 *
 * The card itself is generic: previews get screenshotted and forwarded, and possession of
 * the token is the entitlement, so it never appears in a tag.
 */
const previewCard = `${useSiteConfig().url}/og-gift.png`;

useSeoMeta({
  robots: "noindex, nofollow",
  title: () => previewTitle.value,
  ogTitle: () => previewTitle.value,
  description: () => previewDescription.value,
  ogDescription: () => previewDescription.value,
  ogType: "website",
  ogImage: previewCard,
  ogImageSecureUrl: previewCard,
  ogImageType: "image/png",
  ogImageWidth: 1200,
  ogImageHeight: 630,
  ogImageAlt: () => previewTitle.value,
  twitterCard: "summary_large_image",
  twitterImage: previewCard,
  twitterTitle: () => previewTitle.value,
  twitterDescription: () => previewDescription.value,
});
</script>
