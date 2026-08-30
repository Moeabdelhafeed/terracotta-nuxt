export default defineNuxtRouteMiddleware(async () => {
  const { appUsers, appGuests, cfg, refresh } = useAuthConfig()
  if (!cfg.value || !Object.keys(cfg.value).length) {
    await refresh()
  }
  // No auth system at all (app_users + app_guests both off) — the app is a
  // public content app with no user concept. Let the route through.
  if (!appUsers.value && !appGuests.value) {
    return
  }
  const { isAuthenticated } = useSanctumAuth()
  if (isAuthenticated.value) {
    return
  }

  // Guests are minted automatically on the client (plugins/04.auto-guest.client.js), and
  // this guard also runs during SSR — where that has not happened yet. Bouncing here would
  // send every first-time visitor to /login for an identity they are about to be given.
  // Only a project with guests switched off still needs the redirect.
  if (appGuests.value) {
    return
  }

  return navigateTo({ name: 'login' })
})
