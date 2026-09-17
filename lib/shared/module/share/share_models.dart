import 'package:flutter/material.dart';

/// The floor for [GlobalShareButton].
abstract final class ShareDefaults {
  /// The glyph. Rounded, because the rest of the app's chrome is.
  static const icon = Icons.share_rounded;

  static const iconSize = 24.0;

  /// A share OPENS something — the OS sheet — and a tick on the way
  /// out is the only feedback the app itself gives.
  static const enableHaptic = true;

  /// Whether the FAB variant sits on a raised surface.
  static const fabElevation = 6.0;
}

/// Presentation form of [GlobalShareButton].
enum ShareButtonVariant {
  /// Icon-only button — wraps `GlobalIconButton`. Default.
  icon,

  /// Floating action button with share icon.
  fab,

  /// A tile row — leading glyph + label. Useful in settings / menus.
  tile,
}

/// How a [GlobalShareButton] LOOKS.
///
/// Every field is nullable: unanswered means "ask the theme, then the
/// floor".
///
/// **The variant is NOT in here**, and neither is the label. A theme
/// that could turn every share control in the app into a floating
/// action button is not a theme, it is a rewrite — where the button
/// goes is the caller's decision, and what it says is content. Both
/// used to live in this bag.
@immutable
class ShareButtonStyle {
  const ShareButtonStyle({
    this.icon,
    this.iconSize,
    this.foregroundColor,
    this.backgroundColor,
    this.enableHaptic,
    this.fabElevation,
  });

  /// The floor — the only place a compile-time constant lives.
  ///
  /// It carries no COLOURS: they resolve from `context.<group>Colors`
  /// at build time so a share button tracks role, brightness and
  /// saturation like everything else.
  static const defaults = ShareButtonStyle(
    icon: ShareDefaults.icon,
    iconSize: ShareDefaults.iconSize,
    enableHaptic: ShareDefaults.enableHaptic,
    fabElevation: ShareDefaults.fabElevation,
  );

  /// A quieter control — no lift, no tick.
  static const quiet = ShareButtonStyle(
    enableHaptic: false,
    fabElevation: 0,
  );

  final IconData? icon;
  final double? iconSize;

  /// Icon + text colour. Falls back to the primary role.
  final Color? foregroundColor;

  /// The FAB's fill, or the tile's tint.
  final Color? backgroundColor;

  final bool? enableHaptic;
  final double? fabElevation;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  ShareButtonStyle mergedWith(ShareButtonStyle? other) {
    if (other == null) return this;
    return ShareButtonStyle(
      icon: other.icon ?? icon,
      iconSize: other.iconSize ?? iconSize,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      fabElevation: other.fabElevation ?? fabElevation,
    );
  }

  ShareButtonStyle copyWith({
    IconData? icon,
    double? iconSize,
    Color? foregroundColor,
    Color? backgroundColor,
    bool? enableHaptic,
    double? fabElevation,
  }) => ShareButtonStyle(
    icon: icon ?? this.icon,
    iconSize: iconSize ?? this.iconSize,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    fabElevation: fabElevation ?? this.fabElevation,
  );

  @override
  bool operator ==(Object other) =>
      other is ShareButtonStyle &&
      other.icon == icon &&
      other.iconSize == iconSize &&
      other.foregroundColor == foregroundColor &&
      other.backgroundColor == backgroundColor &&
      other.enableHaptic == enableHaptic &&
      other.fabElevation == fabElevation;

  @override
  int get hashCode => Object.hash(
    icon,
    iconSize,
    foregroundColor,
    backgroundColor,
    enableHaptic,
    fabElevation,
  );
}

/// A [ShareButtonStyle] with every question answered.
@immutable
class ResolvedShareButtonStyle {
  const ResolvedShareButtonStyle({
    required this.icon,
    required this.iconSize,
    required this.enableHaptic,
    required this.fabElevation,
    this.foregroundColor,
    this.backgroundColor,
  });

  final IconData icon;
  final double iconSize;

  /// Still nullable AFTER resolution, like [backgroundColor].
  ///
  /// The icon and tile variants fall back to the primary role. The
  /// FAB does NOT: Material fills it with the primary container and
  /// picks the matching foreground itself, so forcing the primary in
  /// there painted a primary glyph on a primary fill — a solid
  /// coloured square with nothing visible on it.
  final Color? foregroundColor;

  /// Still nullable AFTER resolution: unset means the FAB takes
  /// Material's own scheme colour and the tile stays transparent,
  /// which is not one colour to name.
  final Color? backgroundColor;

  final bool enableHaptic;
  final double fabElevation;
}
