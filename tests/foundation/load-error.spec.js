// @vitest-environment nuxt
import { describe, it, expect, vi } from 'vitest'
import { mockNuxtImport, mountSuspended } from '@nuxt/test-utils/runtime'

/**
 * A failed request must not read as an empty one. `useApiFetch`/`useApiList` resolve to
 * their `default` on a rejection, so every list on this site used to answer an outage
 * with its own "nothing here yet" copy and no way to try again.
 */
const { api, lang, sanctum, server } = await vi.hoisted(async () => {
  const { createApiMock, envelope, apiError, createLang, createSanctumState } = await import('../helpers/mockApi')
  const server = { orders: 'empty' }
  return {
    server,
    api: createApiMock({
      'GET /api/shop/orders': () => {
        if (server.orders === 'down') return apiError(503, {}, 'The studio is updating its shelves.')
        if (server.orders === 'offline') return { error: { status: 0, body: null } }
        return envelope({ data: [], current_page: 1, last_page: 1, total: 0 })
      },
    }),
    lang: createLang('en'),
    sanctum: createSanctumState(),
  }
})

mockNuxtImport('useApi', () => api.useApi)
mockNuxtImport('useApiFetch', () => api.useApiFetch)
mockNuxtImport('useLang', () => () => lang)
mockNuxtImport('useSanctumAuth', () => () => sanctum)

const AppLoadError = (await import('~/components/AppLoadError.vue')).default
const OrdersPage = (await import('~/pages/orders/index.vue')).default

describe('AppLoadError', () => {
  it('renders nothing at all when there is no error', async () => {
    const wrapper = await mountSuspended(AppLoadError, { props: { error: null } })
    expect(wrapper.find('[data-test="load-error"]').exists()).toBe(false)
  })

  it('prints the server\'s own sentence when it sent one, and a retry that calls refresh', async () => {
    const retry = vi.fn()
    const wrapper = await mountSuspended(AppLoadError, {
      props: { error: { status: 503, data: { message: 'The studio is updating its shelves.' } }, retry },
    })

    expect(wrapper.text()).toContain('Something went wrong')
    expect(wrapper.text()).toContain('The studio is updating its shelves.')

    await wrapper.find('[data-test="load-error-retry"]').trigger('click')
    expect(retry).toHaveBeenCalled()
  })

  it('falls back to stock copy when the failure carries no readable message', async () => {
    const wrapper = await mountSuspended(AppLoadError, { props: { error: new Error('fetch failed') } })
    expect(wrapper.text()).toContain("We couldn't load this. Try again in a moment.")
    expect(wrapper.text()).not.toContain('fetch failed')
  })
})

describe('a list that failed vs a list that is empty', () => {
  const mount = () => mountSuspended(OrdersPage, {
    global: { stubs: { AppSkeleton: true, NuxtLink: { template: '<a><slot /></a>' } } },
  })

  it('shows the empty copy when the server really has nothing', async () => {
    server.orders = 'empty'
    const page = await mount()
    await vi.waitFor(() => expect(page.text()).toContain('No orders yet'))
    expect(page.find('[data-test="load-error"]').exists()).toBe(false)
  })

  it('shows the failure and a retry — never "No orders yet" — when the request failed', async () => {
    server.orders = 'down'
    const page = await mount()

    await vi.waitFor(() => expect(page.find('[data-test="load-error"]').exists()).toBe(true))
    expect(page.text()).not.toContain('No orders yet')
    expect(page.text()).toContain('The studio is updating its shelves.')

    // The retry is the composable's own refresh, so a recovered server fills the page.
    server.orders = 'empty'
    await page.find('[data-test="load-error-retry"]').trigger('click')
    await vi.waitFor(() => expect(page.text()).toContain('No orders yet'))
    expect(page.find('[data-test="load-error"]').exists()).toBe(false)
  })
})
