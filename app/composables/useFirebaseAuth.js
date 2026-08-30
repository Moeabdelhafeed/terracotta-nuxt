import { initializeApp, getApps, getApp } from 'firebase/app'
import {
  getAuth,
  GoogleAuthProvider,
  FacebookAuthProvider,
  TwitterAuthProvider,
  GithubAuthProvider,
  OAuthProvider,
  signInWithPopup,
} from 'firebase/auth'

let appInstance = null

const buildProvider = (providerId) => {
  switch (providerId) {
    case 'google.com': return new GoogleAuthProvider()
    case 'facebook.com': return new FacebookAuthProvider()
    case 'twitter.com': return new TwitterAuthProvider()
    case 'github.com': return new GithubAuthProvider()
    case 'apple.com': return new OAuthProvider('apple.com')
    case 'microsoft.com': return new OAuthProvider('microsoft.com')
    case 'yahoo.com': return new OAuthProvider('yahoo.com')
    default:
      throw new Error(`Unknown provider: ${providerId}`)
  }
}

export const useFirebaseAuth = () => {
  const config = useRuntimeConfig().public.firebase

  const ensureApp = () => {
    if (appInstance) return appInstance
    if (!config?.apiKey) throw new Error('Firebase config missing — set NUXT_PUBLIC_FIREBASE_* env vars')
    appInstance = getApps().length ? getApp() : initializeApp({
      apiKey: config.apiKey,
      authDomain: config.authDomain,
      projectId: config.projectId,
      appId: config.appId,
    })
    return appInstance
  }

  const signInWithProvider = async (providerId) => {
    const app = ensureApp()
    const auth = getAuth(app)
    const provider = buildProvider(providerId)
    const result = await signInWithPopup(auth, provider)
    const idToken = await result.user.getIdToken()
    return { idToken, user: result.user, providerId }
  }

  return { signInWithProvider }
}
