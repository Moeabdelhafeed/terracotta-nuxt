/**
 * "Signed in with a real account", the one question six domains kept answering slightly
 * differently.
 *
 * Everyone gets a guest identity automatically (see `plugins/04.auto-guest.client.js`), so
 * `isAuthenticated` alone is not it — a guest would be offered a profile, a cart and a
 * gift to claim, and then be bounced by the middleware. The payload is normally wrapped
 * (`user.data`), but not on every path that fills it, and reading only `user.data.is_guest`
 * silently promotes a guest to registered when it is not; check both shapes.
 */
export const useIsRegistered = () => {
  const { user, isAuthenticated } = useSanctumAuth()

  const account = computed(() => user.value?.data ?? user.value ?? null)
  const isGuest = computed(() => !!(account.value?.is_guest))

  return {
    account,
    isGuest,
    isRegistered: computed(() => !!user.value && isAuthenticated.value !== false && !isGuest.value),
  }
}
