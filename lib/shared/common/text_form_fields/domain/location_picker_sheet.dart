import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/location_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/buttons/global_filled_button.dart';
import '../../../module/map/global_osm_map.dart';
import '../../../module/sheet/global_sheet.dart';

/// A draggable map with a fixed centre pin — the map moves under the pin,
/// so wherever the pin sits when the user confirms is the picked point.
/// Returned via [GlobalBottomSheet]; null on dismiss.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key, this.initial});

  final LatLng? initial;

  /// Open the picker as a bottom sheet. Returns the chosen [LatLng] or
  /// null if dismissed.
  static Future<LatLng?> show(BuildContext context, {LatLng? initial}) {
    return GlobalBottomSheet.show<LatLng>(
      context: context,
      title: LocationFieldStrings.label,
      icon: Icons.map_outlined,
      isScrollControlled: true,
      content: LocationPickerSheet(initial: initial),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  /// Amman as a neutral default when no seed is given.
  static const _fallback = LatLng(31.9539, 35.9106);

  late LatLng _center = widget.initial ?? _fallback;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 320,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.md),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // OPENSTREETMAP, not Google: this picker needs a map
                // to pan and nothing else — no routing, no Places —
                // and a Google map needs a billed key per platform
                // that this build does not have, so it drew nothing at
                // all. See [GlobalOsmMap].
                //
                // Reads the pin position from the CAMERA — there is no
                // marker to drag, the whole map pans under a fixed
                // centre pin.
                GlobalOsmMap(
                  latitude: _center.latitude,
                  longitude: _center.longitude,
                  onMoved: (lat, lng) => _center = LatLng(lat, lng),
                ),
                // Fixed centre pin — offset up by half its height so the
                // tip points at the map centre.
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: context.statusColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.spacing.md),
        GlobalFilledButton(
          text: LocationFieldStrings.confirm,
          icon: Icons.check,
          onPressed: () => Navigator.of(context).pop(_center),
        ),
      ],
    );
  }
}
