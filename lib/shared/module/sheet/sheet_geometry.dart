import 'package:flutter/material.dart';

import '../../../core/utils/device/info/screen_radius.dart';
import 'sheet_models.dart';

/// The corners a sheet and the things INSIDE it are drawn with.
///
/// A row sitting in a padded sheet has to round by less than the sheet
/// does, or the two curves fight: the module's own sheets shipped
/// 14-point rows inside a 24-point sheet with a 20-point inset, which
/// reads as a card that happens to be in a sheet rather than as part of
/// one. Concentric is the rule — inner = outer − inset — and it is
/// stated once, here, because three sheets in the picker family were
/// each guessing at it.
abstract final class SheetGeometry {
  /// Fallback when the device reports no screen corner.
  static const fallbackRadius = 24.0;

  /// The sheet's OWN corner: explicit > device radius > fallback.
  static BorderRadius outerRadius(
    ResolvedSheetStyle rs, {
    required bool floating,
    required bool isTop,
  }) {
    final explicit = rs.borderRadius;
    if (explicit != null) return explicit;
    if (floating) {
      if (rs.useDeviceRadius && DeviceRadius.hasRoundedCorners) {
        return DeviceRadius.uniformPadded;
      }
      return BorderRadius.circular(fallbackRadius);
    }
    if (rs.useDeviceRadius && DeviceRadius.hasRoundedCorners) {
      return DeviceRadius.borderRadiusPadded;
    }
    return isTop
        ? const BorderRadius.vertical(bottom: Radius.circular(fallbackRadius))
        : const BorderRadius.vertical(top: Radius.circular(fallbackRadius));
  }

  /// The corner a child inset by [inset] should use so its curve is
  /// CONCENTRIC with [outer].
  ///
  /// Never negative, and never below [minRadius] — a row squared off
  /// inside a rounded sheet looks like a mistake, where a slightly
  /// generous curve does not.
  static BorderRadius innerRadius(
    BorderRadius outer, {
    required double inset,
    double minRadius = 8,
  }) {
    double inner(Radius r) => (r.x - inset).clamp(minRadius, double.infinity);
    return BorderRadius.only(
      topLeft: Radius.circular(inner(outer.topLeft)),
      topRight: Radius.circular(inner(outer.topRight)),
      bottomLeft: Radius.circular(inner(outer.bottomLeft)),
      bottomRight: Radius.circular(inner(outer.bottomRight)),
    );
  }

  /// The corner for a row in a FLOATING sheet with the given inset —
  /// the shape every picker sheet uses.
  static BorderRadius rowRadius(
    BuildContext context, {
    required ResolvedSheetStyle rs,
    required double inset,
  }) => innerRadius(
    outerRadius(rs, floating: true, isTop: false),
    inset: inset,
  );
}
