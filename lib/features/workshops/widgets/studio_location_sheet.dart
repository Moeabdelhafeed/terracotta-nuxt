import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/device/system/launcher_utils.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/map/global_osm_map.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../booking/widgets/sheet_shell.dart';

/// «موقع الاستوديو» — where the workshop happens, and the way there.
///
/// ## Why a sheet and not a link
///
/// The location button did nothing at all: `onLocation` fell back to
/// `() {}` on both the workshops accordion and the booking's own page.
/// Handing the reader straight to Maps would work, but it leaves the
/// app on a tap that might have been a mistake — and on a workshop
/// with no published location there is nothing to hand them to. The
/// sheet shows what is known first, and the trip out is a decision.
///
/// ## The map
///
/// OpenStreetMap tiles, which need no key — see [GlobalOsmMap]. It
/// draws whenever the published link carries a POINT; a link that
/// names a place by name has no coordinates to read, and
/// [StudioMapPanel] falls back to a panel that says so rather than an
/// empty grey box that reads as a map which failed to load.
class StudioLocationSheet extends StatelessWidget {
  const StudioLocationSheet({required this.locationUrl, this.tint, super.key});

  /// The studio's `location_url`, as the workshop published it.
  ///
  /// **Null on every workshop the live CMS has today**, which is why
  /// the empty state is the one that had to be right first.
  final String? locationUrl;

  final Color? tint;

  /// Directions TO the studio, rather than a pin on it.
  ///
  /// `dir/?api=1&destination=` opens the route from wherever the
  /// reader is — which is the thing someone tapping a location button
  /// on the morning of a workshop actually wants. A published URL that
  /// is already a Maps link is handed over untouched: the studio may
  /// have shared a place ID, and rewriting it would lose the pin.
  /// The pin's coordinates, dug out of whatever the CMS published.
  ///
  /// The studio publishes a MAPS LINK, not a latitude and a longitude —
  /// so the only way to draw the place is to read the numbers back out
  /// of the URL. Three shapes cover what Google produces:
  /// `?q=lat,lng`, `@lat,lng,15z` in the path, and the `!3dlat!4dlng`
  /// pair in a place link.
  ///
  /// Null when the link names a PLACE rather than a point — a short
  /// `goo.gl` link, or a search by name. There is nothing to draw
  /// then, and the sheet says so rather than inventing a location.
  static ({double latitude, double longitude})? coordinatesIn(String? url) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return null;

    for (final pattern in _coordinatePatterns) {
      final match = pattern.firstMatch(raw);
      if (match == null) continue;
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat == null || lng == null) continue;
      // A pair outside the world is a pair read out of the wrong part
      // of the string.
      if (lat.abs() > 90 || lng.abs() > 180) continue;
      return (latitude: lat, longitude: lng);
    }
    return null;
  }

  static final _coordinatePatterns = <RegExp>[
    RegExp(r'[?&]q=(-?\d+\.\d+),\s*(-?\d+\.\d+)'),
    RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)'),
    RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)'),
  ];

  static String? directionsFor(String? url) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return null;
    // ALREADY A MAP LINK — handed over untouched.
    //
    // The host matters as much as the path: `maps.google.com/?q=…` is
    // what the CMS actually publishes, and it contains neither
    // `google.com/maps` nor `goo.gl/maps`. Checked for only those two,
    // a perfectly good map link was URL-ENCODED INTO A SEARCH TERM —
    // the button opened Maps looking for a place called
    // "https%3A%2F%2Fmaps.google.com…".
    if (raw.contains('google.com/maps') ||
        raw.contains('maps.google.') ||
        raw.contains('goo.gl/maps') ||
        raw.contains('maps.app.goo.gl') ||
        raw.contains('openstreetmap.org')) {
      return raw;
    }
    return 'https://www.google.com/maps/dir/?api=1&destination='
        '${Uri.encodeComponent(raw)}';
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final directions = directionsFor(locationUrl);

    return SheetShell(
      title: WorkshopStrings.studioLocation,
      // NO TINT — see the note in [PiecePhotosSheet]. The panel is the
      // plain surface like every other sheet; [tint] here colours the
      // pin and the button instead.

      // Sized to what it holds: a panel and a button do not need most
      // of the screen.
      heightFactor: null,
      maxHeightFactor: 0.7,
      children: [
        SizedBox(height: spacing.sm),
        StudioMapPanel(at: coordinatesIn(locationUrl)),
        SizedBox(height: spacing.md),
        if (directions == null)
          Text(
            WorkshopStrings.noLocation,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.secondary,
            ),
          )
        else
          GlobalFilledButton(
            text: WorkshopStrings.openInMaps,
            onPressed: () => unawaited(LauncherUtils.openUrl(directions)),
            style: terracottaCtaStyle(showArrow: false),
          ),
        SizedBox(height: spacing.md),
      ],
    );
  }
}

/// The map, when the published link carries a point to draw.
///
/// OPENSTREETMAP. A Google map needs a billed key per platform that
/// this build does not have, which is why this panel used to be a
/// drawn stand-in saying so — see [GlobalOsmMap].
///
/// Falls back to that stand-in when [at] is null: the CMS publishes a
/// maps LINK, and a link that names a place rather than a point has no
/// coordinates to read. An unexplained grey rectangle reads as a
/// failure, and that is not one.
class StudioMapPanel extends StatelessWidget {
  const StudioMapPanel({this.at, super.key});

  /// Where the studio is, when the link said so.
  final ({double latitude, double longitude})? at;

  static const double _height = 190;

  @override
  Widget build(BuildContext context) {
    final tint = context.primaryColors.primary;

    if (at case final point?) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.md),
        child: SizedBox(
          height: _height,
          child: GlobalOsmMap(
            latitude: point.latitude,
            longitude: point.longitude,
            // SHOWN, not explored. A drag here should scroll the sheet
            // it is in, not pan the world.
            interactive: false,
            markers: [
              (
                latitude: point.latitude,
                longitude: point.longitude,
                child: Icon(
                  Icons.place_rounded,
                  size: context.iconSizes.xl,
                  color: tint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.radii.md),
      child: SizedBox(
        height: _height,
        child: DecoratedBox(
          decoration: BoxDecoration(color: context.backgroundColors.container),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place_rounded,
                  size: context.iconSizes.xl,
                  color: tint,
                ),
                SizedBox(height: context.spacing.xs),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.lg,
                  ),
                  child: Text(
                    WorkshopStrings.mapPending,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [StudioLocationSheet] over whatever is on screen.
Future<void> showStudioLocationSheet(
  BuildContext context, {
  required String? locationUrl,
  Color? tint,
}) => showTerracottaSheet<void>(
  context,
  builder: (_) => StudioLocationSheet(locationUrl: locationUrl, tint: tint),
);
