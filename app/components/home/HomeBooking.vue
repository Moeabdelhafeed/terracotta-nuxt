<template>
  <section v-if="greeting || booking" class="mx-auto max-w-3xl px-6 pt-14">
    <p v-if="greeting" class="font-display text-2xl font-semibold sm:text-3xl">{{ greeting }}</p>

    <template v-if="booking">
      <h2 class="mt-6 font-display text-lg font-semibold text-brand-rust">
        {{ t('resume_workshop', 'Resume your workshop', 'استكمل ورشتك') }}
      </h2>

      <!-- The same card the bookings list uses: `current_booking` carries the fields it
           reads, and the date/time are the API's own studio-time strings either way. -->
      <BookingCard :booking="booking" class="mt-3" />
    </template>
  </section>
</template>

<script setup>
/**
 * The signed-in visitor's welcome: a greeting by their local hour, and the nearest
 * upcoming confirmed booking (`current_booking` from `GET /api/home`, `null` for a guest
 * or for someone with nothing booked).
 */
const { currentBooking } = useHome()
const { user } = useSanctumAuth()
const { t } = useLang('web', 'home')

const booking = computed(() => currentBooking.value)

const name = computed(() => {
  const record = user.value?.data ?? user.value
  return record?.is_guest ? '' : (record?.name ?? '')
})

// The hour is the *viewer's*, which the server does not know — reading it during SSR
// would greet half the world with the wrong half of the day and then swap it on
// hydration. So it stays null until mounted, and the line simply is not there yet.
const hour = ref(null)
onMounted(() => { hour.value = new Date().getHours() })

const greeting = computed(() => {
  if (hour.value === null || !name.value) return ''
  const salutation = hour.value < 12
    ? t('good_morning', 'Good morning', 'صباح الخير')
    : t('good_evening', 'Good evening', 'مساء الخير')
  return `${salutation}, ${name.value}`
})
</script>
