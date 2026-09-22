<template>
  <main class="bg-background">
    <PageBar :crumbs="crumbs" />
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-5">
        <h1 class="font-display text-3xl font-semibold sm:text-4xl">
          {{ t('addresses_title', 'My addresses', 'عناويني') }}
        </h1>

        <AppLoadError v-if="loadError" :error="loadError" :retry="refresh" />

        <div v-else-if="pending && !addresses.length" class="grid gap-3 lg:grid-cols-2" aria-busy="true">
          <AppSkeleton v-for="n in 2" :key="n" class="h-32 w-full !rounded-2xl" />
        </div>

        <div v-else-if="!addresses.length" class="mx-auto flex w-full max-w-xl flex-col items-center gap-3 rounded-2xl border bg-card p-10 text-center">
          <span class="flex size-12 items-center justify-center rounded-full bg-brand-terracotta/10 text-brand-terracotta">
            <LucideMapPin class="size-5" />
          </span>
          <h2 class="font-display text-lg font-semibold text-foreground">{{ t('no_addresses', 'No addresses yet', 'لا توجد عناوين بعد') }}</h2>
          <p class="text-sm text-muted-foreground">
            {{ t('no_addresses_note', 'Save an address once and every delivery gets faster.', 'احفظ عنوانك مرة واحدة ليصبح كل توصيل أسرع.') }}
          </p>
        </div>

        <ul v-else class="grid gap-3 lg:grid-cols-2" data-test="address-list">
          <li v-for="address in addresses" :key="address.id" class="rounded-2xl border bg-card p-5" data-test="address-card">
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-display text-base font-semibold text-foreground">{{ address.label || t('address_untitled', 'Address', 'عنوان') }}</span>
                  <span v-if="address.is_default" data-test="default-badge" class="rounded-md bg-success/15 px-2.5 py-0.5 text-xs font-medium text-success">
                    {{ t('address_default', 'Default', 'افتراضي') }}
                  </span>
                </div>
                <p class="mt-1 text-sm break-words text-muted-foreground">{{ address.address_line }}</p>
                <p class="mt-1 text-sm text-muted-foreground" dir="ltr">{{ address.phone }}</p>
                <p v-if="address.notes" class="mt-1 text-xs text-muted-foreground">{{ address.notes }}</p>
                <p v-if="address.delivery_zone" class="mt-2 text-xs text-muted-foreground">
                  {{ address.delivery_zone }} · {{ t('address_zone_fee', 'Delivery :fee', 'التوصيل :fee', { fee: format(address.delivery_fee) }) }}
                </p>
              </div>
              <div class="flex shrink-0 gap-1">
                <button
                  v-if="!address.is_default"
                  type="button"
                  class="flex size-9 items-center justify-center rounded-xl text-foreground/60 transition-colors hover:bg-brand-mist hover:text-foreground disabled:opacity-50"
                  :aria-label="t('address_make_default', 'Make default', 'اجعله الافتراضي')"
                  :title="t('address_make_default', 'Make default', 'اجعله الافتراضي')"
                  :disabled="promoting === address.id"
                  data-test="make-default"
                  @click="makeDefault(address)"
                >
                  <LucideStar class="size-4" :class="promoting === address.id ? 'animate-pulse' : ''" />
                </button>
                <a
                  v-if="address.map_url"
                  :href="address.map_url"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="flex size-9 items-center justify-center rounded-xl text-foreground/60 transition-colors hover:bg-brand-mist hover:text-foreground"
                  :aria-label="t('address_open_map', 'Open in maps', 'افتح في الخرائط')"
                >
                  <LucideMap class="size-4" />
                </a>
                <button
                  type="button"
                  class="flex size-9 items-center justify-center rounded-xl text-foreground/60 transition-colors hover:bg-brand-mist hover:text-foreground"
                  :aria-label="t('edit', 'Edit', 'تعديل')"
                  data-test="edit-address"
                  @click="openEdit(address)"
                >
                  <LucidePencil class="size-4" />
                </button>
                <button
                  type="button"
                  class="flex size-9 items-center justify-center rounded-xl text-destructive/70 transition-colors hover:border-destructive hover:bg-destructive hover:text-white hover:text-destructive"
                  :aria-label="t('delete', 'Delete', 'حذف')"
                  data-test="delete-address"
                  @click="confirming = address"
                >
                  <LucideTrash2 class="size-4" />
                </button>
              </div>
            </div>
          </li>
        </ul>

        <Button data-test="add-address" class="h-12 rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90 sm:self-start sm:px-8" @click="openAdd">
          <LucidePlus class="size-4" />
          {{ t('add_address', 'Add an address', 'إضافة عنوان') }}
        </Button>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="formOpen" class="fixed inset-0 z-[60] flex items-center justify-center p-4" role="dialog" aria-modal="true">
        <div class="fixed inset-0 bg-black/50" @click="formOpen = false" />
        <!-- Wider than the other dialogs: the national-address form is a dozen fields, and
             at `max-w-md` they stack into a column taller than any screen. -->
        <div class="relative max-h-[90svh] w-full max-w-2xl overflow-y-auto rounded-2xl border bg-background p-6 shadow-lg">
          <div class="mb-5 flex items-center justify-between">
            <span class="flex items-center gap-3">
              <span class="flex size-9 items-center justify-center rounded-xl bg-brand-terracotta/10 text-brand-terracotta"><LucideMapPin class="size-4" /></span>
              <span class="font-display text-base font-semibold">
                {{ editing ? t('edit_address', 'Edit address', 'تعديل العنوان') : t('add_address', 'Add an address', 'إضافة عنوان') }}
              </span>
            </span>
            <button type="button" class="text-muted-foreground transition-colors hover:text-foreground" :aria-label="t('close', 'Close', 'إغلاق')" @click="formOpen = false">
              <LucideX class="size-5" />
            </button>
          </div>
          <AddressForm :address="editing" @saved="onSaved" @cancel="formOpen = false" />
        </div>
      </div>
    </Teleport>

    <Teleport to="body">
      <div v-if="confirming" class="fixed inset-0 z-[60] flex items-center justify-center p-4" role="dialog" aria-modal="true">
        <div class="fixed inset-0 bg-black/50" @click="deleting || (confirming = null)" />
        <div class="relative max-h-[90svh] w-full max-w-md overflow-y-auto rounded-2xl border bg-background p-6 shadow-lg">
          <div class="mb-4 flex items-center gap-3">
            <span class="flex size-9 items-center justify-center rounded-xl bg-destructive/10 text-destructive"><LucideTrash2 class="size-4" /></span>
            <span class="font-display text-base font-semibold">{{ t('delete_address', 'Delete this address?', 'حذف هذا العنوان؟') }}</span>
          </div>
          <p class="text-sm text-muted-foreground">{{ confirming.address_line }}</p>
          <p v-if="confirming.is_default" class="mt-2 text-sm text-muted-foreground">
            {{ t('delete_default_address_note', 'It is your default address — another one takes over.', 'هذا عنوانك الافتراضي — سيحل محله عنوان آخر.') }}
          </p>
          <p v-if="deleteError" class="mt-3 text-xs text-destructive">{{ deleteError }}</p>
          <div class="mt-6 flex gap-3">
            <Button variant="outline" class="h-12 flex-1 rounded-xl text-base" :disabled="deleting" @click="confirming = null">
              {{ t('cancel', 'Cancel', 'إلغاء') }}
            </Button>
            <Button variant="destructive" class="h-12 flex-1 rounded-xl text-base" data-test="confirm-delete" :disabled="deleting" @click="onDelete">
              {{ deleting ? t('deleting', 'Deleting...', 'جارٍ الحذف...') : t('delete', 'Delete', 'حذف') }}
            </Button>
          </div>
        </div>
      </div>
    </Teleport>
  </main>
</template>

<script setup>
/**
 * The server keeps exactly one default address at all times — deleting the default
 * promotes another — so every write here is followed by the composable's refetch rather
 * than a local edit of the list.
 */
definePageMeta({
  // Entered from somewhere, with its own way back in the header — the site's
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'addresses',
})

const { t } = useLang('web', 'addresses')

// Reached from the profile, so the trail says so — and PageBar's arrow follows it.
const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/profile', label: t('nav_profile', 'Profile', 'حسابي', { subGroup: 'general' }) },
  { label: t('addresses_title', 'My addresses', 'عناويني') },
])
const { format } = usePrice()
const toast = useToast()
const { addresses, pending, error: loadError, refresh, remove, save } = useAddresses()

const formOpen = ref(false)
const editing = ref(null)

const openAdd = () => { editing.value = null; formOpen.value = true }
const openEdit = (address) => { editing.value = address; formOpen.value = true }

const onSaved = () => {
  formOpen.value = false
  toast.success(t('address_saved', 'Address saved.', 'تم حفظ العنوان.'))
}

/**
 * One tap, not a round trip through the whole form. The update endpoint takes the record
 * it was given, which is what Edit already posts — so this is the same call with one
 * field flipped, and the server's "exactly one default" rule demotes the old one.
 */
const promoting = ref(null)
const makeDefault = async (address) => {
  promoting.value = address.id
  try {
    await save({ ...emptyAddressForm(), ...address, is_default: true }, address.id)
    toast.success(t('address_default_set', 'Default address updated.', 'تم تحديث العنوان الافتراضي.'))
  } catch (e) {
    toast.error(normalizeApiError(e).message)
  } finally {
    promoting.value = null
  }
}

const confirming = ref(null)

// The page behind a dialog stays where it was left.
useModalScrollLock(formOpen);
useModalScrollLock(confirming);
const deleting = ref(false)
const deleteError = ref('')

const onDelete = async () => {
  deleting.value = true
  deleteError.value = ''
  try {
    await remove(confirming.value.id)
    confirming.value = null
    toast.success(t('address_deleted', 'Address deleted.', 'تم حذف العنوان.'))
  } catch (e) {
    deleteError.value = normalizeApiError(e).message
    await refresh()
  } finally {
    deleting.value = false
  }
}
</script>
