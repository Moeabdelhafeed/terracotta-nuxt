/**
 * Guests are created by visiting the site, not by pressing a button: any visitor who
 * lands anywhere with `app_guests` on gets a guest identity so carts, favourites and
 * bookings have somewhere to live from the first tap.
 *
 * Client-only on purpose — running it during SSR would mint a guest row for every
 * crawler hit. The backend keys guests by `X-Device-Id` and reuses the existing row,
 * so this is idempotent per device.
 *
 * Goes through `$publicApi`, not the Sanctum client: creating a guest needs no bearer,
 * and the Sanctum client's token storage is only installed on `page:loading:start`,
 * which happens after plugins run — asking for it here throws
 * "`sanctum.tokenStorage` is not defined in app.config.ts".
 */
export default defineNuxtPlugin(async () => {
  const { appGuests } = useAuthConfig()
  const user = useSanctumUser()

  if (!appGuests.value || user.value) return

  try {
    const res = await useNuxtApp().$publicApi('/api/guest', { method: 'POST' })
    const guest = res?.data?.user ?? res?.user ?? null

    // Store the same envelope shape `/api/user` returns — the app reads
    // `user.value.data.is_guest`, and handing it a bare user object makes a guest look
    // like a signed-in member (`is_guest` reads as undefined).
    if (guest) {
      user.value = { ...(res ?? {}), data: guest }
    }
  } catch (err) {
    // 403 means the device already belongs to a registered account — nothing to do.
    if (err?.response?.status !== 403) {
      console.warn('[auto-guest] could not create a guest identity', err?.data?.message ?? err?.message ?? err)
    }
  }
})
