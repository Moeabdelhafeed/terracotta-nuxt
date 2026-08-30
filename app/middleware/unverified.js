export default defineNuxtRouteMiddleware(() => {
    const { user } = useSanctumAuth()

    if (user.value && user.value?.data?.verified_at) {
        return navigateTo({ name: 'home' })
    }
})
