export default defineNuxtRouteMiddleware(() => {
  const { user } = useSanctumAuth()
  const isGuest = !!user.value?.data?.is_guest
  if (!isGuest) {
    return navigateTo('/')
  }
})
