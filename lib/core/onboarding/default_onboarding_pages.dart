import 'dart:convert';

import 'package:flutter/material.dart';

import 'onboarding_page.dart';

/// Built-in 4-page intro. Replace by passing a custom `pages` list to
/// `OnboardingScreen`, or by setting `onboarding_pages_json` in
/// Remote Config.
List<OnboardingPage> defaultOnboardingPages() => [
  OnboardingPage.icon(
    icon: Icons.rocket_launch_rounded,
    title: 'Welcome aboard',
    body:
        'Set up your space in a minute. Swipe to see what '
        'you can do here.',
  ),
  OnboardingPage.icon(
    icon: Icons.auto_awesome_outlined,
    iconColor: const Color(0xFFEAB308),
    title: 'Built for speed',
    body:
        'Themed components, responsive layouts, and offline-first '
        'data — straight out of the box.',
  ),
  OnboardingPage.icon(
    icon: Icons.notifications_active_outlined,
    iconColor: const Color(0xFF22C55E),
    title: 'Stay in the loop',
    body: 'Get a heads-up the moment something needs your attention.',
    ctaLabel: 'Allow notifications',
    permission: OnboardingPermission.notifications,
  ),
  OnboardingPage.icon(
    icon: Icons.celebration_rounded,
    iconColor: const Color(0xFF6453D8),
    title: 'You\'re all set',
    body: 'Tap Get started to dive in.',
  ),
];

/// Parses the optional Remote Config JSON array into a page list.
/// Returns null when the input is empty or invalid; caller falls back
/// to [defaultOnboardingPages].
List<OnboardingPage>? parseOnboardingPagesJson(String raw) {
  if (raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    final pages = decoded
        .whereType<Map<String, dynamic>>()
        .map(OnboardingPage.fromJson)
        .where((p) => p.title.isNotEmpty || p.body.isNotEmpty)
        .toList();
    return pages.isEmpty ? null : pages;
  } catch (_) {
    return null;
  }
}
