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
  const { user, isAuthenticated } = useSanctumAuth();

  const account = computed(() => user.value?.data ?? user.value ?? null);
  const isGuest = computed(() => !!account.value?.is_guest);

  const isRegistered = computed(
    () => !!user.value && isAuthenticated.value !== false && !isGuest.value,
  );

  return {
    account,
    isGuest,
    isRegistered,
    /**
     * A real account that has not yet entered its code. Guests are never "unverified" —
     * they have nothing to verify — and neither is a visitor with no account at all, so
     * both answer `false` and nothing asks them to confirm anything.
     */
    needsVerification: computed(
      () => isRegistered.value && !account.value?.verified_at,
    ),
  };
};
