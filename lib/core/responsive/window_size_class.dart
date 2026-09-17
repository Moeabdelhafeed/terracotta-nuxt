/// Material 3 *window size class* — semantic, layout-decision bucket.
/// Use for "which layout do I render?" choices. For pixel-level device
/// info (e.g. logging, design-time picker) see [DeviceFormFactor].
///
/// Thresholds match the Material 3 spec:
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
enum WindowSizeClass {
  /// `< 600 dp` — phones portrait, small foldables.
  compact,

  /// `600 – 839 dp` — phones landscape, tablets portrait, foldables open.
  medium,

  /// `840 – 1199 dp` — tablets landscape, small laptops.
  expanded,

  /// `1200 – 1599 dp` — laptops, small desktops.
  large,

  /// `≥ 1600 dp` — desktops, ultra-wide.
  extraLarge;

  /// Pick the bucket from a width in logical pixels.
  static WindowSizeClass fromWidth(double width) {
    if (width < 600) return WindowSizeClass.compact;
    if (width < 840) return WindowSizeClass.medium;
    if (width < 1200) return WindowSizeClass.expanded;
    if (width < 1600) return WindowSizeClass.large;
    return WindowSizeClass.extraLarge;
  }

  String get label => switch (this) {
    compact => 'Compact',
    medium => 'Medium',
    expanded => 'Expanded',
    large => 'Large',
    extraLarge => 'Extra Large',
  };

  /// `true` if this bucket is `>=` [other].
  bool isAtLeast(WindowSizeClass other) => index >= other.index;

  bool get isCompact => this == WindowSizeClass.compact;
  bool get isMediumUp => isAtLeast(WindowSizeClass.medium);
  bool get isExpandedUp => isAtLeast(WindowSizeClass.expanded);
  bool get isLargeUp => isAtLeast(WindowSizeClass.large);
  bool get isExtraLarge => this == WindowSizeClass.extraLarge;
}

/// Material 3 *window height class* — used for landscape phone /
/// short-window decisions (collapse app bars, hide secondary nav).
enum WindowHeightClass {
  /// `< 480 dp` — landscape phones, very short windows.
  compact,

  /// `480 – 899 dp` — most phones portrait, small tablets.
  medium,

  /// `≥ 900 dp` — tall tablets, desktops.
  expanded;

  static WindowHeightClass fromHeight(double height) {
    if (height < 480) return WindowHeightClass.compact;
    if (height < 900) return WindowHeightClass.medium;
    return WindowHeightClass.expanded;
  }

  String get label => switch (this) {
    compact => 'Short',
    medium => 'Medium',
    expanded => 'Tall',
  };

  bool get isCompact => this == WindowHeightClass.compact;
  bool get isMediumUp => index >= WindowHeightClass.medium.index;
  bool get isExpanded => this == WindowHeightClass.expanded;
}
