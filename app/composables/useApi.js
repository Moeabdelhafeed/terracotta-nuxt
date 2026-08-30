/**
 * Unified API client. Dispatches to Sanctum (Bearer + auth lifecycle) when
 * `app_users=true`, else to the plain `$publicApi` instance. Both transports
 * carry the same X-Device-Id, X-Platform, X-FCM-Token, Accept-Language headers
 * — only Bearer differs. X-API-TOKEN is added server-side by the Nitro proxy
 * (server/api/[...].js), never here.
 *
 * Use for any imperative API call (POST/PUT/DELETE or GET when SSR cache
 * isn't needed). For SSR-friendly data fetching see `useApiFetch`.
 *
 * @returns {import('ofetch').$Fetch}
 */
export const useApi = () => {
  const { appUsers } = useAuthConfig()
  if (appUsers.value) return useSanctumClient()
  return useNuxtApp().$publicApi
}
