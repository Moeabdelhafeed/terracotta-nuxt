<template>
  <div class="flex flex-col gap-8">
    <!-- Party size. The cap is the server's `max_available_seats` (already capped at
         `max_people_per_booking`) — never a locally derived number. -->
    <section v-if="!lockPeople">
      <h2 class="font-display text-xl font-semibold">{{ t('booking_people_title', 'How many of you?', 'كم عددكم؟') }}</h2>

      <ul class="mt-4 flex flex-wrap gap-2" data-test="people-options">
        <li v-for="n in peopleOptions" :key="n">
          <Button
            type="button"
            size="sm"
            class="rounded-xl"
            :variant="people === n ? 'default' : 'outline'"
            :class="people === n ? 'bg-brand-rust hover:bg-brand-rust/90' : ''"
            :data-people="n"
            @click="people = n"
          >
            {{ t('n_people', ':n people', ':n اشخاص', { n }) }}
          </Button>
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
      <h2 class="font-display text-xl font-semibold">{{ t('booking_pick_date', 'Pick a date', 'اختر موعد') }}</h2>

      <div v-if="loadingCalendar" class="mt-4 flex gap-3 overflow-hidden" aria-busy="true">
        <AppSkeleton v-for="n in 6" :key="n" class="h-24 w-24 shrink-0 !rounded-2xl" />
      </div>

      <div v-else-if="loadError" class="mt-4 flex flex-col items-start gap-3 rounded-2xl border border-destructive/30 p-4">
        <p class="text-sm text-destructive" data-test="availability-error">{{ loadError }}</p>
        <Button type="button" size="sm" variant="outline" class="rounded-xl" @click="reload">
          {{ t('try_again', 'Try again', 'حاول مرة أخرى') }}
        </Button>
      </div>

      <ul v-else class="mt-4 flex gap-3 overflow-x-auto pb-2" data-test="date-strip">
        <li v-for="day in days" :key="day.ymd" class="shrink-0">
          <button
            type="button"
            class="flex h-24 w-24 flex-col items-center justify-center gap-1 rounded-2xl border text-center transition-colors disabled:cursor-not-allowed disabled:opacity-40"
            :class="date === day.ymd ? 'border-brand-rust bg-brand-rust text-white' : 'bg-card hover:border-brand-rust'"
            :disabled="day.blocked"
            :data-date="day.ymd"
            :data-blocked="day.blocked ? 'true' : 'false'"
            @click="date = day.ymd"
          >
            <span class="text-xs opacity-80">{{ day.month }}</span>
            <span class="font-display text-2xl font-semibold">{{ day.day }}</span>
            <span class="text-xs opacity-80">{{ day.weekday }}</span>
          </button>
        </li>
      </ul>
      <span v-if="fieldError(errors, 'booking_date')" class="mt-2 block text-xs text-destructive">{{ fieldError(errors, 'booking_date') }}</span>
    </section>

    <!-- Slots. `is_full` is relative to the party size and `has_conflict` means the caller
         already has a booking then — both are disabled, never hidden. -->
    <section v-if="date">
      <h2 class="font-display text-xl font-semibold">{{ t('booking_pick_slot', 'Pick a session', 'اختر الجلسة') }}</h2>

      <div v-if="loadingSlots" class="mt-4 flex flex-col gap-3" aria-busy="true">
        <AppSkeleton v-for="n in 3" :key="n" class="h-16 w-full !rounded-2xl" />
      </div>

      <p v-else-if="!slots.length" class="mt-4 rounded-2xl border border-dashed p-6 text-center text-sm text-muted-foreground">
        {{ t('booking_no_slots', 'No sessions run on this day. Try another date.', 'لا توجد جلسات في هذا اليوم. جرب تاريخًا آخر.') }}
      </p>

      <ul v-else class="mt-4 flex flex-col gap-3" data-test="slot-list">
        <li v-for="slot in slots" :key="slot.workshop_slot_id">
          <button
            type="button"
            class="flex w-full flex-col items-start gap-2 rounded-2xl border bg-card p-4 text-start transition-colors disabled:cursor-not-allowed disabled:opacity-40"
            :class="slotId === slot.workshop_slot_id ? 'border-brand-rust ring-1 ring-brand-rust' : 'hover:border-brand-rust'"
            :disabled="slot.is_full || slot.has_conflict"
            :data-slot="slot.workshop_slot_id"
            @click="slotId = slot.workshop_slot_id"
          >
            <span class="flex w-full flex-col items-start gap-1 sm:flex-row sm:items-center sm:justify-between sm:gap-4">
              <span class="font-medium">
                {{ t('slot_from_to', 'Session :from to :to', 'ورشة من :from الى :to', { from: slot.start_time, to: slot.end_time }) }}
              </span>
              <span class="text-sm text-muted-foreground" dir="ltr">
                {{ slot.has_conflict
                  ? t('slot_conflict', 'You are already booked then', 'لديك حجز في هذا الوقت')
                  : t('seats_of', ':left / :capacity people', ':left \\ :capacity اشخاص', { left: slot.remaining, capacity: slot.capacity }) }}
              </span>
            </span>

            <!-- Booking this session now lands inside its own cancellation window, so the
                 booking would arrive already uncancellable — said before it is picked. -->
            <span v-if="slot.is_non_cancellable" class="flex items-start gap-1.5 text-xs text-amber-700" data-test="slot-no-cancel">
              <LucideAlertCircle class="mt-px size-3.5 shrink-0" />
              {{ t('slot_no_cancel', "This session is too close to book and still cancel — you won't be able to cancel or move it.", 'هذه الجلسة قريبة جدًا: لن تتمكن من إلغاء الحجز أو تغيير موعده.') }}
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
const availability = useWorkshopBooking(() => props.workshop.id)

const maxSeats = ref(props.workshop.max_people_per_booking ?? 1)
const blocked = ref([])
const slots = ref([])
const loadingCalendar = ref(true)
const loadingSlots = ref(false)
const loadError = ref('')

const peopleCap = computed(() => Math.min(props.workshop.max_people_per_booking ?? 1, maxSeats.value))
const peopleOptions = computed(() => Array.from({ length: Math.max(peopleCap.value, 1) }, (_, i) => i + 1))

const days = computed(() => dateRange(todayInStudio(), props.days).map((ymd) => ({
  ymd,
  blocked: blocked.value.includes(ymd),
  ...dateParts(ymd, code.value),
})))

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

  if (people.value > peopleCap.value && peopleCap.value > 0) people.value = peopleCap.value
  // A date that was open for one person can be blocked for three.
  if (!date.value || blocked.value.includes(date.value)) date.value = days.value.find((day) => !day.blocked)?.ymd ?? ''
}

const loadSlots = async () => {
  if (!date.value) { slots.value = []; return }
  loadingSlots.value = true
  try {
    slots.value = await availability.slots(date.value, people.value)
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
