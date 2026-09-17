// ---------------------------------------------------------------------------
// Platform capability floors
// ---------------------------------------------------------------------------
//
// What is left here is the handful of numbers that are FACTS about the
// platforms rather than policy: the OS versions that first shipped an
// AR runtime. Everything an app might reasonably want to change — the
// cache TTLs, the low-battery threshold, the latency bands, the
// brightness and volume fallbacks — moved to `DevicePolicy`, where it
// can be set once in `bootstrap()` and read back.
//
// Deleted outright: `kNotchDetectionThreshold`, `kDefaultPixelRatio`
// and `kHighDensityPixelRatio`. Nothing read them. The notch is
// answered properly by `DeviceNotch` and the safe-area insets, and
// asset density is resolved by Flutter itself from the `2.0x/` and
// `3.0x/` folders.

/// Minimum Android SDK level that supports ARCore.
const int kMinAndroidSdkForAR = 24;

/// Minimum iOS major version that supports ARKit.
const int kMinIOSVersionForAR = 13;
