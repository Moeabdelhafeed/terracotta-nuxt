export default defineNuxtRouteMiddleware(() => {
  const { cfg } = useAuthConfig()
  if (cfg.value?.auth_mode === 'otp') {
    return navigateTo({ name: 'login' })
  }
})
