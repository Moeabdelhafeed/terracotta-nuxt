# CLAUDE.md — lib/core/onboarding

Reusable contract for the onboarding gate. The screen itself lives in `lib/features/onboarding/views/onboarding_page.dart` — adopters reshape it; this directory is the stable API.

Wiring examples: [`docs/examples/onboarding_wiring.md`](../../../docs/examples/onboarding_wiring.md).

## Contract

### `OnboardingPage` — page model

Three factory shapes:

- `.icon({icon, title, body, iconColor, ctaLabel, permission, background})`
- `.lottie({asset, title, body, ctaLabel, permission, background})`
- `.builder({hero, title, body, ctaLabel, permission, background})` — caller renders the hero

### `OnboardingOptions`

Full style + behavior config:

- `indicator` — `dots` / `bar` / `numbered` / `custom` / `none`
- `autoAdvance` — `Duration?` between auto-page-flips (null = manual only)
- `transitionDuration` / `transitionCurve`
- `skipFlagsAsSeen` — when true, tapping "Skip" marks `seenOnboarding=true`
- `respectReduceMotion` — downgrades animations when `MediaQuery.disableAnimationsOf` is true
- `contentBuilder` / `bottomBarBuilder` / `heroBuilder` — escape hatches for total layout override
- `onPermissionRequest(OnboardingPermission)` — adopter wires native permission via `permission_handler`
- `onAnalyticsEvent(name, params)` — emits `step_seen` / `cta_tapped` / `permission_granted` / `permission_denied` / `skipped` / `finished`

### `OnboardingRedirect.shouldShow({arrivedViaDeepLink, compileTimeEnabledOverride})`

Precedence (highest first):

1. Dev override (`devOverride.value`)
2. Compile-time override (caller flag)
3. RC `onboarding_enabled` (operator kill-switch)
4. Deep-link arrival — marks seen + skips
5. Persisted `seenOnboarding` flag

### `OnboardingRedirect.devOverride`

`ValueNotifier<OnboardingDevOverride>` — `auto` / `forceShow` / `forceSkip`. Debug/profile only. Surfaced as `DevTool.onboardingReset` in the dev overlay.

### `OnboardingPermission`

`none` / `notifications` / `location` / `camera` / `contacts`. The screen intercepts the page's primary CTA and fires the matching permission via `OnboardingOptions.onPermissionRequest` before advancing. Adopter wires the native call (typically `permission_handler`).

### `defaultOnboardingPages()`

Three placeholder pages. Adopter replaces with branded pages.

## Feature page

Class `OnboardingFlowPage` in `lib/features/onboarding/views/onboarding_page.dart`. Owns scaffold, `PageView`, indicator, bottom bar, permission primer, auto-advance, skip handling, analytics emission.

Indicator delegates to `GlobalDotIndicator` (from `lib/shared/module/indicator/`) for `dots` kind, inline progress bar for `bar`, inline pill for `numbered`. No `OnboardingIndicator` module — the shared indicator covers all cases.

## Customization paths

- **Tweak existing layout**: pass a custom `OnboardingOptions` — covers ~80% of cases (indicator, bottom bar, hero builder).
- **Total rewrite**: edit `lib/features/onboarding/views/onboarding_page.dart` directly. Keep the `OnboardingPage` + `OnboardingOptions` + `OnboardingRedirect` contracts so navigation gating + first-launch state + permission flow stay wired.
