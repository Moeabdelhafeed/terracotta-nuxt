# CLAUDE.md — lib/core/splash

Reusable contract for the splash gate. The screen itself lives in `lib/features/splash/views/splash_page.dart` — adopters reshape it; this directory is the stable API.

Wiring examples: [`docs/examples/splash_wiring.md`](../../../docs/examples/splash_wiring.md).

## Native handoff

iOS `LaunchScreen.storyboard` + Android `@color/launch_background` are **solid color only** — no logo, no image. The Dart splash owns the brand experience. All three layers (iOS bg + Android color + `SplashOptions.backgroundColor`) must agree on one hex for a flash-free handoff.

## Contract

### `SplashHero` — sealed union

Six variants. Each carries its own readiness signal:

- `.staticContent({child, display})` — caller widget, completes after `display`.
- `.icon({icon, color, size, display})` — cheapest variant, no asset load.
- `.image({ref, display, width, height, fit})` — `AssetRef`-based; pre-decoded via `SplashWarmer.precacheSplashImage`.
- `.lottie({asset, loop, repeatCount, ...})` — completes on controller `AnimationStatus.completed`; for loops, after `repeatCount` cycles.
- `.video({source, loop, minLoops, muted, fit, poster, posterMinDisplay})` — completes on end-of-stream; for loops, after `minLoops` full plays.
- `.builder({builder, readiness})` — escape hatch; caller supplies the readiness future.

### `SplashVideoSource` — sealed

- `.asset(path)` — bundled in `pubspec.yaml`.
- `.file(path)` — local file (e.g. pre-downloaded cache).
- `.network(url)` — remote. Pre-cache on first launch then pass `.file` for subsequent loads.

### `SplashOptions`

- `backgroundColor` — must match native layers
- `minDuration` — floor (default 800ms)
- `maxDuration` — hard ceiling (default 8s)
- `extraDelay` — post-hero pause
- `tapToSkip`, `waitForBootstrap`, `respectReduceMotion`
- `footerBuilder(progress)` — optional progress bar / skip hint
- `onAnalyticsEvent(name, params)` — emits `splash_mounted` / `splash_hero_ready` / `splash_navigated` / `splash_skipped` / `splash_max_duration_exceeded`
- `nextDecider` — `SplashNextDecider`, decides destination + push mode

All knobs `copyWith`-able.

### `SplashDestination` + `SplashPushMode`

Decider returns `(location, extra, mode)`. Modes:

- `go` — clear stack and replace (most common; back button doesn't return to splash)
- `replace` — swap current entry
- `push` — stack on top (rare; back button returns to splash)

### `defaultSplashNext`

Ships with the template. Replicates the prior hardcoded logic: onboarding redirect → auth check → home / login. Adopters pass their own `SplashNextDecider` for app-specific gating (paywall, kids-mode pin, etc).

### `SplashRedirect.devOverride`

`ValueNotifier<SplashDevOverride>` — `auto` / `forceHold` / `forceSkip`. Debug/profile only; release always reads `auto`. Surfaced as `DevTool.splash` in the dev overlay.

## Pre-warm — `SplashWarmer` singleton

For video heroes, **call `await SplashWarmer.instance.warmupVideo(hero)` mid-`bootstrap()`** before `runApp`. The warmer opens a `media_kit` `Player` in the background, primes the codec + buffer, and awaits the first non-zero `state.duration` emission (6s timeout). `SplashPage.build()` then calls `takePlayer()` to attach a `Video` widget to the already-buffered instance — frame 0 paints immediately, no codec-spinup stutter.

`SplashWarmer.instance.signalBootstrapDone()` is called from `bootstrap.dart` right before `runApp`. When `SplashOptions.waitForBootstrap` is true (default), the orchestrator awaits this so deferred async work (RC fetch, language preload, auth refresh) overlaps the splash hold.

## Orchestrator — `lib/features/splash/views/splash_page.dart`

Three races in parallel: hero readiness, `minDuration` floor, `bootstrapDone` (if waiting). `Future.wait` of all three, capped by `maxDuration`. After settle: `extraDelay`, then `nextDecider`, then dispatch via the chosen push mode.

Reduce-motion downgrades video → poster + `minDuration`. Tap-to-skip respects bootstrap gates so an early skip doesn't crash mid-init.

## Codec guardrails (video heroes)

- **H.264** only — broad codec support, fast init. Not HEVC / AV1.
- **720p max, 30fps**, low bitrate. 1080p splashes stutter on low-end Android.
- **`muted: true`** — skip audio decoder spin-up.
- **`SplashVideoSource.network` should be pre-cached.** Download once via `DownloadService`, persist to app docs, pass `SplashVideoSource.file` thereafter.

## Cold-start force

The router's `redirect` callback in `core/navigation/go_router_config.dart` has a one-shot `_firstRedirectSeen` flag that intercepts the first call each session and bounces to `splash.path`. Without it, GoRouter's `restorationScopeId` would restore the last route from the prior session — onboarding / home would mount before splash, the gate would never run. Trade-off: cold-start deep links bounce through splash for one frame; extend the guard with a whitelist if you ship deep-link-direct flows.
