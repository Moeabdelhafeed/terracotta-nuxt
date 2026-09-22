/**
 * Hold the page still while a modal is open.
 *
 * Without it a scroll inside the panel chains to the page underneath once the panel hits
 * its own end, so the list behind the dialog creeps away and is somewhere else when the
 * dialog closes. Locking the body stops that; the panel keeps its own scroll.
 *
 * @param {import('vue').Ref<boolean>} isOpen
 */
export const useModalScrollLock = (isOpen) => {
  if (import.meta.server) return

  const locked = useScrollLock(document.body)

  watch(isOpen, (open) => {
    locked.value = !!open
  })

  // A route change can unmount the page with the dialog still open, which would leave the
  // body locked and the whole site unscrollable.
  onBeforeUnmount(() => {
    locked.value = false
  })
}
