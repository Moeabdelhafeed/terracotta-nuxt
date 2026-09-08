/**
 * A visitor without an account keeps their basket and hearts in localStorage. The moment
 * they become a registered account the local copy is handed to the server and dropped.
 *
 * Hooked once here rather than at each sign-in call site: password login, OTP verify,
 * firebase and register are four ways into the same state change, and they all have to
 * behave the same. Client-only — localStorage is the source.
 */
export const shouldPushLocalShop = (isRegistered, cartIds, favoriteIds) =>
  !!isRegistered && !!(cartIds?.length || favoriteIds?.length)

export default defineNuxtPlugin((nuxtApp) => {
  const { isRegistered } = useIsRegistered()

  let pushing = false

  watch(
    // A reload that still owes a push arrives with the session already restored, so the
    // length is watched too — `isRegistered` alone never changes on that path.
    [isRegistered, () => localCartIds.value.length + localFavoriteIds.value.length],
    () => {
      if (pushing || !shouldPushLocalShop(isRegistered.value, localCartIds.value, localFavoriteIds.value)) return
      pushing = true

      // Never awaited by the caller: a slow or failed push must not hold up navigation.
      // `useApi`/`useLang` reach for the Sanctum client, which is only installed once the
      // app is running — so they are resolved here and not at plugin setup.
      nuxtApp.runWithContext(async () => {
        const api = useApi()
        const { t } = useLang('web', 'shop')
        try {
          const { dropped } = await pushLocalShopToServer(api)
          if (dropped > 0) {
            useToast().info(t(
              'cart_items_dropped',
              ':n item(s) in your basket are no longer available and were removed.',
              'لم تعد :n من القطع في سلتك متاحة وتمت إزالتها.',
              { n: dropped },
            ))
          }
        } catch {
          // The basket stays in storage; the next sign-in tries again.
        } finally {
          pushing = false
        }
      })
    },
    { immediate: true },
  )
})
