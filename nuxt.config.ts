import tailwindcss from "@tailwindcss/vite"

// https://nuxt.com/docs/api/configuration/nuxt-config

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  runtimeConfig: {
    xApiToken: '',        // NUXT_X_API_TOKEN — private, server-only. Injected by server/api/[...].js proxy.
    apiBaseUrl: '',       // NUXT_API_BASE_URL — private. Real Laravel URL the proxy forwards to.
    public: {
      baseUrl: '',        // own origin (relative). Client fetches hit Nitro proxy, not Laravel directly.
      translationsMode: process.env.NUXT_PUBLIC_TRANSLATIONS_MODE, // 'remote' | 'local'
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
    baseUrl: process.env.NUXT_PUBLIC_SITE_URL || 'http://localhost:3000',
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
    name: process.env.NUXT_PUBLIC_SITE_NAME || 'Terracotta',
    url: process.env.NUXT_PUBLIC_SITE_URL || 'http://localhost:3000',
    defaultLocale: 'ar',
  },

  seo: {
    // The module's own defaults (canonical, og:url, title template fallbacks) are wanted;
    // app.vue sets the site-wide values and each page overrides what it knows better.
    automaticDefaults: true,
  },

  robots: {
    // Nothing behind a login, and nothing addressed to one person, belongs in an index.
    // A gift link in particular is an entitlement: it must never become findable.
    disallow: ['/login', '/register', '/verify', '/verify-login', '/forgot-password', '/profile', '/devices', '/gift/'],
  },

  sitemap: {
    exclude: ['/login', '/register', '/verify', '/verify-login', '/forgot-password/**', '/profile', '/devices', '/gift/**'],
    // Products, workshops, albums and CMS pages are only known at runtime — see
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