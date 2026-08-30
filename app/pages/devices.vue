<template>
  <div class="min-h-svh bg-muted/40 p-6">
    <div class="mx-auto flex max-w-2xl flex-col gap-6">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold">{{ t('active_devices', 'Active devices', 'الأجهزة النشطة') }}</h1>
          <p class="text-sm text-muted-foreground">{{ t('active_devices_description', 'Devices currently signed in to your account.', 'الأجهزة المسجّلة الدخول حاليًا.') }}</p>
        </div>
        <Button variant="outline" as-child>
          <NuxtLink to="/profile">{{ t('back_to_profile', 'Back to profile', 'عودة للملف') }}</NuxtLink>
        </Button>
      </div>

      <Card>
        <CardContent class="pt-6">
          <p v-if="pending" class="text-sm text-muted-foreground">{{ t('loading', 'Loading...', 'جارٍ التحميل...') }}</p>
          <p v-else-if="!devices.length" class="text-sm text-muted-foreground">{{ t('no_devices', 'No devices found.', 'لا توجد أجهزة.') }}</p>
          <ul v-else class="flex flex-col gap-2">
            <li
              v-for="d in devices"
              :key="d.id"
              class="flex items-center justify-between gap-4 rounded-md border p-3 text-sm"
            >
              <div class="flex flex-col">
                <span class="font-medium">
                  {{ d.device_name || t('unknown_device', 'Unknown device', 'جهاز غير معروف') }}
                  <span
                    v-if="d.is_current"
                    class="ms-2 rounded bg-primary/10 px-2 py-0.5 text-xs text-primary"
                  >{{ t('this_device', 'This device', 'هذا الجهاز') }}</span>
                </span>
                <span class="text-xs text-muted-foreground">
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
                :disabled="revoking === d.id"
                @click="onRevoke(d.id)"
              >{{ revoking === d.id ? t('revoking', 'Revoking...', 'جارٍ الإلغاء...') : t('revoke', 'Revoke', 'إلغاء') }}</Button>
            </li>
          </ul>
          <p v-if="error" class="mt-3 text-xs text-red-500">{{ error }}</p>
        </CardContent>
      </Card>
    </div>
  </div>
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
