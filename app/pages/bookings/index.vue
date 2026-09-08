<template>
  <main class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-3xl px-6 py-16">
      <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('bookings_title', 'My bookings', 'ورشاتي') }}</h1>

      <ul class="mt-6 flex flex-wrap gap-2">
        <li>
          <Button as-child size="sm" variant="outline" class="rounded-xl">
            <NuxtLink to="/workshops">{{ t('tab_book', 'Book a workshop', 'حجز ورشة') }}</NuxtLink>
          </Button>
        </li>
        <li>
          <Button size="sm" class="rounded-xl bg-brand-rust hover:bg-brand-rust/90">{{ t('tab_mine', 'My workshops', 'ورشاتي') }}</Button>
        </li>
      </ul>

      <div v-if="pending && !items.length" class="mt-8 flex flex-col gap-4" aria-busy="true">
        <AppSkeleton v-for="n in 3" :key="n" class="h-32 w-full !rounded-3xl" />
      </div>

      <p v-else-if="!items.length" class="mt-8 rounded-3xl border border-dashed p-10 text-center text-muted-foreground">
        {{ t('bookings_empty', 'You have no bookings yet.', 'لا توجد لديك حجوزات بعد.') }}
      </p>

      <ul v-else class="mt-8 flex flex-col gap-4">
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
          <NuxtLink :to="{ query: { page: n > 1 ? n : undefined } }">{{ n }}</NuxtLink>
        </Button>
      </nav>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'bookings',
})

const route = useRoute()
const { t } = useLang('web', 'bookings')

const page = computed(() => Number(route.query.page ?? 1) || 1)
const { items, lastPage, pending } = useBookings({ page, perPage: 10 })

const pageWindow = computed(() => {
  const from = Math.max(1, page.value - 2)
  const to = Math.min(lastPage.value, page.value + 2)
  return Array.from({ length: to - from + 1 }, (_, i) => from + i)
})

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { label: t('bookings_title', 'My bookings', 'ورشاتي') },
])

useSeoMeta({ title: () => t('bookings_title', 'My bookings', 'ورشاتي'), robots: 'noindex' })
</script>
