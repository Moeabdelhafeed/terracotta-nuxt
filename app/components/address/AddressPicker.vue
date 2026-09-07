<template>
  <div class="flex flex-col gap-3">
    <div v-if="pending && !addresses.length" class="flex flex-col gap-2" aria-busy="true">
      <AppSkeleton v-for="n in 2" :key="n" class="h-20 w-full !rounded-2xl" />
    </div>

    <template v-else>
      <label
        v-for="address in addresses"
        :key="address.id"
        class="flex cursor-pointer items-start gap-3 rounded-2xl border bg-card p-4 transition-colors"
        :class="selected === address.id ? 'border-brand-rust/60 bg-brand-mist/40' : 'hover:bg-accent/5'"
      >
        <input
          type="radio"
          name="address"
          class="mt-1 size-4 accent-brand-rust"
          :value="address.id"
          :checked="selected === address.id"
          @change="selected = address.id"
        />
        <span class="min-w-0 flex-1">
          <span class="flex items-center gap-2">
            <span class="font-medium text-foreground">{{ address.label || address.delivery_zone || t('address_untitled', 'Address', 'عنوان') }}</span>
            <span v-if="address.is_default" class="rounded-full bg-brand-mist px-2 py-0.5 text-xs text-brand-rust">{{ t('address_default', 'Default', 'افتراضي') }}</span>
          </span>
          <span class="mt-0.5 block text-sm text-muted-foreground">{{ address.address_line }}</span>
          <span class="mt-0.5 block text-xs text-muted-foreground" dir="ltr">{{ address.phone }}</span>
        </span>
      </label>

      <p v-if="!addresses.length" class="rounded-2xl border border-dashed p-4 text-center text-sm text-muted-foreground">
        {{ t('address_none_yet', 'No saved addresses yet.', 'لا توجد عناوين محفوظة بعد.') }}
      </p>

      <button
        type="button"
        class="flex items-center justify-center gap-2 rounded-2xl border border-dashed p-3 text-sm font-medium text-brand-rust transition-colors hover:bg-brand-mist/40"
        @click="adding = true"
      >
        <LucidePlus class="size-4" />
        {{ t('address_add', 'Add a new address', 'إضافة عنوان جديد') }}
      </button>
    </template>

    <Teleport to="body">
      <div v-if="adding" class="fixed inset-0 z-50 flex items-center justify-center p-4" role="dialog" aria-modal="true">
        <div class="absolute inset-0 bg-black/50" @click="adding = false" />
        <div class="relative max-h-[90svh] w-full max-w-lg overflow-y-auto rounded-2xl border bg-background p-6 shadow-lg">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span class="flex size-9 items-center justify-center rounded-xl bg-brand-mist text-brand-rust">
                <LucideMapPin class="size-4" />
              </span>
              <h2 class="font-display text-lg font-semibold text-foreground">{{ t('address_add', 'Add a new address', 'إضافة عنوان جديد') }}</h2>
            </div>
            <button type="button" class="text-muted-foreground transition-colors hover:text-foreground" @click="adding = false">
              <LucideX class="size-5" />
            </button>
          </div>
          <div class="mt-5">
            <AddressForm @saved="onSaved" @cancel="adding = false" />
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
/**
 * Choose a saved address (`v-model` = its id) or add one inline. Selects the default
 * address on first load so a checkout can quote immediately.
 */
const selected = defineModel({ type: Number, default: null })
const { t } = useLang('web', 'addresses')
const { addresses, defaultAddress, pending } = useAddresses()

const adding = ref(false)

watch(defaultAddress, (address) => {
  if (address && selected.value === null) selected.value = address.id
}, { immediate: true })

const onSaved = (address) => {
  adding.value = false
  if (address?.id) selected.value = address.id
}
</script>
