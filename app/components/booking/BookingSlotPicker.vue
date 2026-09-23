<template>
  <div class="flex flex-col gap-8">
    <!-- Party size. The cap is the server's `max_available_seats` (already capped at
         `max_people_per_booking`) — never a locally derived number. -->
    <section v-if="!lockPeople">
      <ul ref="peopleRail" class="flex cursor-grab gap-3 overflow-x-auto scrollbar-none pb-2" data-test="people-options">
        <li v-for="n in peopleOptions" :key="n" class="shrink-0">
          <button
            type="button"
            class="relative flex h-24 w-24 flex-col items-center justify-center gap-1 overflow-hidden rounded-2xl border text-center transition-colors"
            :class="people === n ? 'border-primary bg-primary text-white' : 'bg-card hover:border-primary'"
            :data-people="n"
            @click="people = n"
          >
            <CardLineArt v-if="people === n" class="absolute inset-0 size-full scale-125" />
            <span class="relative font-display text-2xl font-semibold">{{ n }}</span>
            <span class="relative text-xs opacity-80">{{ t('n_people_unit', 'people', 'أشخاص') }}</span>
          </button>
        </li>
      </ul>

      <p v-if="peopleCap === 0" class="mt-3 text-sm text-destructive">
        {{ t('booking_no_seats', 'No dates in the next month have room. Please check back soon.', 'لا توجد مواعيد متاحة خلال الشهر القادم. تفقد الصفحة لاحقًا.') }}
      </p>
      <span v-if="fieldError(errors, 'people_count')" class="mt-2 block text-xs text-destructive">{{ fieldError(errors, 'people_count') }}</span>
    </section>

    <!-- Date strip. `blocked_dates` is relative to the party size, so it is refetched
         whenever `people` changes. -->
    <section>
      <h2 class="font-display text-xl font-semibold">{{ t('booking_pick_date', 'Pick a date', 'اختر تاريخًا') }}</h2>

      <div v-if="loadingCalendar" class="mt-4 flex gap-3 overflow-hidden" aria-busy="true">
        <AppSkeleton v-for="n in 6" :key="n" class="h-24 w-24 shrink-0 !rounded-2xl" />
      </div>

      <div v-else-if="loadError" class="mt-4 flex flex-col items-start gap-3 rounded-2xl border border-destructive/30 p-4">
        <p class="text-sm text-destructive" data-test="availability-error">{{ loadError }}</p>
        <Button type="button" size="sm" variant="outline" class="rounded-xl" @click="reload">
          {{ t('try_again', 'Try again', 'حاول مرة أخرى') }}
        </Button>
      </div>

      <p
        v-else-if="!days.length"
        class="mt-4 rounded-2xl border border-dashed p-6 text-center text-sm text-muted-foreground"
        data-test="no-dates"
      >
        {{ t('no_open_dates', 'No open dates for this party size — try fewer people.', 'لا توجد مواعيد متاحة لهذا العدد — جرّب عددًا أقل.') }}
      </p>

      <ul v-else ref="dateRail" class="mt-4 flex cursor-grab gap-3 overflow-x-auto scrollbar-none pb-2" data-test="date-strip">
        <li v-for="day in days" :key="day.ymd" class="shrink-0">
          <button
            type="button"
            class="relative flex h-24 w-24 flex-col items-center justify-center gap-1 overflow-hidden rounded-2xl border text-center transition-colors"
            :class="date === day.ymd ? 'border-primary bg-primary text-white' : 'bg-card hover:border-primary'"
            :data-date="day.ymd"
            @click="date = day.ymd"
          >
            <CardLineArt v-if="date === day.ymd" class="absolute inset-0 size-full scale-125" />
            <span class="relative text-xs opacity-80">{{ day.month }}</span>
            <span class="relative font-display text-2xl font-semibold">{{ day.day }}</span>
            <span class="relative text-xs opacity-80">{{ day.weekday }}</span>
          </button>
        </li>
      </ul>
      <span v-if="fieldError(errors, 'booking_date')" class="mt-2 block text-xs text-destructive">{{ fieldError(errors, 'booking_date') }}</span>
    </section>

    <!-- Slots. `is_full` is relative to the party size and `has_conflict` means the caller
         already has a booking then — both are disabled, never hidden. -->
    <section v-if="date">
      <div v-if="loadingSlots" class="mt-4 flex flex-col gap-3" aria-busy="true">
        <AppSkeleton v-for="n in 3" :key="n" class="h-[88px] w-full !rounded-2xl" />
      </div>

      <!-- A failed request is not an empty day: the customer is told which one it was. -->
      <div v-else-if="slotsError" class="mt-4 rounded-card border border-dashed p-6 text-center text-sm" data-test="slots-error">
        <p class="text-destructive">{{ slotsError }}</p>
        <Button type="button" variant="outline" class="mt-3 h-10 rounded-control" @click="loadSlots">
          {{ t('retry', 'Try again', 'إعادة المحاولة') }}
        </Button>
      </div>

      <p v-else-if="!slots.length" class="mt-4 rounded-card border border-dashed p-6 text-center text-sm text-muted-foreground">
        {{ t('booking_no_slots', 'No sessions run on this day. Try another date.', 'لا توجد جلسات في هذا اليوم. جرب تاريخًا آخر.') }}
      </p>

      <ul v-else class="mt-4 flex flex-col gap-3" data-test="slot-list">
        <li v-for="slot in slots" :key="slot.workshop_slot_id">
          <button
            type="button"
            class="relative flex w-full flex-col items-start gap-2 overflow-hidden rounded-2xl border px-4 py-6 text-start transition-colors disabled:cursor-not-allowed disabled:opacity-40"
            :class="slotId === slot.workshop_slot_id ? 'border-primary bg-primary text-white' : 'bg-card hover:border-primary'"
            :disabled="slot.is_full || slot.has_conflict"
            :data-slot="slot.workshop_slot_id"
            @click="slotId = slot.workshop_slot_id"
          >
            <CardLineArt
              v-if="slotId === slot.workshop_slot_id"
              class="absolute inset-y-0 end-0 aspect-square h-full scale-125"
            />
            <span class="relative flex w-full flex-col items-start gap-1 sm:flex-row sm:items-center sm:justify-between sm:gap-4">
              <span class="font-medium">
                {{ t('slot_from_to', 'Session :from to :to', 'ورشة من :from الى :to', { from: formatClock(slot.start_time, code), to: formatClock(slot.end_time, code) }) }}
              </span>
              <!-- No `dir="ltr"`: the count reads «14 من 14», and forcing the run to LTR
                   threw the Arabic word to the front of both numbers. -->
              <span class="text-sm" :class="slotId === slot.workshop_slot_id ? 'text-white/80' : 'text-muted-foreground'">
                {{ slot.has_conflict
                  ? t('slot_conflict', 'You are already booked then', 'لديك حجز في هذا الوقت')
                  : t('seats_taken_of', ':taken of :capacity', ':taken من :capacity', { taken: slot.capacity - slot.remaining, capacity: slot.capacity }) }}
              </span>
            </span>

          </button>
        </li>
      </ul>
      <span v-if="fieldError(errors, 'workshop_slot_id')" class="mt-2 block text-xs text-destructive">{{ fieldError(errors, 'workshop_slot_id') }}</span>
    </section>
  </div>
</template>

<script setup>
/**
 * Party size → date → slot, the one picker used by both the booking flow and the
 * reschedule sheet. It owns the two availability calls and nothing else: the parent keeps
 * the selection and decides what to do with it.
 */
const props = defineProps({
  workshop: { type: Object, required: true },
  /** Reschedule of a catalogue booking: the API refuses a party-size change. */
  lockPeople: { type: Boolean, default: false },
  errors: { type: Object, default: () => ({}) },
  days: { type: Number, default: 30 },
})

const people = defineModel('people', { type: Number, default: 1 })
const date = defineModel('date', { type: String, default: '' })
const slotId = defineModel('slotId', { type: Number, default: null })
/** The chosen slot in full — the summary needs its `start_time` / `end_time` strings. */
const slot = defineModel('slot', { type: Object, default: null })

const { t, code } = useLang('web', 'bookings')

// Both rails are sideways, and a mouse has no sideways. See `useDragScroll`.
const peopleRail = ref(null)
const dateRail = ref(null)
useDragScroll(peopleRail)
useDragScroll(dateRail)
const { formatDate } = useDateFormat()
const availability = useWorkshopBooking(() => props.workshop.id)

const maxSeats = ref(props.workshop.max_people_per_booking ?? 1)
const blocked = ref([])
const slots = ref([])
const loadingCalendar = ref(true)
const loadingSlots = ref(false)
const loadError = ref('')
const slotsError = ref('')

const peopleCap = computed(() => Math.min(props.workshop.max_people_per_booking ?? 1, maxSeats.value))
const peopleOptions = computed(() => Array.from({ length: Math.max(peopleCap.value, 1) }, (_, i) => i + 1))

/**
 * Only the days that can actually be booked.
 *
 * A blocked day is dropped, not greyed: the strip is a list of choices, and a row of
 * dimmed dates the customer cannot pick is noise they have to read past to find the ones
 * they can. The slots BELOW are the opposite case — `is_full` and `has_conflict` stay on
 * screen and disabled, because there the reason matters ("that session is full", "you are
 * already booked then") and hiding it would look like the session does not exist.
 */
const days = computed(() => dateRange(todayInStudio(), props.days)
  .filter((ymd) => !blocked.value.includes(ymd))
  .map((ymd) => ({ ymd, ...dateParts(ymd, code.value) })))

const loadCalendar = async () => {
  loadingCalendar.value = true
  loadError.value = ''
  try {
    const data = await availability.calendar({ people_count: people.value, days: props.days })
    maxSeats.value = data.max_available_seats ?? 0
    blocked.value = data.blocked_dates ?? []
  } catch (err) {
    // Without this the strip just renders empty, which reads as "no dates" rather than
    // "we could not ask".
    loadError.value = normalizeApiError(err).message
      || t('availability_failed', 'Could not load available dates. Please try again.', 'تعذّر تحميل المواعيد المتاحة. حاول مرة أخرى.')
    return
  } finally {
    loadingCalendar.value = false
  }

  // Never under `lockPeople`. Availability is computed WITHOUT excluding the booking being
  // moved, so `max_available_seats` is routinely below that booking's own party size — and
  // rewriting the model there silently shrank a paid party, recomputed the total and issued
  // a partial wallet refund the customer never asked for. The picker only greys the slots
  // that cannot take them.
  if (!props.lockPeople && people.value > peopleCap.value && peopleCap.value > 0) {
    people.value = peopleCap.value
  }
  // A date that was open for one person can be blocked for three.
  if (!date.value || blocked.value.includes(date.value)) date.value = days.value[0]?.ymd ?? ''
}

const loadSlots = async () => {
  if (!date.value) { slots.value = []; return }
  loadingSlots.value = true
  slotsError.value = ''
  try {
    slots.value = await availability.slots(date.value, people.value)
  } catch (err) {
    // Without this a failure reads as "no sessions run on this day", which sends the
    // customer hunting through a calendar that is fine.
    slots.value = []
    slotsError.value = normalizeApiError(err).message
      || t('slots_failed', 'Could not load this day’s sessions. Please try again.', 'تعذّر تحميل جلسات هذا اليوم. حاول مرة أخرى.')
  } finally {
    loadingSlots.value = false
  }
  if (!slots.value.some((slot) => slot.workshop_slot_id === slotId.value)) slotId.value = null
}

watch([slotId, slots], () => {
  slot.value = slots.value.find((candidate) => candidate.workshop_slot_id === slotId.value) ?? null
})

// `loadCalendar` picks the first open date, and that assignment is what triggers the slot
// fetch — calling `loadSlots` alongside it would put two identical requests in flight and
// let the loser answer last. The one case the watcher misses is the date surviving a
// party-size change unchanged, so reload it explicitly then.
watch(people, async () => {
  const previous = date.value
  await loadCalendar()
  if (date.value === previous) await loadSlots()
})
watch(date, loadSlots)

const reload = async () => {
  await loadCalendar()
  if (!date.value) slots.value = []
}

onMounted(reload)

// The create call checks capacity under a row lock, so a 422 means the day changed under
// us — the page re-renders the real slots instead of showing a toast.
defineExpose({ refreshSlots: loadSlots, refreshCalendar: loadCalendar })
</script>
