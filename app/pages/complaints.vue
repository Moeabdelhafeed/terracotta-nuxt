<template>
  <main class="min-h-svh bg-background pb-28">
    <PageBar :crumbs="crumbs" />
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="mx-auto flex max-w-lg flex-col gap-5">
        <div>
          <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('complaints_title', 'Complaints', 'الشكاوى') }}</h1>
          <p class="mt-3 text-muted-foreground">
            {{ t('complaints_intro', 'Tell us what went wrong and we will get back to you.', 'أخبرنا بما حدث وسنعود إليك في أقرب وقت.') }}
          </p>
        </div>

        <form class="flex flex-col gap-4 rounded-3xl border bg-card p-6 sm:p-8" @submit.prevent="onSubmit">
          <div class="grid gap-2">
            <Label for="complaint_type">{{ t('complaint_type', 'What is this about?', 'موضوع الشكوى') }}</Label>
            <select
              id="complaint_type"
              v-model="form.type"
              data-test="complaint-type"
              class="h-12 w-full rounded-xl border border-input bg-transparent px-4 text-base outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
            >
              <option v-for="type in COMPLAINT_TYPES" :key="type" :value="type">{{ complaintTypeLabel(type, t) }}</option>
            </select>
            <span v-if="err('type')" class="text-xs text-destructive">{{ err('type') }}</span>
          </div>

          <template v-if="!isRegistered">
            <div class="grid gap-2">
              <Label for="complaint_name">{{ t('name', 'Name', 'الاسم') }}</Label>
              <Input id="complaint_name" v-model="form.name" data-test="complaint-name" type="text" maxlength="120" class="h-12 rounded-xl text-base" required />
              <span v-if="err('name')" class="text-xs text-destructive">{{ err('name') }}</span>
            </div>
            <div class="grid gap-2">
              <Label for="complaint_contact">{{ t('complaint_contact', 'Email or phone we can reply to', 'بريد أو هاتف للتواصل معك') }}</Label>
              <Input id="complaint_contact" v-model="form.contact" data-test="complaint-contact" type="text" maxlength="120" class="h-12 rounded-xl text-base" dir="ltr" required />
              <span v-if="err('contact')" class="text-xs text-destructive">{{ err('contact') }}</span>
            </div>
          </template>

          <div class="grid gap-2">
            <Label for="complaint_reference">
              {{ t('complaint_reference', 'Order or booking number', 'رقم الطلب أو الحجز') }}
              <span class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span>
            </Label>
            <Input id="complaint_reference" v-model="form.reference" type="text" maxlength="64" class="h-12 rounded-xl text-base" dir="ltr" />
            <span v-if="err('reference')" class="text-xs text-destructive">{{ err('reference') }}</span>
          </div>

          <div class="grid gap-2">
            <Label for="complaint_message">{{ t('complaint_message', 'What happened?', 'ماذا حدث؟') }}</Label>
            <textarea
              id="complaint_message"
              v-model="form.message"
              data-test="complaint-message"
              rows="5"
              minlength="5"
              maxlength="2000"
              required
              class="w-full rounded-xl border border-input bg-transparent p-4 text-base outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
              :placeholder="t('complaint_message_placeholder', 'Describe the problem in a few lines…', 'اشرح المشكلة في بضعة أسطر…')"
            />
            <div class="flex flex-wrap items-center justify-between gap-x-3">
              <span v-if="err('message')" data-test="message-error" class="text-xs text-destructive">{{ err('message') }}</span>
              <span v-else class="text-xs text-muted-foreground">{{ t('complaint_message_hint', 'At least 5 characters, no HTML.', '5 أحرف على الأقل، بدون وسوم HTML.') }}</span>
              <span class="text-xs text-muted-foreground" dir="ltr">{{ form.message.length }}/2000</span>
            </div>
          </div>

          <span v-if="submitError" data-test="complaint-error" class="text-xs text-destructive">{{ submitError }}</span>
          <p v-if="sentMessage" data-test="complaint-success" class="rounded-2xl bg-brand-mist/60 p-4 text-sm text-foreground">{{ sentMessage }}</p>

          <Button
            type="submit"
            data-test="complaint-submit"
            class="h-12 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
            :disabled="submitting"
          >
            {{ submitting ? t('sending', 'Sending...', 'جارٍ الإرسال...') : t('complaint_send', 'Send complaint', 'إرسال الشكوى') }}
          </Button>
        </form>

        <section v-if="isRegistered" class="rounded-3xl border bg-card p-6 sm:p-8">
          <h2 class="font-display text-lg font-semibold text-foreground">{{ t('my_complaints', 'My complaints', 'شكاواي') }}</h2>

          <div v-if="pending && !complaints.length" class="mt-4 flex flex-col gap-3" aria-busy="true">
            <AppSkeleton v-for="n in 2" :key="n" class="h-24 w-full" />
          </div>

          <p v-else-if="!complaints.length" class="mt-4 text-sm text-muted-foreground">
            {{ t('no_complaints', 'You have not filed a complaint yet.', 'لم تقدّم أي شكوى بعد.') }}
          </p>

          <ul v-else class="mt-4 flex flex-col gap-3">
            <li v-for="complaint in complaints" :key="complaint.id" class="rounded-2xl border p-4">
              <div class="flex flex-wrap items-center justify-between gap-2">
                <span class="text-sm font-medium text-foreground">{{ complaintTypeLabel(complaint.type, t) }}</span>
                <span class="rounded-md px-2.5 py-0.5 text-xs font-medium" :class="statusClass(complaint.status)">
                  {{ complaintStatusLabel(complaint.status, t) }}
                </span>
              </div>
              <p class="mt-2 break-words whitespace-pre-line text-sm text-muted-foreground">{{ complaint.message }}</p>
              <p v-if="complaint.reference" class="mt-1 text-xs break-words text-muted-foreground" dir="ltr">{{ complaint.reference }}</p>
              <p class="mt-2 text-xs text-muted-foreground">
                {{ formatDate(complaint.created_at) }}
                <template v-if="complaint.resolved_at">
                  · {{ t('complaint_resolved_on', 'Resolved :date', 'تم الحل :date', { date: formatDate(complaint.resolved_at) }) }}
                </template>
              </p>
            </li>
          </ul>
        </section>
      </div>
    </div>
  </main>
</template>

<script setup>
/**
 * `POST /api/complaints` is public: signed out it needs `name` + `contact`, signed in the
 * account is used and any posted name/contact is ignored — so those two inputs disappear.
 * The endpoint is on `throttle:auth`, hence the disabled button while a submit is in flight.
 */
definePageMeta({
  middleware: [],
  name: 'complaints',
})

const { t } = useLang('web', 'account')
const { formatDate } = useDateFormat()

const { complaints, pending, send, submitting, errors, submitError, isRegistered } = useComplaints()

const crumbs = computed(() => [
  { label: t('home', 'Home', 'الرئيسية'), to: '/' },
  { label: t('complaints_title', 'Complaints', 'الشكاوى') },
])

const form = ref({ type: 'order', name: '', contact: '', reference: '', message: '' })
const sentMessage = ref('')

const err = (field) => fieldError(errors.value, field)

const statusClass = (status) => ({
  new: 'bg-brand-mist text-brand-ink',
  in_progress: 'bg-amber-100 text-amber-800',
  resolved: 'bg-brand-green/15 text-brand-green',
  closed: 'bg-muted text-muted-foreground',
}[status] ?? 'bg-muted text-muted-foreground')

const onSubmit = async () => {
  if (submitting.value) return
  sentMessage.value = ''
  try {
    const res = await send(form.value)
    sentMessage.value = res.message || t('complaint_received', 'Your complaint has been received.', 'تم استلام شكواك.')
    form.value = { type: 'order', name: '', contact: '', reference: '', message: '' }
  } catch {
    // `errors` / `submitError` are bound in the template — the server's text is the truth.
  }
}
</script>
