/**
 * Method-override for the Sanctum client.
 *
 * The production host (LiteSpeed/Apache) blocks real PUT/PATCH/DELETE requests,
 * so every such call is sent as POST with an `X-HTTP-Method-Override` header
 * carrying the real verb. Laravel's kernel resolves the verb from the header,
 * so the API routes stay `Route::put(...)` / `Route::delete(...)`.
 *
 * `_method` is sent in the query string as well as the header, because a hop that
 * strips unknown `X-` headers would turn a DELETE into a bare POST to the same URI —
 * a delete that reads as a create. Laravel honours either (`httpMethodParameterOverride`).
 *
 * nuxt-auth-sanctum fires the `sanctum:request` hook on every request made by
 * `useSanctumClient` / `useSanctumFetch`, so this one hook covers them all.
 * The plain `$publicApi` instance applies the same rule in its own onRequest.
 */
export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.hook('sanctum:request', (_app, ctx) => {
    const { options } = ctx
    const method = String(options.method ?? 'GET').toUpperCase()

    if (method === 'PUT' || method === 'PATCH' || method === 'DELETE') {
      const headers = new Headers(options.headers)
      headers.set('X-HTTP-Method-Override', method)
      options.headers = headers
      options.query = { ...options.query, _method: method }
      options.method = 'POST'
    }
  })
})
