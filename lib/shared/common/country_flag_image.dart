import 'package:flutter/material.dart';

import '../../data/models/common/country_code/country_code.dart';
import '../module/image/index.dart';

/// Country flag as an IMAGE (flagcdn.com — the open Flagpedia CDN, keyed by
/// ISO 3166-1 alpha-2 code). Emoji flags don't render on several newer iOS
/// models, so images are the reliable path; the emoji ([CountryCode.flag])
/// stays as the offline/error fallback.
///
/// Cached after first load (rides `GlobalImage`'s cached-network pipeline).
/// Never mirrored in RTL — flags have a canonical orientation.
class CountryFlagImage extends StatelessWidget {
  const CountryFlagImage({
    super.key,
    required this.country,
    this.width = 24,
  });

  final CountryCode country;
  final double width;

  @override
  Widget build(BuildContext context) {
    final iso = country.code.toLowerCase();
    final fallback = Text(country.flag ?? '');
    if (iso.isEmpty) return fallback;
    return GlobalImage.n(
      // w40 = 40px-wide PNG, correct aspect per flag. Free, no key.
      'https://flagcdn.com/w40/$iso.png',
      width: width,
      height: width * 0.75,
      mirrorInRtl: false,
      errorWidget: fallback,
      style: ImageStyle(
        fit: BoxFit.contain,
        backgroundColor: Colors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
