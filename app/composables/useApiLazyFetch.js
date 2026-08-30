/**
 * Lazy data fetcher. Same dispatch as `useApiFetch` but forces `lazy: true`.
 * Use when SSR shouldn't block — component renders immediately, data ref
 * fills in client-side.
 *
 * @type {typeof import('#app').useLazyFetch}
 */
export const useApiLazyFetch = (url, options = {}) => {
  return useApiFetch(url, { ...options, lazy: true })
}
