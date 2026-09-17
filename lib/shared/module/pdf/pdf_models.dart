import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Where the PDF bytes come from.
enum PdfSourceKind { url, asset, file, bytes }

/// Polymorphic source spec. Factory constructors keep callers from
/// caring about [PdfSourceKind] until they need to.
@immutable
class PdfSourceSpec {
  const PdfSourceSpec._({
    required this.kind,
    required this.value,
    this.bytes,
    this.password,
    this.cacheKey,
  });

  factory PdfSourceSpec.url(
    String url, {
    String? password,
    String? cacheKey,
  }) => PdfSourceSpec._(
    kind: PdfSourceKind.url,
    value: url,
    password: password,
    cacheKey: cacheKey,
  );

  factory PdfSourceSpec.asset(String path, {String? password}) =>
      PdfSourceSpec._(
        kind: PdfSourceKind.asset,
        value: path,
        password: password,
      );

  factory PdfSourceSpec.file(String path, {String? password}) =>
      PdfSourceSpec._(
        kind: PdfSourceKind.file,
        value: path,
        password: password,
      );

  factory PdfSourceSpec.bytes(
    Uint8List data, {
    String label = 'bytes',
    String? password,
  }) => PdfSourceSpec._(
    kind: PdfSourceKind.bytes,
    value: label,
    bytes: data,
    password: password,
  );

  final PdfSourceKind kind;
  final String value;
  final Uint8List? bytes;

  /// Pre-supplied password. When null and the document is encrypted,
  /// the viewer invokes [GlobalPdfViewer.onPasswordRequired] to prompt
  /// the user.
  final String? password;

  /// Stable identifier used for bookmarks + thumbnail cache. Defaults
  /// to the source value (URL / path / bytes label). Override when
  /// the same logical document might appear at different URLs.
  final String? cacheKey;

  /// The persistence key — used by the bookmarks cubit + on-disk
  /// caches. Derived from [cacheKey] when set, else [value].
  String get persistKey => cacheKey ?? value;
}

/// What of a page's interactive furniture gets DRAWN.
///
/// A mirror of pdfrx's own enum, because the engine type never escapes
/// this module — the whole point is that the engine is replaceable.
enum PdfAnnotationMode {
  /// Page content only. A scan with review scribbles all over it reads
  /// as the document it was before anyone marked it up.
  none,

  /// Annotations, but not form fields.
  annotations,

  /// Annotations and form fields. pdfrx's own default, and this one's.
  annotationsAndForms,
}

/// One thing a keyboard shortcut can ask the viewer to do.
///
/// Public so the mapping can be driven directly — a test does not have
/// to synthesise a key event on a viewer that needs a real PDF engine
/// to build, and a caller with its own chrome can reuse the verbs.
enum PdfShortcutCommand {
  nextPage,
  prevPage,
  zoomIn,
  zoomOut,
  resetZoom,
  rotate,
  search,
  print,
  escape;

  /// Whether this one is reachable WITHOUT a modifier, and so competes
  /// with typing. Those are refused while the search row is open, or
  /// searching for "rotate" turns the page on every letter.
  bool get isBareKey => switch (this) {
    PdfShortcutCommand.search ||
    PdfShortcutCommand.print ||
    PdfShortcutCommand.resetZoom ||
    PdfShortcutCommand.escape => false,
    _ => true,
  };
}

/// Visual variant for [GlobalPdfViewer].
enum PdfViewerVariant {
  /// Card-sized preview — first-page thumbnail + filename + page
  /// count. Tap-to-open hook for navigation flows.
  compact,

  /// Paged viewer — one page at a time, swipe / scroll between
  /// pages. Pinch-zoom + page indicator + controls.
  full,

  /// Continuous vertical scroll — all pages stacked book-style.
  continuous,

  /// Caller-driven layout — supply [GlobalPdfViewer.builder] to
  /// compose chrome around the viewer.
  custom,
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [PdfStyle] instead.
abstract final class PdfDefaults {
  static const compactHeight = 180.0;
  static const thumbnailStripHeight = 72.0;
  static const pageGap = 8.0;
  static const radius = 12.0;

  static const initialZoom = 1.0;
  static const minZoom = 0.5;
  static const maxZoom = 6.0;
  static const zoomStep = 0.25;

  /// The scrim under the compact variant's filename, and the text on
  /// it. Fixed rather than themed: it sits over the first PAGE of the
  /// document, whose colour nothing here controls.
  static const compactScrimOpacity = 0.55;
  static const compactTitleOpacity = 0.95;
  static const compactMetaOpacity = 0.85;

  /// How much of the accent a search hit keeps. The focused one is
  /// full strength, so it reads as the one you are on.
  static const matchOpacity = 0.35;
}

// ---------------------------------------------------------------------------
// PdfStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalPdfViewer` — EVERY field nullable.
///
/// Resolution order, materialized once per build by
/// `style.resolve(context)`:
/// `caller > GlobalPdfTheme.style > PdfStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedPdfStyle] and `GlobalPdfTheme.lerp`.
@immutable
class PdfStyle {
  const PdfStyle({
    this.accent,
    this.background,
    this.controlsColor,
    this.padding,
    this.borderRadius,
    this.compactHeight,
    this.showPageIndicator,
    this.showZoomControls,
    this.showSearchButton,
    this.showOutlineButton,
    this.showThumbnailStrip,
    this.showShareButton,
    this.showRotateButton,
    this.showActionsMenu,
    this.enableTextSelection,
    this.openExternalLinks,
    this.invertColorsInDark,
    this.thumbnailStripHeight,
    this.pageGap,
    this.initialZoom,
    this.minZoom,
    this.maxZoom,
    this.zoomStep,
    this.matchColor,
    this.activeMatchColor,
    this.panEnabled,
    this.annotationMode,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from the palette at build time, so a viewer tracks the app's
  /// role, brightness and saturation.
  static const PdfStyle defaults = PdfStyle(
    compactHeight: PdfDefaults.compactHeight,
    showPageIndicator: true,
    showZoomControls: true,
    showSearchButton: true,
    showOutlineButton: true,
    showThumbnailStrip: false,
    showShareButton: false,
    showRotateButton: true,
    showActionsMenu: true,
    enableTextSelection: true,
    openExternalLinks: true,
    invertColorsInDark: false,
    thumbnailStripHeight: PdfDefaults.thumbnailStripHeight,
    pageGap: PdfDefaults.pageGap,
    initialZoom: PdfDefaults.initialZoom,
    minZoom: PdfDefaults.minZoom,
    maxZoom: PdfDefaults.maxZoom,
    zoomStep: PdfDefaults.zoomStep,
    panEnabled: true,
    annotationMode: PdfAnnotationMode.annotationsAndForms,
  );

  /// Highlight / progress accent. Null takes the palette primary.
  final Color? accent;

  /// Surface behind pages. Null takes the palette's container.
  final Color? background;

  /// Tint for transport / search / zoom icons. Null takes the
  /// palette's primary text colour.
  final Color? controlsColor;

  /// Outer padding around the viewer.
  final EdgeInsets? padding;

  /// Corner radius for the viewer surface.
  final BorderRadius? borderRadius;

  /// Height for [PdfViewerVariant.compact].
  final double? compactHeight;

  final bool? showPageIndicator;
  final bool? showZoomControls;
  final bool? showSearchButton;
  final bool? showOutlineButton;

  /// Horizontal thumbnail strip overlay at the bottom (full variant).
  final bool? showThumbnailStrip;

  /// System-share icon next to outline / search.
  final bool? showShareButton;

  /// Rotate button — cycles 0/90/180/270.
  final bool? showRotateButton;

  /// "More" menu — share / print / save-as system intents.
  final bool? showActionsMenu;

  /// Enable native text selection + copy. Maps to pdfrx's
  /// `textSelectionParams`.
  final bool? enableTextSelection;

  /// Tap link annotations to navigate. External URLs open via
  /// `url_launcher`; internal links jump to the target page.
  final bool? openExternalLinks;

  /// Invert page colors when the app is in dark mode — cheap "night
  /// mode" without re-rasterizing.
  final bool? invertColorsInDark;

  /// Height of the horizontal thumbnail strip when
  /// [showThumbnailStrip] is true.
  final double? thumbnailStripHeight;

  /// Pixel gap between pages in continuous mode.
  final double? pageGap;

  final double? initialZoom;
  final double? minZoom;
  final double? maxZoom;

  /// Step applied by the zoom-in / zoom-out buttons.
  final double? zoomStep;

  /// Whether a drag PANS the document.
  ///
  /// ON, which is right for a viewer that owns its screen. Set it FALSE
  /// for one embedded in a scrolling page: a drag can belong to the
  /// document or to the page, never to both, and with panning on the
  /// two fight — the gesture arena hands the drag to whichever
  /// recognizer claims it first, which is not something the reader can
  /// predict from looking at it. Off, the page scrolls and the viewer's
  /// own controls do the paging.
  final bool? panEnabled;

  /// Which of a page's annotations and form fields get drawn.
  ///
  /// Everything, by default. Turn it down when the markup is noise —
  /// a reviewed contract covered in comment boxes, a scan someone
  /// highlighted — or when the annotations are the reason the page is
  /// unreadable to a screen reader.
  final PdfAnnotationMode? annotationMode;

  /// Search match highlight (non-active). Null takes the accent,
  /// washed.
  final Color? matchColor;

  /// Active (currently focused) search match highlight. Null takes the
  /// accent at full strength, so the one you are on stands out from
  /// the rest.
  final Color? activeMatchColor;

  /// Field-by-field override — anything set on [other] wins.
  PdfStyle mergedWith(PdfStyle? other) {
    if (other == null) return this;
    return PdfStyle(
      accent: other.accent ?? accent,
      background: other.background ?? background,
      controlsColor: other.controlsColor ?? controlsColor,
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      compactHeight: other.compactHeight ?? compactHeight,
      showPageIndicator: other.showPageIndicator ?? showPageIndicator,
      showZoomControls: other.showZoomControls ?? showZoomControls,
      showSearchButton: other.showSearchButton ?? showSearchButton,
      showOutlineButton: other.showOutlineButton ?? showOutlineButton,
      showThumbnailStrip: other.showThumbnailStrip ?? showThumbnailStrip,
      showShareButton: other.showShareButton ?? showShareButton,
      showRotateButton: other.showRotateButton ?? showRotateButton,
      showActionsMenu: other.showActionsMenu ?? showActionsMenu,
      enableTextSelection: other.enableTextSelection ?? enableTextSelection,
      openExternalLinks: other.openExternalLinks ?? openExternalLinks,
      invertColorsInDark: other.invertColorsInDark ?? invertColorsInDark,
      thumbnailStripHeight: other.thumbnailStripHeight ?? thumbnailStripHeight,
      pageGap: other.pageGap ?? pageGap,
      initialZoom: other.initialZoom ?? initialZoom,
      minZoom: other.minZoom ?? minZoom,
      maxZoom: other.maxZoom ?? maxZoom,
      zoomStep: other.zoomStep ?? zoomStep,
      matchColor: other.matchColor ?? matchColor,
      activeMatchColor: other.activeMatchColor ?? activeMatchColor,
      panEnabled: other.panEnabled ?? panEnabled,
      annotationMode: other.annotationMode ?? annotationMode,
    );
  }

  PdfStyle copyWith({
    Color? accent,
    Color? background,
    Color? controlsColor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    double? compactHeight,
    bool? showPageIndicator,
    bool? showZoomControls,
    bool? showSearchButton,
    bool? showOutlineButton,
    bool? showThumbnailStrip,
    bool? showShareButton,
    bool? showRotateButton,
    bool? showActionsMenu,
    bool? enableTextSelection,
    bool? openExternalLinks,
    bool? invertColorsInDark,
    double? thumbnailStripHeight,
    double? pageGap,
    double? initialZoom,
    double? minZoom,
    double? maxZoom,
    double? zoomStep,
    Color? matchColor,
    Color? activeMatchColor,
    bool? panEnabled,
    PdfAnnotationMode? annotationMode,
  }) => PdfStyle(
    accent: accent ?? this.accent,
    background: background ?? this.background,
    controlsColor: controlsColor ?? this.controlsColor,
    padding: padding ?? this.padding,
    borderRadius: borderRadius ?? this.borderRadius,
    compactHeight: compactHeight ?? this.compactHeight,
    showPageIndicator: showPageIndicator ?? this.showPageIndicator,
    showZoomControls: showZoomControls ?? this.showZoomControls,
    showSearchButton: showSearchButton ?? this.showSearchButton,
    showOutlineButton: showOutlineButton ?? this.showOutlineButton,
    showThumbnailStrip: showThumbnailStrip ?? this.showThumbnailStrip,
    showShareButton: showShareButton ?? this.showShareButton,
    showRotateButton: showRotateButton ?? this.showRotateButton,
    showActionsMenu: showActionsMenu ?? this.showActionsMenu,
    enableTextSelection: enableTextSelection ?? this.enableTextSelection,
    openExternalLinks: openExternalLinks ?? this.openExternalLinks,
    invertColorsInDark: invertColorsInDark ?? this.invertColorsInDark,
    thumbnailStripHeight: thumbnailStripHeight ?? this.thumbnailStripHeight,
    pageGap: pageGap ?? this.pageGap,
    initialZoom: initialZoom ?? this.initialZoom,
    minZoom: minZoom ?? this.minZoom,
    maxZoom: maxZoom ?? this.maxZoom,
    zoomStep: zoomStep ?? this.zoomStep,
    matchColor: matchColor ?? this.matchColor,
    activeMatchColor: activeMatchColor ?? this.activeMatchColor,
    panEnabled: panEnabled ?? this.panEnabled,
    annotationMode: annotationMode ?? this.annotationMode,
  );
}

// ---------------------------------------------------------------------------
// ResolvedPdfStyle
// ---------------------------------------------------------------------------

/// [PdfStyle] after `caller > theme > defaults > palette`. Every themed
/// field is non-null, so build code reads `rs.accent` with no `??`
/// ladder behind it.
@immutable
class ResolvedPdfStyle {
  const ResolvedPdfStyle({
    required this.accent,
    required this.background,
    required this.controlsColor,
    required this.padding,
    required this.borderRadius,
    required this.compactHeight,
    required this.showPageIndicator,
    required this.showZoomControls,
    required this.showSearchButton,
    required this.showOutlineButton,
    required this.showThumbnailStrip,
    required this.showShareButton,
    required this.showRotateButton,
    required this.showActionsMenu,
    required this.enableTextSelection,
    required this.openExternalLinks,
    required this.invertColorsInDark,
    required this.thumbnailStripHeight,
    required this.pageGap,
    required this.initialZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.zoomStep,
    required this.matchColor,
    required this.activeMatchColor,
    required this.panEnabled,
    required this.annotationMode,
  });

  final Color accent;
  final Color background;
  final Color controlsColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final double compactHeight;
  final bool showPageIndicator;
  final bool showZoomControls;
  final bool showSearchButton;
  final bool showOutlineButton;
  final bool showThumbnailStrip;
  final bool showShareButton;
  final bool showRotateButton;
  final bool showActionsMenu;
  final bool enableTextSelection;
  final bool openExternalLinks;
  final bool invertColorsInDark;
  final double thumbnailStripHeight;
  final double pageGap;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final double zoomStep;
  final Color matchColor;
  final Color activeMatchColor;
  final PdfAnnotationMode annotationMode;

  /// Whether a drag pans the document rather than the page around it.
  final bool panEnabled;
}

/// State exposed to UI without leaking pdfrx types.
@immutable
class PdfStateSnapshot {
  const PdfStateSnapshot({
    required this.pageNumber,
    required this.pageCount,
    required this.zoom,
    required this.rotation,
    required this.loading,
    required this.errored,
    required this.encrypted,
    required this.searching,
    required this.matchCount,
    required this.currentMatchIndex,
    this.title,
    this.author,
  });

  /// 1-based page number. 0 when not loaded.
  final int pageNumber;
  final int pageCount;
  final double zoom;

  /// Whole-view rotation in degrees (0 / 90 / 180 / 270).
  final int rotation;

  final bool loading;
  final bool errored;

  /// True when the document required a password to open.
  final bool encrypted;
  final bool searching;
  final int matchCount;

  /// 0-based index into the match list, or -1 when none focused.
  final int currentMatchIndex;

  /// Document metadata (when available). Pulled from the PDF's
  /// /Info dictionary on load.
  final String? title;
  final String? author;

  static const empty = PdfStateSnapshot(
    pageNumber: 0,
    pageCount: 0,
    zoom: 1,
    rotation: 0,
    loading: true,
    errored: false,
    encrypted: false,
    searching: false,
    matchCount: 0,
    currentMatchIndex: -1,
  );
}

/// Outline node exposed to UI. Wraps pdfrx's `PdfOutlineNode` so
/// callers don't take a hard dep on the engine type.
@immutable
class PdfOutlineItem {
  const PdfOutlineItem({
    required this.title,
    required this.pageNumber,
    required this.children,
  });

  final String title;

  /// Target page (1-based). 0 when the outline entry doesn't resolve
  /// to a page (rare — e.g. URL actions).
  final int pageNumber;

  final List<PdfOutlineItem> children;
}
