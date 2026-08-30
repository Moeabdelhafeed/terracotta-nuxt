export default defineNuxtRouteMiddleware(() => {
    const { user } = useSanctumAuth()
    const isGuest = !!user.value?.data?.is_guest
    if (user.value && !isGuest && !user.value?.data?.verified_at) {
        return navigateTo({ name: 'verify' })
    }
})
