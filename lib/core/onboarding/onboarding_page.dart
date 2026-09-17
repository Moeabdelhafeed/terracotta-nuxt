import 'package:flutter/material.dart';

/// Permission types primed by an onboarding page. The screen intercepts
/// the page's primary CTA and triggers the matching native dialog
/// before advancing.
///
/// Add new types as the app grows. Each maps to a runtime call inside
/// `OnboardingScreen._primePermission` — wire your `permission_handler`
/// (or platform-specific) call there.
enum OnboardingPermission { none, notifications, location, camera, contacts }

/// One page in the onboarding flow. Use the named constructors for
/// the common shapes — `.icon` (gradient + Material icon), `.lottie`
/// (Lottie asset hero), `.builder` (caller renders the entire body).
@immutable
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.body,
    this.icon,
    this.iconColor,
    this.lottieAsset,
    this.imageAsset,
    this.imageBleeds = false,
    this.heroBuilder,
    this.ctaLabel,
    this.permission = OnboardingPermission.none,
    this.background,
  });

  /// Hero with a gradient badge + centered Material icon. Default
  /// flavor — works without bundling Lottie assets.
  factory OnboardingPage.icon({
    required IconData icon,
    required String title,
    required String body,
    Color? iconColor,
    String? ctaLabel,
    OnboardingPermission permission = OnboardingPermission.none,
    Color? background,
  }) {
    return OnboardingPage(
      title: title,
      body: body,
      icon: icon,
      iconColor: iconColor,
      ctaLabel: ctaLabel,
      permission: permission,
      background: background,
    );
  }

  /// Hero rendered from a Lottie asset path. Caller is responsible
  /// for declaring the asset in `pubspec.yaml`.
  factory OnboardingPage.lottie({
    required String asset,
    required String title,
    required String body,
    String? ctaLabel,
    OnboardingPermission permission = OnboardingPermission.none,
    Color? background,
  }) {
    return OnboardingPage(
      title: title,
      body: body,
      lottieAsset: asset,
      ctaLabel: ctaLabel,
      permission: permission,
      background: background,
    );
  }

  /// Hero rendered from a bundled raster/vector asset.
  ///
  /// [bleed] reproduces artwork the design lets run past the frame
  /// edge — the drawing is laid out at its natural width and allowed
  /// to overflow horizontally rather than being shrunk to fit.
  factory OnboardingPage.image({
    required String asset,
    required String title,
    required String body,
    bool bleed = false,
    String? ctaLabel,
    OnboardingPermission permission = OnboardingPermission.none,
    Color? background,
  }) {
    return OnboardingPage(
      title: title,
      body: body,
      imageAsset: asset,
      imageBleeds: bleed,
      ctaLabel: ctaLabel,
      permission: permission,
      background: background,
    );
  }

  /// Total custom hero — caller decides what renders above the
  /// title/body block.
  factory OnboardingPage.builder({
    required WidgetBuilder hero,
    required String title,
    required String body,
    String? ctaLabel,
    OnboardingPermission permission = OnboardingPermission.none,
    Color? background,
  }) {
    return OnboardingPage(
      title: title,
      body: body,
      heroBuilder: hero,
      ctaLabel: ctaLabel,
      permission: permission,
      background: background,
    );
  }

  final String title;
  final String body;

  /// Used when [heroBuilder] / [lottieAsset] are null.
  final IconData? icon;
  final Color? iconColor;

  /// Optional Lottie asset path. Resolved via `lottie` package.
  final String? lottieAsset;

  /// Optional image asset path (PNG / SVG) for the hero.
  final String? imageAsset;

  /// Whether [imageAsset] is allowed to overflow the frame's width
  /// instead of being scaled down to fit it.
  final bool imageBleeds;

  /// Total override for the hero region.
  final WidgetBuilder? heroBuilder;

  /// Per-page primary CTA. Falls back to global "Next" / "Get Started"
  /// from [OnboardingStrings] when null.
  final String? ctaLabel;

  /// Native permission asked when the user taps the CTA. [none]
  /// advances normally.
  final OnboardingPermission permission;

  /// Override the page background. Null = inherits theme.
  final Color? background;

  /// Builds an [OnboardingPage] from a Remote Config JSON map.
  /// Unknown icon names fall back to [Icons.star_rounded].
  factory OnboardingPage.fromJson(Map<String, dynamic> json) {
    final iconName = (json['icon'] as String?) ?? '';
    return OnboardingPage(
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      icon: _iconFromName(iconName),
      ctaLabel: json['ctaLabel'] as String?,
      lottieAsset: json['lottieAsset'] as String?,
      imageAsset: json['imageAsset'] as String?,
      imageBleeds: (json['imageBleeds'] as bool?) ?? false,
      permission: _permissionFromString(json['permission'] as String?),
    );
  }
}

OnboardingPermission _permissionFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'notifications':
      return OnboardingPermission.notifications;
    case 'location':
      return OnboardingPermission.location;
    case 'camera':
      return OnboardingPermission.camera;
    case 'contacts':
      return OnboardingPermission.contacts;
    default:
      return OnboardingPermission.none;
  }
}

/// Tiny lookup table — extend as needed. Avoids pulling in a full
/// icon name → IconData reflection (which Flutter doesn't ship).
IconData _iconFromName(String name) {
  switch (name) {
    case 'rocket_launch_rounded':
      return Icons.rocket_launch_rounded;
    case 'shield_outlined':
      return Icons.shield_outlined;
    case 'notifications_active_outlined':
      return Icons.notifications_active_outlined;
    case 'location_on_outlined':
      return Icons.location_on_outlined;
    case 'celebration_rounded':
      return Icons.celebration_rounded;
    case 'auto_awesome_outlined':
      return Icons.auto_awesome_outlined;
    case 'wallet_outlined':
      return Icons.wallet_outlined;
    case 'flash_on_rounded':
      return Icons.flash_on_rounded;
    default:
      return Icons.star_rounded;
  }
}
