<template>
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-5">
        <div class="flex items-center justify-between">
          <NuxtLink
            to="/profile"
            class="flex size-10 items-center justify-center text-foreground/70 transition-colors hover:text-foreground -ms-2 rtl:-scale-x-100"
            :aria-label="t('back_to_profile', 'Back to profile', 'عودة للملف')"
          >
            <LucideArrowLeft class="size-5" />
          </NuxtLink>
          <h1 class="font-display text-lg font-semibold text-foreground">{{ t('active_devices', 'Active devices', 'الأجهزة النشطة') }}</h1>
          <span class="size-10" />
        </div>
        <p class="-mt-3 text-center text-sm text-muted-foreground">{{ t('active_devices_description', 'Devices currently signed in to your account.', 'الأجهزة المسجّلة الدخول حاليًا.') }}</p>

        <section class="rounded-2xl border bg-card p-5">
          <p v-if="pending" class="text-sm text-muted-foreground">{{ t('loading', 'Loading...', 'جارٍ التحميل...') }}</p>
          <p v-else-if="!devices.length" class="text-sm text-muted-foreground">{{ t('no_devices', 'No devices found.', 'لا توجد أجهزة.') }}</p>
          <ul v-else class="grid gap-3 lg:grid-cols-2">
            <li
              v-for="d in devices"
              :key="d.id"
              class="flex flex-wrap items-center justify-between gap-4 rounded-xl border p-4 text-sm"
            >
              <div class="flex min-w-0 flex-col gap-0.5">
                <span class="font-medium break-words text-foreground">
                  {{ d.device_name || t('unknown_device', 'Unknown device', 'جهاز غير معروف') }}
                  <span
                    v-if="d.is_current"
                    class="ms-2 rounded-md bg-brand-rust/10 px-2 py-0.5 text-xs font-medium text-brand-rust"
                  >{{ t('this_device', 'This device', 'هذا الجهاز') }}</span>
                </span>
                <span class="text-xs break-words text-muted-foreground">
                  {{ [d.platform, d.ip].filter(Boolean).join(' • ') }}
                </span>
                <span v-if="d.last_seen_at" class="text-xs text-muted-foreground">
                  {{ t('last_seen', 'Last seen :time', 'آخر ظهور :time', { time: formatDate(d.last_seen_at) }) }}
                </span>
              </div>
              <Button
                v-if="!d.is_current"
                size="sm"
                variant="outline"
                class="shrink-0 rounded-xl"
                :disabled="revoking === d.id"
                @click="onRevoke(d.id)"
              >{{ revoking === d.id ? t('revoking', 'Revoking...', 'جارٍ الإلغاء...') : t('revoke', 'Revoke', 'إلغاء') }}</Button>
            </li>
          </ul>
          <p v-if="error" class="mt-3 text-xs text-destructive">{{ error }}</p>
        </section>
      </div>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered', 'verified', 'multi-session-only'],
  name: 'devices',
})

const { t } = useLang('web', 'profile')
const client = useApi()

const { data, pending, refresh } = useApiFetch('/api/devices', { key: 'devices' })

const devices = computed(() => {
  const d = data.value?.data ?? data.value
  return d?.devices ?? (Array.isArray(d) ? d : [])
})

const revoking = ref(null)
const error = ref('')

const onRevoke = async (id) => {
  error.value = ''
  revoking.value = id
  try {
    await client(`/api/devices/${id}`, { method: 'DELETE' })
    await refresh()
  } catch (err) {
    error.value = err?.data?.message ?? err?.message ?? String(err)
  } finally {
    revoking.value = null
  }
}

const formatDate = (s) => {
  try { return new Date(s).toLocaleString() } catch { return s }
}
</script>
