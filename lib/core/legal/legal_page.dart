import 'package:flutter/material.dart';

import '../localization/strings/legal_strings.dart';

/// Catalog of legal / about pages the app can surface.
///
/// Each entry has:
/// - [slug] — used in routes (`/legal/<slug>`), RC keys
///   (`legal_<slug>_*`), and bundled asset filenames
///   (`assets/legal/<slug>.md`).
/// - [title] — heading shown in the AppBar and the index list
///   (localized, resolved at read time).
/// - [icon] — leading icon in the index.
///
/// Pages are toggled on/off via Remote Config (`legal_<slug>_enabled`).
/// Disabled pages are hidden from the index and short-circuit to a
/// "not available" state if accessed by direct URL.
enum LegalPage {
  about(
    slug: 'about',
    icon: Icons.info_outline_rounded,
  ),
  privacy(
    slug: 'privacy',
    icon: Icons.shield_outlined,
  ),
  tos(
    slug: 'tos',
    icon: Icons.gavel_rounded,
  ),
  licenses(
    slug: 'licenses',
    icon: Icons.code_rounded,
  ),
  eula(
    slug: 'eula',
    icon: Icons.description_outlined,
  ),
  refund(
    slug: 'refund',
    icon: Icons.receipt_long_outlined,
  ),
  credits(
    slug: 'credits',
    icon: Icons.favorite_outline_rounded,
  ),
  contact(
    slug: 'contact',
    icon: Icons.support_agent_rounded,
  );

  const LegalPage({
    required this.slug,
    required this.icon,
  });

  final String slug;
  final IconData icon;

  /// Heading shown in the AppBar and the index list — localized via
  /// [LegalStrings], so it can't live on the const enum entries.
  String get title => switch (this) {
    LegalPage.about => LegalStrings.titleAbout,
    LegalPage.privacy => LegalStrings.titlePrivacy,
    LegalPage.tos => LegalStrings.titleTos,
    LegalPage.licenses => LegalStrings.titleLicenses,
    LegalPage.eula => LegalStrings.titleEula,
    LegalPage.refund => LegalStrings.titleRefund,
    LegalPage.credits => LegalStrings.titleCredits,
    LegalPage.contact => LegalStrings.titleContact,
  };

  /// Bundled asset path for the markdown fallback. The Open-source
  /// licenses page is rendered by Flutter's built-in `LicensePage`
  /// and has no markdown asset — the resolver short-circuits.
  String get bundledAssetPath => 'assets/legal/$slug.md';

  static LegalPage? fromSlug(String? slug) {
    if (slug == null) return null;
    for (final p in LegalPage.values) {
      if (p.slug == slug) return p;
    }
    return null;
  }
}
