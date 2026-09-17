/// WHICH BUNDLED ASSETS THE STUDIO MAY REPLACE, and under what key.
///
/// One map, so adoption anywhere is a one-line swap —
/// `DynamicAssetImage.forAsset(path)` looks the path up here and draws
/// the plain bundled asset when it finds nothing. A drawing the studio
/// should NOT be able to change simply stays out of the map.
///
/// ## The keys are a contract with the CMS
///
/// `sub_group` and `key` are slugs (`^[a-z0-9]([a-z0-9_-]*[a-z0-9])?$`)
/// and they are what the studio sees in the CMS, so they are named for
/// the thing and not for the file: `onboarding/onboarding_1`, not
/// `onboarding/onboarding-1-png`. **Renaming one orphans whatever the
/// studio uploaded against the old name** — the app would fall back to
/// the bundle and seed the new key, and their artwork would still be
/// sitting in the CMS under a key nothing reads.
///
/// ## What is deliberately absent
///
/// The brand mark and the app's own chrome. Those are the app's
/// identity rather than the studio's decoration, and a CMS that can
/// replace the logo is a CMS that can break the app's face.
library;

/// A slot in the CMS's dynamic storage.
typedef DynamicSlot = ({String section, String key});

/// Bundled path → where it lives in the CMS.
const dynamicAssetSlots = <String, DynamicSlot>{
  // ── Onboarding ──────────────────────────────────────────────
  'assets/images/onboarding-1.png': (
    section: 'onboarding',
    key: 'onboarding_1',
  ),
  'assets/images/onboarding-2.png': (
    section: 'onboarding',
    key: 'onboarding_2',
  ),
  'assets/images/onboarding-3.png': (
    section: 'onboarding',
    key: 'onboarding_3',
  ),

  // ── The auth flow ───────────────────────────────────────────
  'assets/images/login-register-illustration.png': (
    section: 'auth',
    key: 'login_register',
  ),
  'assets/images/enter-otp-illustration.png': (section: 'auth', key: 'otp'),
  'assets/images/chnage-password-request-illustration.png': (
    section: 'auth',
    key: 'password_request',
  ),
  'assets/images/chnage-password-illustration.png': (
    section: 'auth',
    key: 'password_change',
  ),

  // ── The browse tabs' headers ────────────────────────────────
  'assets/images/gallery-illustration-1.png': (
    section: 'gallery',
    key: 'header_camera_line',
  ),
  'assets/images/gallery-illustration-2.png': (
    section: 'gallery',
    key: 'header_camera_heart',
  ),
};

/// The slot for [assetPath], or null when it is not the studio's to
/// change.
DynamicSlot? slotForAsset(String assetPath) => dynamicAssetSlots[assetPath];
