/**
 * The routes only the API knows about: every product, workshop, gallery album and CMS
 * page. `@nuxtjs/sitemap` fetches this and merges it with the file-based routes.
 *
 * Called server-side, so it goes straight to Laravel with the private token rather than
 * through the browser-facing proxy.
 */
const LOCALE = 'ar'

export default defineEventHandler(async (event) => {
  const { xApiToken, apiBaseUrl } = useRuntimeConfig(event)

  const headers = {
    'X-API-TOKEN': xApiToken,
    'X-Device-Id': 'web-sitemap',
    'X-Platform': 'web',
    'Accept-Language': LOCALE,
  }

  const get = async (path) => {
    try {
      const res = await $fetch(`${apiBaseUrl}${path}`, { headers })
      const data = res?.data ?? []
      // A paginated endpoint answers `{ data: [...] }`; the rest answer a bare array.
      return Array.isArray(data) ? data : (data.data ?? [])
    } catch {
      // A sitemap missing one section beats a sitemap that fails to build.
      return []
    }
  }

  const [products, workshops, albums, pages] = await Promise.all([
    get('/api/shop/products?per_page=all'),
    get('/api/workshops'),
    get('/api/gallery'),
    get('/api/pages'),
  ])

  return [
    ...products.map((item) => ({ loc: `/shop/${item.id}`, _sitemap: 'shop' })),
    ...workshops.map((item) => ({ loc: `/workshops/${item.id}`, _sitemap: 'workshops' })),
    ...albums.map((item) => ({ loc: `/gallery/${item.id}`, _sitemap: 'gallery' })),
    ...pages.map((item) => ({ loc: `/${item.slug}` })),
  ]
})
