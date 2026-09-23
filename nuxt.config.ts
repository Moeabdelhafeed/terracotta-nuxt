import tailwindcss from "@tailwindcss/vite"

// The site's own identity. Read by @nuxtjs/seo and nuxt-i18n, which resolve at build time
// rather than through runtimeConfig, so they cannot be overridden by a deploy variable —
// change them here.
const SITE_URL = 'https://terracotta-ksa.com'
const SITE_NAME = 'Terracotta'

// https://nuxt.com/docs/api/configuration/nuxt-config

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  devServer: {
    host: '0.0.0.0',
    port: 3000
  },

  // Everything the project needs to boot lives here, not in a `.env` — Nuxt still lets a
  // deploy override any of it with the matching `NUXT_*` variable, so production points
  // itself at the real API without the file being edited. The ONE exception is the API
  // token below: this repository is public, so the secret stays in the environment.
  runtimeConfig: {
    xApiToken: 'af72083febcec6bb0332781b14e180cf70075d43313f05efd05568739c235d28',        // NUXT_X_API_TOKEN — secret. Never hardcode it; see .env.example.
    // The host only — NOT including `/api`. The proxy appends the whole incoming path,
    // which already starts with `/api`, so a trailing one here asks for `/api/api/...`.
    apiBaseUrl: 'https://dev-cms.terracotta-ksa.com', // NUXT_API_BASE_URL overrides this on a deploy.
    public: {
      baseUrl: '',        // own origin (relative). Client fetches hit Nitro proxy, not Laravel directly.
      translationsMode: 'remote', // 'remote' | 'local'
      // Baked in at build time. Passenger (Hostinger's Node host) runs several worker
      // processes and spawns them lazily, so several PIDs is normal — several *builds* is
      // not, and that is what /api/_build compares.
      buildId: process.env.NUXT_PUBLIC_BUILD_ID || String(Date.now()),
      firebase: {
        apiKey: '',
        authDomain: '',
        projectId: '',
        appId: '',
      },
    },
  },



  css: [
    "~/assets/css/main.css",
  ],
  sanctum: {
    baseUrl: '', // own origin → /api/* proxied to Laravel by server/api/[...].js
    mode: 'token',
    // app/plugins/00.bootstrap-config.js already loads /api/user (alongside
    // /api/config); leaving this on makes every render fetch the user twice.
    client: {
      initialRequest: false,
    },
    endpoints: {
      login: '/api/login',
      logout: '/api/logout',
      user: '/api/user',
    },
    redirect: {
      keepRequestedRoute: false,
      onLogin: '/',
      onLogout: '/',
      onAuthOnly: '/login',
      onGuestOnly: '/',
    },
  },

  vite: {
    optimizeDeps: {
      include: [
        '@vue/devtools-core',
        '@vue/devtools-kit',
        'class-variance-authority',
        'reka-ui',
        'clsx',
        'tailwind-merge',
      ]
    },
    plugins: [
      tailwindcss(),
    ]
  },

  i18n: {
    baseUrl: SITE_URL,
    // Arabic is the backend's default language (LanguageSeeder: ar is_default=true,
    // APP_LOCALE=ar) — the storefront is Arabic-first, English stays available.
    defaultLocale: 'ar',
    locales: [
      { code: 'ar', language: 'ar-SA', file: 'ar.json', name: 'العربية', dir: 'rtl' },
      { code: 'en', language: 'en-US', file: 'en.json', name: 'English', dir: 'ltr' }
    ],
    strategy: 'no_prefix',
    detectBrowserLanguage: {
      useCookie: true,
      cookieKey: 'i18n_locale',
      redirectOn: 'root', // recommended
      fallbackLocale: 'ar',
    },
    compilation: {
      strictMessage: false,
    },
  },

  shadcn: {
    /**
     * Prefix for all the imported component.
     * @default "Ui"
     */
    prefix: '',
    /**
     * Directory that the component lives in.
     * Will respect the Nuxt aliases.
     * @link https://nuxt.com/docs/api/nuxt-config#alias
     * @default "@/components/ui"
     */
    componentDir: '@/components/ui'
  },

  site: {
    name: SITE_NAME,
    url: SITE_URL,
    defaultLocale: 'ar',
  },

  seo: {
    // The module's own defaults (canonical, og:url, title template fallbacks) are wanted;
    // app.vue sets the site-wide values and each page overrides what it knows better.
    automaticDefaults: true,
  },

  // In token mode the Sanctum bearer lives in a cookie the client has to read, so it
  // cannot be httpOnly — one script execution would be an account takeover. These headers
  // are the second line: nothing may frame us (every destructive action is one click:
  // delete account, cancel an order, claim a gift), and a referrer never carries an
  // order or gift path off-site.
  routeRules: {
    '/**': {
      headers: {
        'X-Frame-Options': 'DENY',
        'Content-Security-Policy': "frame-ancestors 'none'",
        'X-Content-Type-Options': 'nosniff',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
      },
    },
    // Universal Links (iOS) / App Links (Android) for the gift share link. Apple's file
    // has no extension, so it would otherwise go out as octet-stream, which iOS ignores;
    // both verifiers also refuse a redirect, so nothing may rewrite this path.
    '/.well-known/**': {
      headers: { 'Content-Type': 'application/json' },
    },
  },

  robots: {
    // Nothing behind a login, and nothing addressed to one person, belongs in an index.
    // A gift link in particular is an entitlement: it must never become findable.
    disallow: [
      '/login', '/register', '/verify', '/verify-login', '/forgot-password', '/profile', '/devices', '/gift/',
      '/wallet', '/my-gallery', '/bookings', '/cart', '/checkout', '/orders', '/favorites', '/addresses',
      '/notifications', '/gifts', '/workshops/*/book',
    ],
  },

  sitemap: {
    exclude: [
      '/login', '/register', '/verify', '/verify-login', '/forgot-password/**', '/profile', '/devices', '/gift/**',
      '/wallet', '/my-gallery', '/bookings/**', '/cart', '/checkout', '/orders/**', '/favorites', '/addresses',
      '/notifications', '/gifts/**', '/workshops/*/book',
    ],
    // Products, materials, workshops, albums and CMS pages are only known at runtime — see
    // server/api/_sitemap-urls.get.js.
    sources: ['/api/_sitemap-urls'],
  },





  modules: [
    "@nuxtjs/i18n",
    'shadcn-nuxt',
    '@vueuse/nuxt',
    'nuxt-lucide-icons',
    'motion-v/nuxt',
    '@nuxtjs/seo',
    'v-gsap-nuxt',
    'nuxt-auth-sanctum',
  
  ],
})