# CLAUDE.md

Project conventions and architecture notes for this Nuxt 4 starter. Loaded automatically into Claude's context.

## Stack

- **Nuxt 4** + Vue 3 (composition API, `<script setup>`).
- **Plain JavaScript only** — no TypeScript files. Composables are `.js`, plugins are `.js`, Vue `<script setup>` has no `lang="ts"`. Existing TS files in `node_modules`/shadcn UI components are vendor; do not introduce TS in app code. (See [memory/feedback_js_only.md](.claude/memory/feedback_js_only.md).)
- **Tailwind v4** via `@tailwindcss/vite` plugin. CSS in `app/assets/css/main.css`.
- **shadcn-vue** components installed via `shadcn-nuxt` module. Auto-imported. Stored in `app/components/ui/<component>/`.
- **reka-ui** (vue port of radix) underlies shadcn. `<ConfigProvider :dir>` in [app/app.vue](app/app.vue) propagates RTL/LTR to all reka components.
- **@nuxtjs/i18n** for local-file translations (en.json / ar.json). Used only in `local` translation mode.
- **nuxt-auth-sanctum** for Laravel Sanctum auth. Token mode. Composables: `useSanctumAuth`, `useSanctumClient`, `useSanctumFetch`.
- **@nuxtjs/seo**, `motion-v`, `nuxt-lucide-icons`, `v-gsap-nuxt`, `@vueuse/nuxt` available.

## Backend contract

Laravel API at `runtimeConfig.public.baseUrl` (default `http://localhost:8000`). Every request gets:
- `X-API-TOKEN: <runtimeConfig.public.xApiToken>` (from `.env` `NUXT_PUBLIC_X_API_TOKEN`).
- `Accept-Language: <locale code>` (sourced based on translations mode — see below).

**Method override (mandatory):** the production host blocks real `PUT`/`PATCH`/`DELETE`. Both transports rewrite those to **`POST` + an `X-HTTP-Method-Override` header** carrying the real verb — the Sanctum client via the `sanctum:request` hook in [app/plugins/02.method-override.js](app/plugins/02.method-override.js), and `$publicApi` in its own `onRequest` ([app/plugins/01.public-api.js](app/plugins/01.public-api.js)). So you still write `useApi()('/api/...', { method: 'PUT' })` as normal — it goes out as POST automatically. Don't hand-roll a bare `$fetch` for a mutating call; route it through `useApi` / `useSanctumClient` / `useSanctumFetch` so the override applies.

Auth endpoints (Sanctum module config in [nuxt.config.ts](nuxt.config.ts)):
- `POST /api/login`, `POST /api/logout`, `GET /api/user` for session.
- `POST /api/verify-login` (OTP mode only) — `{ identifier, otp }` → `{ token, user, is_verified, token_id, account_restored? }`.
- `POST /api/register`, `POST /api/check-identifier`, `POST /api/forgot-password`, `POST /api/verify-forgot-password-otp`, `POST /api/change-forgot-password`, `POST /api/verify-otp`, `POST /api/send-otp`.
- `PUT /api/update-profile`, `POST /api/change-password`, `POST /api/request-identifier-change`, `POST /api/verify-identifier-change`, `DELETE /api/delete-account`.
- `GET /api/social-accounts`, `POST /api/link-social-account`, `DELETE /api/unlink-social-account`.

Config endpoints:
- `GET /api/config` — returns `{ identifiers, has_username_field, has_email_field, has_phone_field, social_providers, max_social_accounts, social_auth_available, is_otp_whatsapp, multi_session, app_users, app_guests, auth_mode, allowed_email_domains, allowed_phone_countries }`. Drives form rendering. `auth_mode` ∈ `{ 'password', 'otp' }` (default `password`).
  - `allowed_email_domains` — the string `"all"` (unrestricted) **or** an array like `["gmail.com","yahoo.com"]`. When an array, pre-validate the email domain client-side before submit and surface an inline error for others.
  - `allowed_phone_countries` — the string `"all"` **or** an array of ISO country codes like `["JO","SA","US"]`. When an array, restrict the phone country-code picker to those.
- `GET /api/languages` — returns array of `{ id, code, name, native_name, direction, is_default, image: { image_api } }`.
- `GET /api/translations?group=web` — returns `{ key: "value with :placeholders" }` flat map for current `Accept-Language` header.
- `POST /api/translations` — body `{ translations: { key: value }, group }`. Used in remote mode to seed missing keys.
- `GET /api/app-settings` — public (no Bearer), gated by backend `HAS_APP_SETTINGS`. Returns the app's link blocks, localized via `Accept-Language`. `data` always has all five keys (empty arrays when unset), each item ordered by `sort_order`, active only:
  ```json
  { "social": [{ "id": 1, "text": "Twitter", "url": "https://…", "image": { "id": 7, "url": "app-settings/x.webp", "type": "webp", "blurhash": "L…", "image_api": "https://…" } }],
    "contact": [], "app_store": [], "google_play": [], "app_gallery": [] }
  ```
  Use for footer/social icons, contact links, and store badges. `image` is the backend Image object or `null` — render it with `<AppImage>`, never bind `image` itself; `text` is the current-locale label. Consume via `useAppSettings()` (see below).
- `GET /api/pages` / `GET /api/pages/{slug}` — public, gated by backend `HAS_PAGES`. Active CMS pages localized via `Accept-Language`. Page shape `{ id, slug, name, content, image }` (`content` is markdown/HTML). Consume via `usePages()` / `usePage(slug)`.

### Content composables

Public, SSR-friendly, deduped, and locale-reactive (refetch when `lang` / `i18n_locale` cookie changes). All route through `useApiFetch` and unwrap the `{ data }` envelope:
### Backend media objects

Every asset the backend serializes goes through its own model, so the shape is the same everywhere:

- **Image** — `{ id, url, type, blurhash, image_api }`. `image_api` is the public URL; `url` is the stored path, so never bind `:src` to it.
- **Video** — `{ id, url, type, video_api, thumbnail }`, where `thumbnail` is an Image object (or `null`).
- **File** — `{ id, url, type, name, size, file_api }`.

A field that holds one asset carries the object directly (`image` on app-settings items, pages, languages). A record that can be any of the three carries `{ type, image|video|file }` — `/api/media` items and gallery items — nested rather than flattened, since the morph has its own `id`/`type`.

Render them, never hand-roll an `<img>`:
- `<AppImage :src="imageObject" />` ([app/components/AppImage.vue](app/components/AppImage.vue)) — paints the blurhash behind the `<img>` until the file loads (average colour during SSR, decoded 32×32 canvas after hydration). Accepts a plain URL string too.
- `<AppMedia :src="asset" />` ([app/components/AppMedia.vue](app/components/AppMedia.vue)) — for a `{ type, … }` wrapper: image → `<AppImage>`, video → `<video>` postered with `thumbnail.image_api` and backed by its blurhash until playback starts, file → a link labelled with `name`.
- The placeholder itself is [useBlurhash()](app/composables/useBlurhash.js).

`useMedia()` exposes `mediaAsset(key, defaultPath?)` (the `{ type, … }` wrapper, or the `/public` fallback path as a string, seeding it to the backend as before) and `media()`, the same call narrowed to the public URL for `background-image` / og:image / anywhere an object is no use.

- `useAppSettings()` → `{ blocks, social, contact, appStore, googlePlay, appGallery, pending, error, refresh }`. Each block is an array of `{ id, text, url, image }` (`image` is an Image object or `null`).
- `usePages()` → `{ pages, bySlug(slug), pending, error, refresh }`.
- `usePage(slug)` → `{ page, pending, error, refresh }` (`slug` may be a ref).

Response envelope: `{ success, message, errors, data }`. Pages typically read `res?.data ?? res ?? {}` to be tolerant.

`/api/check-identifier` data shape (recent change):
```json
{
  "exists": true|false,
  "pending_deletion": true|false,
  "suspended": true|false,
  "available_channels": ["email", "phone"]
}
```
Branching:
- `!exists` → free identifier (register flow).
- `suspended` → block UI ("Account suspended. Contact support."). No login/forgot/register.
- `pending_deletion` → allow login; backend returns `account_restored: true` after successful login. Show modal confirmation before submit.
- otherwise → normal active.
- Pre-submit uniqueness for register/profile: treat any `exists:true` as "taken" regardless of `pending_deletion`/`suspended`.

### Identifier requests always declare a `type`

Every endpoint that takes an `identifier` / `new_identifier` also takes a **required `type`** (`email`, `phone`, or — login/check only — `username`). The API never infers the kind from the value's shape; a phone must therefore arrive **with its country code** and is stored in E.164 (`+966501234567`). Sending `0501234567` or `770000000` is a 422, not a guess.

Affected: `POST /api/login`, `/api/register`, `/api/check-identifier`, `/api/forgot-password`, `/api/verify-forgot-password-otp`, `/api/change-forgot-password`, `/api/verify-login`, `/api/request-identifier-change`, `/api/verify-identifier-change`.

On `POST /api/forgot-password` the two questions are separate fields:
- `type` — what the user typed to identify themselves (required).
- `channel` — where the reset code should be sent (`email` / `phone`, optional, defaults to email > phone). This is what the old `type` on that endpoint used to mean.

`useAuthConfig()` exposes `identifierTypes` (the kinds this project accepts) and `defaultIdentifierType`. Pages keep the selected kind in state — a picker when there is more than one, otherwise the single configured identifier — and send it with every request. Carry it through multi-step flows in the query string (`/verify-login?identifier=…&type=phone`) so each step declares the same thing.

## Translations system (`useLang`)

Single source of truth for locale + dir + translation lookup, in [app/composables/useLang.js](app/composables/useLang.js).

### Cookies

- `lang` — full language object `{ id, code, native_name, direction, is_default, image }`. Owned by `useLang`. UI components read this for image / native_name / dir / is_default without re-deriving from the languages list.
- `i18n_locale` — plain locale code. Owned by `@nuxtjs/i18n` (config in `detectBrowserLanguage.cookieKey`). When `useLang.setLanguage` runs, it calls `i18n.setLocale(code)` which writes this cookie too — keeping both sources in sync.

### Modes

Selected via `runtimeConfig.public.translationsMode` (override with `NUXT_PUBLIC_TRANSLATIONS_MODE=local|remote`):
- `'remote'` (default) — translations fetched live from `/api/translations?group=web`. Missing keys auto-seeded back to backend.
- `'local'` — translations sourced from JSON files in `i18n/locales/<code>.json` via `useI18n().getLocaleMessage(code)`. Missing keys written to those files via dev-only server endpoint `/api/dev-translations`.

[app/plugins/01.sanctum-listener.js](app/plugins/01.sanctum-listener.js) reads `translationsMode` to decide which cookie's code to put in `Accept-Language`:
- `local` → `i18n_locale` cookie (string), fallback `lang.code`, then `'en'`.
- `remote` → `lang.code`, fallback `'en'`.

### First render picks the language before anything else is fetched

[app/plugins/00.bootstrap-config.js](app/plugins/00.bootstrap-config.js) resolves the language *before* `/api/config` and every page fetch, because a cold visit has no `lang` cookie: without it the API calls go out as `en` while the layout takes `dir`/`lang` from the backend default, so an Arabic-first project renders RTL with English copy.

Order on a first visit: `GET /api/languages` (sent with `Accept-Language: en` — the API rejects a request without the header, and the list is the same either way) → pick the visitor's browser language when the project has it, else `is_default`, else the first → write the `lang` + `i18n_locale` cookies → everything else uses that code.

Two subtleties worth keeping:
- Nuxt's `useCookie` re-parses the **incoming request header** on every call, so a cookie written in the plugin is invisible to composables that read it later in the same SSR pass. The plugin writes the value back onto `event.node.req.headers.cookie` so the rest of the render sees it.
- The response is primed into `nuxtApp.payload.data.languages`, so `useLang()`'s own `useApiFetch('/api/languages', { key: 'languages' })` reuses it instead of fetching the list twice per render.

### `t(key, defaults?, params?)`

Signature variants supported (parser detects shape):
```js
t('key')                                     // raw key
t('key', 'English')                          // en only
t('key', 'English', 'العربية')               // en + ar (positional)
t('key', 'English', 'العربية', { n: 1 })     // en + ar + params
t('key', 'English', { n: 1 })                // en + params
t('key', { en, ar, fr, ... })                // multi-locale map
t('key', { en, ar, fr, ... }, { n: 1 })      // map + params
```

Lookup order:
1. backend value (if non-empty string).
2. `defaults[code]` (if provided).
3. raw `key`.

Seeding (only fires when `ready && !has && Object.keys(defaults).length && import.meta.client`):
- Module-level `seededKeys` Set dedupes within session (avoids spam).
- **Remote mode**: one `POST /api/translations` per locale present in `defaults`, each with `Accept-Language: <locale>` and `body: { translations: { [key]: value }, group }`. After all resolve, calls `refreshTranslations()`.
- **Local mode**: single `POST /api/dev-translations` with `{ key, defaults }`. Server endpoint ([server/api/dev-translations.post.js](server/api/dev-translations.post.js)) writes each `{key:value}` into `i18n/locales/<locale>.json`. Per-file mutex prevents race conditions when many keys seed simultaneously. Values containing `@` or `|` are escaped to vue-i18n literal-interpolation form (e.g. `m@example.com` → `m{'@'}example.com`) to avoid the AOT compiler's linked-message parser tripping.
- After write, calls `i18n.mergeLocaleMessage()` for live UI update without page reload.

For 3+ locales **always use map form** — positional only handles en/ar.

### Adding a new locale

**Remote mode** (zero frontend changes for backend-only):
1. Backend exposes new language in `/api/languages` and `/api/translations`.
2. `LanguageSwitcher` picks it up automatically.

**Local mode** (more involved):
1. Backend `/api/languages` — same.
2. Add to `i18n.locales` array in [nuxt.config.ts](nuxt.config.ts).
3. Create `i18n/locales/<code>.json` (empty `{}`).
4. Use map form: `t('key', { en, ar, <new>: '...' })`. Seed will populate the new file.

## Auth-driven forms (`useAuthConfig`)

[app/composables/useAuthConfig.js](app/composables/useAuthConfig.js) wraps `/api/config`. Pages read shape and render conditional fields:
- `identifiers`: array of accepted login identifier kinds (`'email'`, `'phone'`).
- `isMultiIdentifier`: `identifiers.length > 1`. Shows kind picker on register.
- `hasUsername`/`hasEmail`/`hasPhone`: extra fields beyond identifier.
- `isExtraRequired(kind)`: extras are required only when in `identifiers`. Otherwise rendered as `(optional)` and omitted from request body if blank.
- `labelFor`/`placeholderFor`/`inputTypeFor`: kind-specific i18n-aware values (use `t()` internally with en + ar defaults).
- `identifierLabel`/`identifierInputType`/`identifierPlaceholder`: composite label/type for the login/forgot identifier input. Joins multiple kinds with translated `or`.
- `socialAuthAvailable`: gates social-accounts card.
- `allowedEmailDomains` / `allowedPhoneCountries`: `"all"` or an array (see `/api/config` above). Use to constrain the email/phone inputs — restrict the country picker, and reject out-of-list email domains before hitting the API (the backend enforces the same list, so this is UX only, not a security boundary).

`/api/social-accounts` returns `{ social_accounts, allowed_providers, max_accounts, can_link_more }`. Profile uses these for the link-account UI. `max_accounts === 0` means unlimited (notice "limit reached" only shown when `!canLinkMore && maxAccounts > 0`).

## Layout / floating UI

- [app/app.vue](app/app.vue): wraps `NuxtLayout` in `<ConfigProvider :dir>` from reka-ui. Direction propagates to all popovers/selects/dialogs.
- [app/layouts/default.vue](app/layouts/default.vue): sets `<Html :lang="code" :dir="dir">` from `useLang`. Nuxt-i18n's `useLocaleHead()` is **not** used (we replaced its output with our cookie-driven values).
- [app/components/LanguageSwitcher.vue](app/components/LanguageSwitcher.vue): `Select` (shadcn) styled for a dark ground, with no positioning of its own. Mounted inside [app/components/AppBottomNav.vue](app/components/AppBottomNav.vue) — the floating bottom bar, which the default layout renders on every page.

## Modals

Pattern is custom (not shadcn `Dialog`). Inline `<Teleport to="body">` + overlay div + panel. Examples:
- Login restore-account confirmation ([app/pages/login.vue](app/pages/login.vue)).
- Profile delete-account confirmation ([app/pages/profile.vue](app/pages/profile.vue)).

Reason: lightweight, no extra deps, easy to style.

## Fetching conventions

- **GET** → `useSanctumFetch` (Nuxt-style declarative fetch with SSR + dedupe by `key`). Refresh via returned `refresh()`.
- **POST/PUT/DELETE** → `useSanctumClient()` (`$fetch` wrapper from sanctum module).
- Both pick up `Accept-Language` + `X-API-TOKEN` from the listener plugin unless caller sets `Accept-Language` explicitly (e.g. seed POSTs that force `en` regardless of UI locale).

## Auth middleware

- `sanctum:auth` (module-provided) — requires authenticated user.
- `sanctum:guest` — requires no session (login/register/forgot pages).
- `verified` ([app/middleware/verified.js](app/middleware/verified.js)) — requires email verification.
- `unverified` ([app/middleware/unverified.js](app/middleware/unverified.js)) — for `/verify` page.

### No-auth-system mode (both `app_users` and `app_guests` off)

The backend now allows disabling **both** `app_users` and `app_guests` — a pure public content app with no user concept. The client adapts via `useAuthConfig` (`appUsers`/`appGuests`, both `false` here):
- `require-user` lets routes through (no user required) instead of bouncing to `/login`.
- `require-pre-auth` redirects auth pages (login/register/verify/forgot) to `/` since they have nothing to render.
- `useApi`/`useApiFetch` already fall back to `$publicApi` (no Bearer) when `appUsers` is off.
- `index.vue` hides the auth/guest buttons + the `GET /api/user` probe card via `hasAuthSystem = appUsers || appGuests`.

When adding auth-gated pages/UI, gate on `appUsers`/`appGuests` (or `hasAuthSystem`) so the no-auth-system build stays coherent.

## Provisioning a fresh backend

Point `NUXT_API_BASE_URL` at an empty install and the site fills it in as pages are
loaded — no fixtures, no manual uploads.

**Translations** seed themselves: `t('key', 'English', 'العربية')` posts the key to
`/api/translations` once per locale the first time it renders missing. Every string on the
site carries its defaults, so browsing the pages creates the whole `web` group.

**Dynamic storage** seeds the same way, but only where the call names a `/public` file to
upload — `mediaAsset(key, defaultPath)`. Every call site does; the seeds live in
[public/seed/](public/seed/) and [public/](public/):

| Key | Seed file |
|---|---|
| `web/branding/logo`, `logo_light`, `logo_mark` | `/logo.png`, `/logo-light.png`, `/logo-mark.png` |
| `web/heroes/hero_shop`, `hero_gallery`, `hero_workshops` | `/seed/hero-*.webp`, passed as `PageHero`'s `fallback` |
| `web/studio/studio_1…4` | `/seed/studio-N.webp` |
| `web/home/hero_video` | `/seed/hero-video.mp4` |
| `web/app/app_screen_1`, `app_screen_2` | `/app-screen-N.png` |

Adding a key means adding its seed file, or it can never provision itself — a
`mediaAsset(key)` with no default renders nothing on a backend that has never seen it.

**Both seeders are client-side and write-gated.** They fire from the browser, so a page
has to actually be visited, and they post to endpoints the backend only exposes when
`IS_TESTING=true`. A production install with writes closed will not provision itself:
either open them for the first pass, or seed against dev and copy the rows over.

**Watch the locale on a fronted host.** Seeds post with a forced `Accept-Language`, and a
CDN that rewrites that header (Hostinger does) files them under the wrong locale. Seed
from local against the target API rather than through the deployed site.

## Env vars

`.env` is gitignored. Required (or defaults exist in `runtimeConfig.public`):
- `NUXT_PUBLIC_X_API_TOKEN` — Laravel API token.
- `NUXT_PUBLIC_BASE_URL` — Laravel base URL (default `http://localhost:8000`).
- `NUXT_PUBLIC_TRANSLATIONS_MODE` — `local` or `remote` (default `remote`).
- `NUXT_OG_IMAGE_SECRET` — for `@nuxtjs/seo` OG image generation.

## Coding conventions

- **No comments unless WHY is non-obvious**. Identifiers should explain WHAT.
- **No premature abstractions**. Three similar lines is fine.
- **No backwards-compat shims** when changing internal code. Just rewrite.
- **Trust framework guarantees** — only validate at system boundaries (user input, external APIs).
- **Edits over creates**. Don't write new files unless required.
- **No defensive nesting** for impossible cases.
- **Tests/dev-feature checks** at boundaries; not deep inside helpers.

## Common gotchas

- **`@` in JSON values** trips vue-i18n's AOT parser (linked-message syntax `@:key`). Server endpoint already escapes when writing; manual edits to `i18n/locales/*.json` need `m{'@'}example.com` form for literal `@`.
- **Stale auto-import hints** ("Could not find name `useFoo`") in IDE after creating a new composable → run `npx nuxt prepare` or wait for next dev start. Runtime works.
- **`useState` with `Set`/`Map`** dies on hydration (JSON serializes as `{}`). Use module-level scope for these.
- **Sanctum plugin only sets `Accept-Language` when caller didn't supply one** — lets seed POSTs force a specific locale.
- **`max_accounts: 0`** means unlimited; check `!canLinkMore && maxAccounts > 0` before showing limit notice.
- **Cookie `lang` stores object**, `i18n_locale` stores string code. Don't mix them.
