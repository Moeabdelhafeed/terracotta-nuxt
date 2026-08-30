import { decode } from 'blurhash'

const BASE83 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~'
const decode83 = (chars) => [...chars].reduce((acc, c) => acc * 83 + BASE83.indexOf(c), 0)

/**
 * Background style that stands in for an asset until it paints: the hash's average colour
 * during SSR (its DC term decodes without a canvas), upgraded to the real 32×32 blur once
 * the client mounts. Returns `undefined` when there is no usable hash.
 *
 * @param {import('vue').MaybeRefOrGetter<string|null|undefined>} hash
 */
export const useBlurhash = (hash) => {
  const preview = ref(null)

  const averageColor = computed(() => {
    const h = toValue(hash)
    if (!h || h.length < 6) return null
    const dc = decode83(h.slice(2, 6))
    return `rgb(${dc >> 16}, ${(dc >> 8) & 255}, ${dc & 255})`
  })

  const render = (h) => {
    preview.value = null
    if (!h) return
    try {
      const size = 32
      const canvas = document.createElement('canvas')
      canvas.width = canvas.height = size
      const ctx = canvas.getContext('2d')
      const image = ctx.createImageData(size, size)
      image.data.set(decode(h, size, size))
      ctx.putImageData(image, 0, 0)
      preview.value = canvas.toDataURL()
    } catch {
      // Malformed hash — the average colour (or nothing) still covers the gap.
    }
  }

  onMounted(() => {
    watch(() => toValue(hash), render, { immediate: true })
  })

  const placeholderStyle = computed(() => {
    if (preview.value) {
      return {
        backgroundImage: `url(${preview.value})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
      }
    }
    return averageColor.value ? { backgroundColor: averageColor.value } : undefined
  })

  return { placeholderStyle, averageColor, preview }
}
