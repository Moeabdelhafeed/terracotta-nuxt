<template>
  <main class="bg-background">
    <!-- The same hero the booking tab carries: the two are one hub, and losing the
         picture halfway through reads as landing on a different site. -->
    <PageHero
      media-key="hero_workshops"
      fallback="/seed/hero-workshops.webp"
      :crumbs="crumbs"
      :title="t('workshops_title', 'The workshop experience', 'تجربة الورشة')"
      :subtitle="
        t(
          'workshops_subtitle',
          'Hands-on sessions with an instructor — shape or paint your piece step by step in the studio.',
          'جلسات عملية بإشراف مدرّبين تصنع أو تلوّن قطعتك خطوة بخطوة داخل الاستوديو',
        )
      "
    />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <GiftWalletGiftRow class="mb-8" />

      <WorkshopHubTabs />

      <!-- A tab appears once the customer has something in that status; the counts come
           from `meta.status_counts`, which covers the whole history whatever is filtered. -->
      <div class="mt-8 flex flex-wrap items-center gap-3">
        <ul
          class="-mx-6 flex flex-1 gap-2 overflow-x-auto scrollbar-none px-6 pb-1"
          data-test="status-tabs"
        >
          <li v-for="tab in tabs" :key="tab.key" class="shrink-0">
            <Button
              size="sm"
              class="rounded-xl"
              :variant="tab.key === activeTab ? 'default' : 'outline'"
              :class="
                tab.key === activeTab
                  ? 'bg-brand-terracotta hover:bg-brand-terracotta/90'
                  : ''
              "
              :data-status="tab.key"
              @click="apply({ status: tab.key === 'all' ? null : tab.key })"
            >
              {{ tab.label }}
              <span
                v-if="tab.count !== null"
                class="ms-2 rounded-full px-2 text-xs"
                :class="tab.key === activeTab ? 'bg-white/20' : 'bg-muted'"
                >{{ tab.count }}</span
              >
            </Button>
          </li>
        </ul>

        <label class="sr-only" for="bookings-sort">{{
          t("sort_by", "Sort by", "ترتيب حسب")
        }}</label>
        <Select
          :model-value="activeSort"
          @update:model-value="
            (value) => apply({ sort: value === 'newest' ? null : value })
          "
        >
          <!-- The label, not <SelectValue>: reka only learns an item's text once its
               portal has mounted, so a closed trigger would render empty on first paint. -->
          <SelectTrigger id="bookings-sort" data-test="sort-select" class="h-12 rounded-xl text-sm">
            {{ sortLabel(activeSort) }}
          </SelectTrigger>
          <SelectContent>
            <SelectItem v-for="option in BOOKING_SORTS" :key="option" :value="option">
              {{ sortLabel(option) }}
            </SelectItem>
          </SelectContent>
        </Select>
      </div>

      <ul
        v-if="pending && !items.length"
        class="mt-8 grid auto-rows-fr gap-4 lg:grid-cols-2"
        aria-busy="true"
      >
        <li v-for="n in 4" :key="n"><WorkshopCardSkeleton /></li>
      </ul>

      <AppLoadError
        v-else-if="error"
        data-test="bookings-error"
        :error="error"
        :retry="refresh"
      />

      <p
        v-else-if="!items.length"
        class="mx-auto mt-8 max-w-xl rounded-card border border-dashed p-10 text-center text-muted-foreground"
      >
        {{
          activeTab === "all"
            ? t(
                "bookings_empty",
                "You have no bookings yet.",
                "لا يوجد لديك حجوزات بعد",
              )
            : t(
                "bookings_empty_filtered",
                "No bookings match this filter.",
                "لا توجد حجوزات تطابق هذا التصنيف.",
              )
        }}
      </p>

      <ul v-else class="mt-8 grid auto-rows-fr gap-4 lg:grid-cols-2">
        <li v-for="booking in items" :key="booking.id">
          <BookingCard :booking="booking" />
        </li>
      </ul>

      <!-- Real links, so a page is shareable and crawlable rather than a click handler. -->
      <nav
        v-if="lastPage > 1"
        class="mt-12 flex flex-wrap items-center justify-center gap-2"
      >
        <Button v-if="page > 1" as-child size="sm" variant="outline" class="rounded-xl">
          <NuxtLink :to="linkTo(page - 1)" rel="prev">{{ t('previous', 'Previous', 'السابق', { subGroup: 'general' }) }}</NuxtLink>
        </Button>

        <Button
          v-for="n in pageWindow"
          :key="n"
          as-child
          size="sm"
          class="min-w-10 rounded-xl"
          :variant="n === page ? 'default' : 'outline'"
        >
          <NuxtLink :to="linkTo(n)" :aria-current="n === page ? 'page' : undefined">{{ n }}</NuxtLink>
        </Button>

        <Button v-if="page < lastPage" as-child size="sm" variant="outline" class="rounded-xl">
          <NuxtLink :to="linkTo(page + 1)" rel="next">{{ t('next', 'Next', 'التالي', { subGroup: 'general' }) }}</NuxtLink>
        </Button>
      </nav>

      <p v-if="total" class="mt-6 text-center text-sm text-muted-foreground">
        {{ t('bookings_count', ':total bookings', ':total حجز', { total }) }}
      </p>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ["auth-mode", "require-registered", "verified"],
  name: "bookings",
});

const route = useRoute();
const router = useRouter();
const { t } = useLang("web", "bookings");

// The URL is the source of truth, so a filtered list is shareable and the back button
// walks the filters like any other navigation.
const page = computed(() => Math.max(1, Number(route.query.page ?? 1) || 1));
const activeTab = computed(() =>
  BOOKING_TABS.includes(route.query.status) ? route.query.status : "all",
);
const activeSort = computed(() =>
  BOOKING_SORTS.includes(route.query.sort) ? route.query.sort : "newest",
);

const { items, lastPage, total, pending, error, refresh, statusCounts } = useBookings({
  page,
  perPage: 10,
  status: computed(() =>
    activeTab.value === "all" ? undefined : activeTab.value,
  ),
  sort: computed(() =>
    activeSort.value === "newest" ? undefined : activeSort.value,
  ),
});

const tabLabels = computed(() => ({
  all: t("status_all", "All", "الكل"),
  pending_payment: t(
    "status_pending_payment",
    "Awaiting payment",
    "بانتظار الدفع",
  ),
  confirmed: t("status_confirmed", "Confirmed", "مؤكد"),
  attending: t("status_attending", "Checked in", "حاضرة"),
  preparing: t("status_preparing", "Being prepared", "قيد التحضير"),
  completed: t("status_completed", "Completed", "مكتملة"),
  absent: t("status_absent", "No-show", "لم تحضر"),
  cancelled: t("status_cancelled", "Cancelled", "ملغاة"),
}));

// An empty status is a tab that could only ever show an empty list. The exception is the
// active one, so a link to a status the customer has since emptied still reads as filtered.
const tabs = computed(() => {
  const counts = statusCounts.value;
  return BOOKING_TABS.filter(
    (key) =>
      key === "all" || key === activeTab.value || (counts?.[key] ?? 0) > 0,
  ).map((key) => ({
    key,
    label: tabLabels.value[key] ?? key,
    count: counts?.[key] ?? null,
  }));
});

const sortLabel = (option) =>
  ({
    newest: t("sort_newest", "Newest booked", "الأحدث حجزًا"),
    oldest: t("sort_oldest", "Oldest booked", "الأقدم حجزًا"),
    session_soonest: t(
      "sort_session_soonest",
      "Nearest session",
      "الجلسة الأقرب",
    ),
    session_latest: t(
      "sort_session_latest",
      "Furthest session",
      "الجلسة الأبعد",
    ),
  })[option] ?? option;

/** Any filter change starts again at page one; an unset value drops out of the URL. */
const apply = (patch) => {
  const query = { ...route.query, ...patch };
  delete query.page;
  Object.keys(query).forEach((key) => {
    if (query[key] === null || query[key] === undefined) delete query[key];
  });
  router.push({ query });
};

const linkTo = (n) => ({
  query: { ...route.query, page: n > 1 ? n : undefined },
});

const pageWindow = computed(() => {
  const from = Math.max(1, page.value - 2);
  const to = Math.min(lastPage.value, page.value + 2);
  return Array.from({ length: to - from + 1 }, (_, i) => from + i);
});

const crumbs = computed(() => [
  {
    to: "/",
    label: t("nav_home", "Home", "الرئيسية", { subGroup: "general" }),
  },
  {
    to: "/workshops",
    label: t("nav_workshops", "Workshops", "الورشات", { subGroup: "general" }),
  },
  { label: t("tab_mine", "My workshops", "ورشاتي") },
]);

useSeoMeta({
  title: () => t("bookings_title", "My bookings", "ورشاتي"),
  robots: "noindex",
});
</script>
