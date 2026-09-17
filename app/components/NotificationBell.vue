<template>
  <NuxtLink
    v-if="isRegistered"
    to="/notifications"
    class="relative flex size-[54px] items-center justify-center rounded-[5px] transition-colors"
    :class="active ? 'bg-white/15 text-white' : 'text-white/70 hover:bg-white/10 hover:text-white'"
    :aria-label="t('nav_notifications', 'Notifications', 'الإشعارات')"
  >
    <LucideBell class="size-[26px]" />
    <span
      v-if="unreadCount > 0"
      class="absolute top-2 end-2 flex h-4 min-w-4 items-center justify-center rounded-full bg-brand-blush px-1 text-[10px] font-semibold text-brand-ink"
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
