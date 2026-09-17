/// Container-level size bucket — used by [BoxResponsive] for component
/// queries against the local box, not the whole window. Components
/// inside a narrow side panel still classify as [narrow] even if the
/// window is [WindowSizeClass.expanded].
///
/// 4 buckets is enough for almost every component decision (collapse,
/// inline, full, ultra). Use [WindowSizeClass] for page-level layout
/// switches.
enum BoxSizeClass {
  /// `< 360 dp` — collapsed mini-panels, narrow side rails.
  narrow,

  /// `360 – 599 dp` — phone-width content area.
  regular,

  /// `600 – 959 dp` — tablet-width content area.
  wide,

  /// `≥ 960 dp` — desktop-width content area.
  extraWide;

  static BoxSizeClass fromWidth(double width) {
    if (width < 360) return BoxSizeClass.narrow;
    if (width < 600) return BoxSizeClass.regular;
    if (width < 960) return BoxSizeClass.wide;
    return BoxSizeClass.extraWide;
  }

  String get label => switch (this) {
    narrow => 'Narrow',
    regular => 'Regular',
    wide => 'Wide',
    extraWide => 'Extra Wide',
  };

  bool isAtLeast(BoxSizeClass other) => index >= other.index;

  bool get isNarrow => this == BoxSizeClass.narrow;
  bool get isRegularUp => isAtLeast(BoxSizeClass.regular);
  bool get isWideUp => isAtLeast(BoxSizeClass.wide);
  bool get isExtraWide => this == BoxSizeClass.extraWide;
}
