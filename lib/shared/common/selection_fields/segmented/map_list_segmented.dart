import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/segmented_control/global_segmented_control.dart';

/// How a location screen renders its results.
enum MapListMode { list, map }

/// The list/map toggle — store finders, delivery tracking, listings.
/// Localized labels + icons baked in.
class MapListSegmented extends StatelessWidget {
  const MapListSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.variant = SegmentedVariant.filled,
    this.style = const SegmentedStyle(),
    this.enabled = true,
  });

  final MapListMode value;
  final ValueChanged<MapListMode>? onChanged;
  final SegmentedVariant variant;
  final SegmentedStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalSegmentedControl<MapListMode>(
      segments: [
        SegmentItem(
          value: MapListMode.list,
          label: SegmentedControlStrings.viewList,
          icon: Icons.view_list_outlined,
        ),
        SegmentItem(
          value: MapListMode.map,
          label: SegmentedControlStrings.viewMap,
          icon: Icons.map_outlined,
        ),
      ],
      value: value,
      onChanged: onChanged,
      variant: variant,
      style: style,
      enabled: enabled,
    );
  }
}
