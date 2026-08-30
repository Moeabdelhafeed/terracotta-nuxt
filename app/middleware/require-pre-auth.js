export default defineNuxtRouteMiddleware(async () => {
  const { appUsers, appGuests, cfg, refresh } = useAuthConfig()
  if (!cfg.value || !Object.keys(cfg.value).length) {
    await refresh()
  }
  // No auth system at all — pre-auth pages (login/register/verify/forgot) have
  // nothing to show. Send to the public home.
  if (!appUsers.value && !appGuests.value) {
    return navigateTo('/')
  }
  const { user, isAuthenticated } = useSanctumAuth()
  const isGuest = !!user.value?.data?.is_guest
  if (isAuthenticated.value && !isGuest) {
    return navigateTo('/')
  }
})
