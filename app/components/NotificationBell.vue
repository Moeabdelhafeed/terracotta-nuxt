<template>
  <NuxtLink
    v-if="isRegistered"
    to="/notifications"
    class="relative flex size-10 items-center justify-center rounded-xl transition-colors"
    :class="active ? 'bg-white text-brand-ink' : 'text-white/75 hover:text-white'"
    :aria-label="t('nav_notifications', 'Notifications', 'الإشعارات')"
  >
    <LucideBell class="size-4" />
    <span
      v-if="unreadCount > 0"
      class="absolute -top-0.5 -end-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-brand-blush px-1 text-[10px] font-semibold text-brand-ink"
      dir="ltr"
    >{{ unreadCount > 99 ? '99+' : unreadCount }}</span>
  </NuxtLink>
</template>

<script setup>
/** The inbox entry in the floating nav, with the unread badge kept fresh by polling. */
const route = useRoute()
const { t } = useLang('web', 'general')
const { unreadCount, isRegistered } = useUnreadCount()

const active = computed(() => route.path.startsWith('/notifications'))
</script>
