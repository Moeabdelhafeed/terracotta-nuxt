/**
 * Site-wide transient notices ("Added to cart", "Address saved"). One shared queue,
 * rendered once by `<AppToaster>` in the default layout — outside `#smooth-content`, since
 * anything fixed inside ScrollSmoother scrolls away.
 *
 * Field-level validation still belongs inline next to its input; this is for outcomes
 * that happen away from a form, or after one closes.
 */
const toasts = ref([])
let seq = 0

export const useToast = () => {
  const push = (message, { kind = 'success', duration = 4000 } = {}) => {
    if (!message) return
    const id = ++seq
    toasts.value = [...toasts.value, { id, message, kind }]
    if (import.meta.client && duration > 0) {
      setTimeout(() => dismiss(id), duration)
    }
    return id
  }

  const dismiss = (id) => {
    toasts.value = toasts.value.filter((toast) => toast.id !== id)
  }

  return {
    toasts,
    dismiss,
    success: (message, opts) => push(message, { ...opts, kind: 'success' }),
    error: (message, opts) => push(message, { ...opts, kind: 'error', duration: opts?.duration ?? 6000 }),
    info: (message, opts) => push(message, { ...opts, kind: 'info' }),
  }
}
