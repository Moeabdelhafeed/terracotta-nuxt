# CLAUDE.md — core/utils/device

Twenty-six static classes over the platform channels: battery, torch,
biometrics, NFC, sensors, connectivity, permissions, clipboard,
brightness, storage, the launcher.

```
device/
  device_policy.dart     — DeviceDefaults · DevicePolicy · ResolvedDevicePolicy
  device_services.dart   — the app-wide layer, DeviceCapability, deviceWarn/deviceGuard
  device_constants.dart  — what is left: the AR version floors
  _ttl_cache.dart        — TtlCache
  hardware/ info/ network/ system/
```

## The bag has no ThemeExtension, and cannot

Every other gold module reads its middle layer out of a
`ThemeExtension`. None of this can: a device service is called from
`bootstrap()` before there is a tree, from a cubit, from a background
task. There is no `BuildContext` and no `Theme` at most of these call
sites.

So the layer is a value set once — `DeviceServices.configure(policy)`
in `bootstrap()` — and the resolve is `DeviceServices.policy`, a
getter, rather than `style.resolve(context)`. Everything else is the
usual shape: all-nullable `DevicePolicy`, floor in `DeviceDefaults`,
`mergedWith` / `copyWith` / `==` / `hashCode`, `ResolvedDevicePolicy`
with every question answered, presets (`live`, `frugal`).

**What the bag carries is POLICY, not paint** — nothing here draws.
How long a reading is trusted, whether a dead capability keeps being
asked, who the latency probe may talk to, which URL schemes may be
launched. Those were loose top-level `const`s and, worse, three public
MUTABLE statics on `NetworkQualityUtils`: a setting an app changes by
assigning to another class's field at an unspecified point in its
life, with no way to read back what it was.

`configure()` REPLACES rather than merges, and clears every capability
latch — otherwise a policy change lands on a service that has already
stopped asking.

## Failures went to `print`

All 55 of them were `debugPrint`. The bootstrap zone reroutes `print`
into `Logger.m.i`, so every failure in this layer arrived untagged, at
INFO, formatted exactly like a status update:

```
[APP] ┃ INFO   BatteryUtils: getLevel failed (battery API unavailable): PlatformException(UNAVAILABLE, …)
[APP] ┃ INFO   TorchUtils: isAvailable failed: [EnableTorchException: … make sure that you are doing this on a real device.]
```

Two lines, on a simulator, from merely OPENING a page that asked. They
are the module's two failure modes in one screenshot:

- **An absent capability is not a failure.** A simulator has no
  battery API and no torch; it never will. `DeviceCapability` probes
  once, remembers, and logs one line at DEBUG (`logUnavailable`,
  `kDebugMode` by default). Battery already latched — torch re-asked
  the platform on every call, which is why it printed on every visit.
- **A failed ACTION is a warning.** Turning the torch on and having it
  throw means the caller asked for something the device claimed it
  could do. `deviceWarn` / `deviceGuard` → `Logger.m.w('[Device] …')`,
  with the app's `[Tag]` convention.

`TorchUtils` also latches on a `false` ANSWER, not just a throw: a
device without a flashlight does not grow one. NFC deliberately does
NOT — it is a radio the reader can switch off and on in settings while
the app is open.

## Bugs found on the way

- **`biometricOnly` did nothing.** The call read
  `biometricOnly: sticky` — the wrong variable — and the caller's own
  `biometricOnly` was dropped. A screen demanding biometrics (a
  wallet, a vault, anywhere a shoulder-surfed PIN is the threat) got a
  prompt that accepted that PIN; `sticky: true` imposed the
  restriction on callers who wanted something else. Two parameters,
  each doing the other's job badly.
- **A failed probe was CACHED as an answer.** `ConnectivityUtils` had
  its `catch` inside the fetch, so the `[none]` fallback was written
  to the cache like a real reading — one flaky platform call and the
  app believed it was offline for thirty seconds, with nothing to
  distinguish that from the truth. `TtlCache` now never stores a
  throw, and the guard sits outside it.
- **`showStatusBar()` left the app out of edge-to-edge.** It restored
  `SystemUiMode.manual` with all overlays instead of `edgeToEdge`. The
  entire side-inset system — every `SafeArea`, `DeviceNotch`'s
  rewrite, `GlobalContainer.shell` — assumes the app draws under the
  bars, so hiding the status bar once and showing it again quietly
  turned all of it off for the rest of the session.
- **`setStatusBarColor` wiped the icon brightness.**
  `setSystemUIOverlayStyle` replaces the WHOLE style, and this built
  one out of a single colour. It is `setOverlayStyle` (take the whole
  thing) and `setStatusBarIconsDark` (the part that still lands under
  edge-to-edge on Android 15+).
- **Storage answered `0.0` when it could not read.** Zero free
  megabytes is a full disk — a real state an app reacts to. Every
  reading is nullable now.
- **`AppLifecycleUtils.current` was a public mutable static**, and
  `dispose()`'s doc promised to close a broadcast stream that `init()`
  is documented to reopen. Read-only getter; the doc says what it does.
- **Concurrent readers each made their own platform call.** Bootstrap
  and the first page both wanting the device id are microseconds
  apart. `TtlCache` shares one in-flight future, guarded by a
  generation counter so an `invalidate()` mid-flight discards what
  lands.
- **`DateTime.now()`** is gone from the cache — see the loading
  module's note; the same reason, the same fix, `package:clock`.

## The launcher gates schemes

`launchUrl` hands the platform whatever it is given, and not every
string reaching `LauncherUtils` was typed by a developer — a URL out
of remote config, a deep link, a field in an API response.
`DevicePolicy.urlSchemes` is an allow-list (`http`, `https`, `mailto`,
`tel`, `sms`, `geo`, `maps`) because the failure is asymmetric: a
missing scheme is a link that does not open, an unwanted one is
`javascript:` executing or `file:` reading off the device. A refusal
logs a warning naming the scheme — a blocked launch is either an
attack or a policy that needs widening, and silence is the worst of
the three outcomes.

## Localized, and typed

- `NetworkQuality.label` returned `'Excellent'` — display copy, in one
  language, from `core/utils/`. It and the new `ConnectionType` route
  through `ConnectivityStrings`.
- `getConnectionType()` returned `'wifi'`; `getThermalState()`
  returned `'low'` / `'normal'`; `getOrientationFromSensor()` returned
  `'portrait'`. A caller comparing against a misspelled literal
  compiles and is simply always wrong. They are `ConnectionType`,
  `DeviceResourceState` and the framework's `Orientation`.
- `getThermalState` is `getResourceState`, named for what it reads: it
  has never measured temperature — Android's `isLowRamDevice` is a
  fact about the hardware, and iOS was hard-coded to `'normal'`.

## Deleted

- **`DndUtils`** — a stub whose every method returned `false`, with a
  comment saying to replace it when the feature was needed. It was
  never needed; the showcase drew a card that could not do anything.
  The template's rule is to delete dead code, not shim it.
- **`kNotchDetectionThreshold`, `kDefaultPixelRatio`,
  `kHighDensityPixelRatio`** — nothing read them. The notch is
  answered by `DeviceNotch` and the real insets; asset density is
  resolved by Flutter from the `2.0x/` folders.

## Guards

`test/device/device_adoption_test.dart` is a source guard, because
this layer is 27 files of the same shape and the next one added is
where it rots: no `debugPrint`, no `DateTime.now()`, no mutable public
static, every `TtlCache` reading its lifetime from the policy, no
`launchUrl` path without a scheme check, no English label on an enum,
`biometricOnly` wired to its own name, and nothing restoring
`SystemUiMode.manual`. It asserts positively too — the seams it
demands must exist, or deleting the code would satisfy it.

`test/device/device_policy_test.dart` covers the bag and the cache.
Neither needs a plugin: the platform channels answer nothing under
`flutter_test`, which is why the services themselves are guarded at
the source rather than driven.
