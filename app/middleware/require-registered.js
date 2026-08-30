export default defineNuxtRouteMiddleware(() => {
  const { user, isAuthenticated } = useSanctumAuth()
  const isGuest = !!user.value?.data?.is_guest
  if (!isAuthenticated.value || isGuest) {
    return navigateTo({ name: 'login' })
  }
})
