export default defineNuxtPlugin(() => {
  const user = useSanctumUser()
  const tokenIdCookie = useCookie('current_token_id', { sameSite: 'lax' })
  const { $echo } = useNuxtApp()

  let activeUserId = null

  const userId = (u) => u?.data?.id ?? u?.id ?? null

  const handleRevoke = async (event) => {
    const local = Number(tokenIdCookie.value)
    if (!local || Number(event?.token_id) !== local) return
    document.cookie = 'current_token_id=; path=/; max-age=0'
    document.cookie = 'sanctum.token.cookie=; path=/; max-age=0'
    user.value = null
    await navigateTo('/login')
  }

  const subscribe = (uid) => {
    if (!$echo || !uid) return
    activeUserId = uid
    $echo.private(`user.${uid}`).listen('.device.revoked', handleRevoke)
  }

  const unsubscribe = () => {
    if ($echo && activeUserId) $echo.leave(`user.${activeUserId}`)
    activeUserId = null
  }

  watch(
    () => userId(user.value),
    (next) => {
      if (activeUserId === next) return
      unsubscribe()
      if (next) subscribe(next)
    },
    { immediate: true },
  )
})
