export default defineNuxtRouteMiddleware(() => {
  const { cfg } = useAuthConfig()
  if (cfg.value && Object.keys(cfg.value).length && !cfg.value.multi_session) {
    return navigateTo('/profile')
  }
})
