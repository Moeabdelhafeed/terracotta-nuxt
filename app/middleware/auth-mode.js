export default defineNuxtRouteMiddleware(async () => {
  const { cfg, refresh } = useAuthConfig()
  if (!cfg.value || !Object.keys(cfg.value).length) {
    await refresh()
  }
  if (cfg.value && cfg.value.app_users === false) {
    return navigateTo('/')
  }
})
