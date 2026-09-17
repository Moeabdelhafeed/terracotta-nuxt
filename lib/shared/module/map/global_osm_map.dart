import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

/// A map, drawn from OpenStreetMap tiles.
///
/// ## Why not Google
///
/// A Google map needs a billed API key per platform, and the two places
/// this app shows a map — picking an address pin, and showing the
/// studio — need neither routing nor Places. OpenStreetMap raster tiles
/// need no key at all, which is also why the studio sheet was showing a
/// drawn placeholder rather than a map: there was no key to give it.
///
/// ## The tile policy is a real obligation
///
/// `tile.openstreetmap.org` runs on donated hardware and its usage
/// policy requires an identifying `User-Agent` — an app sending the
/// default Dart one is indistinguishable from a scraper and gets
/// blocked. [userAgentPackageName] is that identification; it is not
/// decoration. Heavy or commercial use is meant to move to a paid tile
/// host, and swapping [urlTemplate] is all that takes.
///
/// ## Coordinates
///
/// Plain doubles in and out. The app carries positions as
/// `google_maps_flutter`'s `LatLng` because that is what every model,
/// converter and form already speaks, and `flutter_map` has a `LatLng`
/// of its own — importing both into one file is a name clash for no
/// reason, so the conversion happens here and nowhere else.
class GlobalOsmMap extends StatelessWidget {
  const GlobalOsmMap({
    required this.latitude,
    required this.longitude,
    this.zoom = 15,
    this.interactive = true,
    this.onMoved,
    this.markers = const [],
    super.key,
  });

  final double latitude;
  final double longitude;
  final double zoom;

  /// Whether the reader can pan and pinch. False for a map that is
  /// only being SHOWN — the studio's address — so a stray drag inside
  /// a sheet does not pan the world instead of scrolling the sheet.
  final bool interactive;

  /// Fired with the centre after every gesture, for a picker.
  final void Function(double latitude, double longitude)? onMoved;

  /// Pins. Empty for a picker, which draws its own fixed centre mark.
  final List<({double latitude, double longitude, Widget child})> markers;

  /// OSM's standard raster layer.
  static const urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Sent as the `User-Agent`. Required by the tile policy — see the
  /// class doc.
  static const userAgentPackageName = 'com.dottech.terracotta';

  @override
  Widget build(BuildContext context) => FlutterMap(
    options: MapOptions(
      initialCenter: ll.LatLng(latitude, longitude),
      initialZoom: zoom,
      interactionOptions: InteractionOptions(
        flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
      ),
      onPositionChanged: onMoved == null
          ? null
          : (camera, hasGesture) {
              if (!hasGesture) return;
              onMoved!(camera.center.latitude, camera.center.longitude);
            },
    ),
    children: [
      TileLayer(
        urlTemplate: urlTemplate,
        userAgentPackageName: userAgentPackageName,
      ),
      if (markers.isNotEmpty)
        MarkerLayer(
          markers: [
            for (final marker in markers)
              Marker(
                point: ll.LatLng(marker.latitude, marker.longitude),
                width: 44,
                height: 44,
                child: marker.child,
              ),
          ],
        ),
      const _Attribution(),
    ],
  );
}

/// «© OpenStreetMap». Required by the ODbL the tiles are licensed
/// under — a credit the app may not choose to leave off.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.bottomEnd,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Text(
            '© OpenStreetMap',
            style: TextStyle(fontSize: 9, color: Colors.black87),
          ),
        ),
      ),
    ),
  );
}
