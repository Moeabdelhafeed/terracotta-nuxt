export default defineNuxtRouteMiddleware((to) => {
  const { user, isAuthenticated } = useSanctumAuth()
  const isGuest = !!user.value?.data?.is_guest
  if (isAuthenticated.value && !isGuest) return

  // On the client the reader is already looking at a page, so ASK there rather than
  // replacing it: cancelling the navigation keeps them where they were. On the server
  // there is nothing rendered to ask in front of, so the redirect still stands.
  if (import.meta.client) {
    useLoginPrompt().ask(to.fullPath)
    return false
  }

  return navigateTo({ name: 'login', query: to.fullPath === '/' ? {} : { redirect: to.fullPath } })
})
