/**
 * Ending the local session, whatever the server says.
 *
 * `useSanctumAuth().logout()` clears `user` and the stored token only AFTER its request
 * resolves, so any failure leaves the browser holding a session:
 *
 *  - Sign out while offline, or into a 401/403/429, and the call throws before the clear.
 *    The token cookie survives, the UI still shows the account, and the navigation never
 *    runs. Tapping again just repeats it.
 *  - Delete the account and the failure is guaranteed: `DELETE /api/delete-account` drops
 *    every token server-side, so the `POST /api/logout` that follows is a 401. Swallowing
 *    it left `user` populated, and `require-pre-auth` then bounced the visitor off /login
 *    back to the home page, apparently still signed in to an account that no longer exists.
 *
 * So the request is best-effort and the local clear is not.
 */
export const useSignOut = () => {
  const { logout } = useSanctumAuth()
  const user = useSanctumUser()
  const app = useNuxtApp()
  const sanctum = useSanctumAppConfig()

  const clearLocalSession = async () => {
    user.value = null
    await sanctum?.tokenStorage?.set?.(app, undefined)
    if (import.meta.client) document.cookie = 'current_token_id=; path=/; max-age=0'
  }

  /** Tell the server, then clear locally regardless of what it answered. */
  const signOut = async () => {
    await logout().catch(() => {})
    await clearLocalSession()
  }

  return { signOut, clearLocalSession }
}
