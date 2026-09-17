<template>
  <main class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <h1 class="font-display text-3xl font-semibold sm:text-4xl">
        {{ t("bookings_title", "My bookings", "ورشاتي") }}
      </h1>

      <ul class="mt-6 flex flex-wrap gap-2">
        <li>
          <Button as-child size="sm" variant="outline" class="rounded-xl">
            <NuxtLink to="/workshops">{{
              t("tab_book", "Book a workshop", "حجز ورشة")
            }}</NuxtLink>
          </Button>
        </li>
        <li>
          <Button
            size="sm"
            class="rounded-xl bg-brand-rust hover:bg-brand-rust/90"
            >{{ t("tab_mine", "My workshops", "ورشاتي") }}</Button
          >
        </li>
      </ul>

      <!-- A tab appears once the customer has something in that status; the counts come
           from `meta.status_counts`, which covers the whole history whatever is filtered. -->
      <div class="mt-8 flex flex-wrap items-center gap-3">
        <ul
          class="-mx-6 flex flex-1 gap-2 overflow-x-auto px-6 pb-1"
          data-test="status-tabs"
        >
          <li v-for="tab in tabs" :key="tab.key" class="shrink-0">
            <Button
              size="sm"
              class="rounded-xl"
              :variant="tab.key === activeTab ? 'default' : 'outline'"
              :class="
                tab.key === activeTab
                  ? 'bg-brand-rust hover:bg-brand-rust/90'
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
          <SelectTrigger id="bookings-sort" data-test="sort-select" class="h-10 text-sm">
            {{ sortLabel(activeSort) }}
          </SelectTrigger>
          <SelectContent>
            <SelectItem v-for="option in BOOKING_SORTS" :key="option" :value="option">
              {{ sortLabel(option) }}
            </SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div
        v-if="pending && !items.length"
        class="mt-8 grid gap-4 lg:grid-cols-2"
        aria-busy="true"
      >
        <AppSkeleton v-for="n in 4" :key="n" class="h-32 w-full !rounded-card" />
      </div>

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

      <ul v-else class="mt-8 grid gap-4 lg:grid-cols-2">
        <li v-for="booking in items" :key="booking.id">
          <BookingCard :booking="booking" />
        </li>
      </ul>

      <nav v-if="lastPage > 1" class="mt-10 flex justify-center gap-2">
        <Button
          v-for="n in pageWindow"
          :key="n"
          as-child
          size="sm"
          class="rounded-xl"
          :variant="n === page ? 'default' : 'outline'"
        >
          <NuxtLink :to="linkTo(n)">{{ n }}</NuxtLink>
        </Button>
      </nav>
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

const { items, lastPage, pending, error, refresh, statusCounts } = useBookings({
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
  { label: t("bookings_title", "My bookings", "ورشاتي") },
]);

useSeoMeta({
  title: () => t("bookings_title", "My bookings", "ورشاتي"),
  robots: "noindex",
});
</script>
