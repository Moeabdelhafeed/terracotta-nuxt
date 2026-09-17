import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Capture behavior for [GlobalScanner].
enum ScannerCaptureMode {
  /// Report the first read and STOP the camera. Use for "scan and go"
  /// flows where the screen closes on the result.
  single,

  /// Stream every read without dismissing. Use when many codes are
  /// scanned in a row.
  continuous,

  /// Hold each read pending until it is confirmed. Use when an
  /// accidental scan is costly — a payment, a stock movement.
  manual,
}

/// What a detection MEANS, given the mode and what is already held.
///
/// Pure, and named, because the switch it replaces was three cases
/// where two did the same thing and the third silently dropped reads
/// while one was pending — and none of it could be tested, since
/// `GlobalScanner` needs a camera to build at all.
enum ScannerCaptureAction {
  /// Hand it to the caller.
  report,

  /// Hand it to the caller and stop the camera.
  reportAndStop,

  /// Hold it for confirmation.
  hold,

  /// Drop it — something is already held.
  ignore,

  /// It is not a code this scanner wants. Say so and keep looking.
  reject,
}

/// How hard the plugin looks.
///
/// The module's own enum rather than the plugin's, so a caller does
/// not import `mobile_scanner` to set a speed — the same reason
/// [ScannerFormat] exists.
enum ScannerDetectionSpeed {
  /// Every frame. Costs battery; use it when a code is expected to
  /// pass through the frame quickly.
  noDuplicates,

  /// Throttled by `detectionTimeout`, and the same code is not
  /// reported twice in a row.
  normal,

  /// Every frame, duplicates included.
  unrestricted;

  DetectionSpeed get pluginSpeed => switch (this) {
    ScannerDetectionSpeed.noDuplicates => DetectionSpeed.noDuplicates,
    ScannerDetectionSpeed.normal => DetectionSpeed.normal,
    ScannerDetectionSpeed.unrestricted => DetectionSpeed.unrestricted,
  };
}

/// Subset of formats the scanner reports. `any` lets every format
/// fire; restricting cuts noise + avoids ML models the dev doesn't
/// need.
enum ScannerFormat {
  any,
  qr,
  ean8,
  ean13,
  code128,
  code39,
  code93,
  pdf417,
  aztec,
  upcA,
  upcE,
  itf,
  dataMatrix;

  /// Convert to the plugin's enum. `any` returns null so the plugin
  /// uses its default (every format).
  BarcodeFormat? get pluginFormat => switch (this) {
    ScannerFormat.any => null,
    ScannerFormat.qr => BarcodeFormat.qrCode,
    ScannerFormat.ean8 => BarcodeFormat.ean8,
    ScannerFormat.ean13 => BarcodeFormat.ean13,
    ScannerFormat.code128 => BarcodeFormat.code128,
    ScannerFormat.code39 => BarcodeFormat.code39,
    ScannerFormat.code93 => BarcodeFormat.code93,
    ScannerFormat.pdf417 => BarcodeFormat.pdf417,
    ScannerFormat.aztec => BarcodeFormat.aztec,
    ScannerFormat.upcA => BarcodeFormat.upcA,
    ScannerFormat.upcE => BarcodeFormat.upcE,
    ScannerFormat.itf => BarcodeFormat.itf14,
    ScannerFormat.dataMatrix => BarcodeFormat.dataMatrix,
  };

  /// Whether a list of these means "every format".
  ///
  /// The plugin takes an EMPTY list as "no restriction", and `any`
  /// maps to null — so a list holding `any` alongside three real
  /// formats used to silently become those three. Saying `any` at all
  /// means any.
  static bool isUnrestricted(List<ScannerFormat> formats) =>
      formats.isEmpty || formats.contains(ScannerFormat.any);
}

/// Every hard-coded number the scanner draws with.
abstract final class ScannerDefaults {
  // ─── Viewfinder ───────────────────────────────────────────
  /// How much of the SHORT side the window takes.
  ///
  /// A fraction rather than a fixed 260 points, because this app
  /// rotates: a square that fits a portrait phone is most of a
  /// landscape one's height, and a tablet made the same box look like
  /// a postage stamp. The short side is the one that constrains, both
  /// ways up.
  static const viewfinderFraction = 0.7;

  /// Width over height. 1 is the square a QR wants.
  static const viewfinderAspect = 1.0;

  /// The wide window's shape, for the formats that ARE wide. A 1D
  /// barcode is a stripe, and a square box over it asks someone to
  /// line up a shape the code does not have.
  static const wideViewfinderAspect = 5 / 3;

  /// Only used when a caller pins an exact size.
  static const viewfinderSize = Size(260, 260);

  static const cornerLength = 24.0;
  static const cornerWidth = 4.0;
  static const cornerRadius = 12.0;
  static const dimColor = Color(0x99000000);

  // ─── Controls ─────────────────────────────────────────────
  static const controlSize = 22.0;
  static const controlGap = 8.0;
  static const controlsPadding = EdgeInsets.fromLTRB(20, 0, 20, 24);
  static const trackHeight = 3.0;
  static const thumbRadius = 7.0;
  static const overlayRadius = 14.0;

  /// The disc behind a control glyph, over camera pixels.
  static const controlScrim = Color(0x73000000);

  // ─── Pending plate ────────────────────────────────────────
  static const pendingRadius = 14.0;
  static const pendingPadding = EdgeInsets.all(14);
  static const pendingInset = 16.0;
  static const pendingBottom = 100.0;
  static const pendingSurface = Color(0xD9000000);
  static const pendingMaxLines = 3;

  // ─── Behaviour ────────────────────────────────────────────
  /// The plugin's own default, and the reason it exists: a code left
  /// sitting in frame otherwise reports on every frame, and a
  /// continuous scanner machine-guns its callback.
  static const detectionTimeout = Duration(milliseconds: 250);

  /// How far a pinch has to travel to cover the whole zoom range.
  ///
  /// The camera's zoom is 0..1 while a scale gesture is a ratio around
  /// 1, so the two need a conversion. Measured on a phone: a full
  /// two-finger spread is roughly 2.5x, and mapping that to the whole
  /// range makes small corrections impossible — so half the range per
  /// spread, and a second spread reaches the end.
  static const pinchSensitivity = 0.4;

  /// How long a refused code is named on screen.
  static const rejectionLinger = Duration(seconds: 2);

  // ─── Motion ───────────────────────────────────────────────
  /// One sweep of the scan line, down and back.
  static const scanLinePeriod = Duration(milliseconds: 2600);

  /// The brackets flash when a code is accepted. Short, because the
  /// screen is usually closing behind it.
  static const successFlash = Duration(milliseconds: 420);

  /// How thick that line is, and how far its glow reaches.
  static const scanLineHeight = 2.0;
  static const scanLineGlow = 12.0;

  // ─── Spacing ──────────────────────────────────────────────
  static const gapXs = 4.0;
  static const gapSm = 8.0;
  static const gapMd = 12.0;
  static const gapLg = 20.0;
  static const deniedGlyphSize = 48.0;
  static const deniedPadding = EdgeInsets.all(24);
}

/// How the scanner LOOKS and which controls it offers.
///
/// Every field is nullable so the three sources layer without a
/// default clobbering a theme: `caller > GlobalScannerTheme.style >
/// ScannerStyle.defaults`. Resolved once per build into a
/// [ResolvedScannerStyle].
///
/// It was half-nullable before — only the accent could be omitted, and
/// every size and flag carried an inline default, so a house that
/// wanted a different viewfinder had to say so at every call site and
/// could never change it centrally.
@immutable
class ScannerStyle {
  const ScannerStyle({
    this.viewfinderColor,
    this.successColor,
    this.viewfinderSize,
    this.viewfinderFraction,
    this.viewfinderAspect,
    this.cornerLength,
    this.cornerWidth,
    this.cornerRadius,
    this.dimColor,
    this.controlsColor,
    this.controlScrim,
    this.controlSize,
    this.showTorch,
    this.showFlip,
    this.showZoom,
    this.showScanLine,
    this.showSuccessFlash,
    this.restrictToViewfinder,
    this.enableHaptic,
    this.enablePinchZoom,
    this.tapToFocus,
    this.autoZoom,
    this.invertImage,
    this.detectionSpeed,
    this.detectionTimeout,
    this.cameraResolution,
  });

  /// The floor. The accent is absent on purpose — it resolves from the
  /// palette at build time so it tracks role, brightness and
  /// saturation, which a constant cannot.
  static const ScannerStyle defaults = ScannerStyle(
    viewfinderFraction: ScannerDefaults.viewfinderFraction,
    viewfinderAspect: ScannerDefaults.viewfinderAspect,
    cornerLength: ScannerDefaults.cornerLength,
    cornerWidth: ScannerDefaults.cornerWidth,
    cornerRadius: ScannerDefaults.cornerRadius,
    dimColor: ScannerDefaults.dimColor,
    controlsColor: Colors.white,
    controlScrim: ScannerDefaults.controlScrim,
    controlSize: ScannerDefaults.controlSize,
    showTorch: true,
    showFlip: true,
    showZoom: true,
    showScanLine: true,
    showSuccessFlash: true,
    restrictToViewfinder: true,
    enableHaptic: true,
    enablePinchZoom: true,
    tapToFocus: true,
    autoZoom: false,
    invertImage: false,
    detectionSpeed: ScannerDetectionSpeed.noDuplicates,
    detectionTimeout: ScannerDefaults.detectionTimeout,
  );

  // ─── Presets ──────────────────────────────────────────────
  //
  // A preset is a NAMED BAG. Everything it decides is what the bag
  // already carries, so it merges with a theme and loses to a per-call
  // override like any other bag, and adds no code path to keep true.

  /// A scanner embedded in a page that has its own chrome.
  ///
  /// No controls and no dim: the page around it owns the surface, and
  /// dimming three quarters of a 200-point card leaves a stamp-sized
  /// picture. Thin brackets, because at that size a 4-point one reads
  /// as a frame rather than as a guide.
  static const ScannerStyle minimal = ScannerStyle(
    showTorch: false,
    showFlip: false,
    showZoom: false,
    showScanLine: false,
    dimColor: Colors.transparent,
    cornerWidth: 2,
    cornerLength: 16,
    viewfinderFraction: 0.55,
  );

  /// A dedicated scanning screen.
  ///
  /// Everything on, a heavier dim and a larger window — this one IS
  /// the screen, so the picture can afford to be about the code.
  static const ScannerStyle focused = ScannerStyle(
    viewfinderFraction: 0.8,
    dimColor: Color(0xCC000000),
    cornerLength: 32,
    showTorch: true,
    showFlip: true,
    showZoom: true,
    showScanLine: true,
  );

  /// Retail barcodes, driving licences, boarding passes.
  ///
  /// A WIDE window, because those formats are stripes. The square box
  /// asks someone to line up a shape the code does not have, and the
  /// scan window follows the box — so a square one over a long barcode
  /// refuses reads that are plainly inside the picture.
  static const ScannerStyle wide = ScannerStyle(
    viewfinderAspect: ScannerDefaults.wideViewfinderAspect,
    showZoom: true,
    showTorch: true,
  );

  /// Viewfinder corner brackets. Falls back to the palette primary.
  final Color? viewfinderColor;

  /// The flash when a code is ACCEPTED. Falls back to the palette's
  /// success colour.
  final Color? successColor;

  /// An exact window, in points. Wins over [viewfinderFraction] — for
  /// a caller who genuinely needs one size, everywhere, whatever the
  /// screen is.
  final Size? viewfinderSize;

  /// How much of the SHORT side the window takes, 0..1.
  ///
  /// A fraction rather than a fixed box because this app rotates: a
  /// square that fits a portrait phone is most of a landscape one's
  /// height, and on a tablet the same box is a postage stamp. The
  /// short side is the one that constrains, both ways up.
  final double? viewfinderFraction;

  /// Width over height. 1 is the square a QR wants; the `wide` preset
  /// is 5:3, because a 1D barcode is a stripe.
  final double? viewfinderAspect;

  final double? cornerLength;
  final double? cornerWidth;
  final double? cornerRadius;

  /// Tinted overlay outside the viewfinder.
  final Color? dimColor;

  /// The control glyphs. WHITE by default, and deliberately not a
  /// palette colour — see the module's CLAUDE.md.
  final Color? controlsColor;

  /// The disc behind a control glyph.
  final Color? controlScrim;

  final double? controlSize;

  final bool? showTorch;
  final bool? showFlip;
  final bool? showZoom;

  /// The sweeping line inside the viewfinder. Purely an affordance —
  /// it says the camera is live — and it is skipped under reduced
  /// motion.
  final bool? showScanLine;

  /// The brackets flash when a code is accepted.
  ///
  /// A haptic is the only other mark a read leaves, and a haptic is
  /// nothing to someone who has them switched off or is wearing
  /// gloves. Skipped under reduced motion.
  final bool? showSuccessFlash;

  /// Whether only codes INSIDE the viewfinder are read.
  ///
  /// On. A box drawn over a picture that is scanned edge to edge is a
  /// box that lies: it reads whatever is in frame and then claims the
  /// reader aimed. Off is for a scanner with no visible window.
  final bool? restrictToViewfinder;

  /// A tick when a code is read. There is nothing else to say a scan
  /// happened when the screen is about to close.
  final bool? enableHaptic;

  /// Pinch the preview to zoom. On, because it is the first thing
  /// anyone tries and the slider was the only way in.
  final bool? enablePinchZoom;

  /// Tap the preview to focus. On — a code held close is the case
  /// continuous autofocus is worst at.
  final bool? tapToFocus;

  /// Let the camera zoom itself towards a small or distant code.
  /// Android only, and OFF: it moves the picture under the reader,
  /// which is startling when it was not asked for.
  final bool? autoZoom;

  /// Scan white-on-black codes, which some printed labels are.
  final bool? invertImage;

  /// How hard the plugin looks. See [ScannerDetectionSpeed].
  final ScannerDetectionSpeed? detectionSpeed;

  /// The gap between reports at [ScannerDetectionSpeed.normal].
  final Duration? detectionTimeout;

  /// What the camera is asked for. Android only; elsewhere the
  /// platform picks.
  final Size? cameraResolution;

  /// [other] wins field by field. Null means "did not say", which is
  /// what lets a caller override one thing without restating a theme.
  ScannerStyle mergedWith(ScannerStyle? other) {
    if (other == null) return this;
    return ScannerStyle(
      viewfinderColor: other.viewfinderColor ?? viewfinderColor,
      viewfinderSize: other.viewfinderSize ?? viewfinderSize,
      successColor: other.successColor ?? successColor,
      viewfinderFraction: other.viewfinderFraction ?? viewfinderFraction,
      viewfinderAspect: other.viewfinderAspect ?? viewfinderAspect,
      showSuccessFlash: other.showSuccessFlash ?? showSuccessFlash,
      enablePinchZoom: other.enablePinchZoom ?? enablePinchZoom,
      tapToFocus: other.tapToFocus ?? tapToFocus,
      autoZoom: other.autoZoom ?? autoZoom,
      invertImage: other.invertImage ?? invertImage,
      detectionSpeed: other.detectionSpeed ?? detectionSpeed,
      detectionTimeout: other.detectionTimeout ?? detectionTimeout,
      cameraResolution: other.cameraResolution ?? cameraResolution,
      cornerLength: other.cornerLength ?? cornerLength,
      cornerWidth: other.cornerWidth ?? cornerWidth,
      cornerRadius: other.cornerRadius ?? cornerRadius,
      dimColor: other.dimColor ?? dimColor,
      controlsColor: other.controlsColor ?? controlsColor,
      controlScrim: other.controlScrim ?? controlScrim,
      controlSize: other.controlSize ?? controlSize,
      showTorch: other.showTorch ?? showTorch,
      showFlip: other.showFlip ?? showFlip,
      showZoom: other.showZoom ?? showZoom,
      showScanLine: other.showScanLine ?? showScanLine,
      restrictToViewfinder: other.restrictToViewfinder ?? restrictToViewfinder,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  ScannerStyle copyWith({
    Color? viewfinderColor,
    Color? successColor,
    Size? viewfinderSize,
    double? viewfinderFraction,
    double? viewfinderAspect,
    double? cornerLength,
    double? cornerWidth,
    double? cornerRadius,
    Color? dimColor,
    Color? controlsColor,
    Color? controlScrim,
    double? controlSize,
    bool? showTorch,
    bool? showFlip,
    bool? showZoom,
    bool? showScanLine,
    bool? showSuccessFlash,
    bool? restrictToViewfinder,
    bool? enableHaptic,
    bool? enablePinchZoom,
    bool? tapToFocus,
    bool? autoZoom,
    bool? invertImage,
    ScannerDetectionSpeed? detectionSpeed,
    Duration? detectionTimeout,
    Size? cameraResolution,
  }) => ScannerStyle(
    viewfinderColor: viewfinderColor ?? this.viewfinderColor,
    successColor: successColor ?? this.successColor,
    viewfinderSize: viewfinderSize ?? this.viewfinderSize,
    viewfinderFraction: viewfinderFraction ?? this.viewfinderFraction,
    viewfinderAspect: viewfinderAspect ?? this.viewfinderAspect,
    cornerLength: cornerLength ?? this.cornerLength,
    cornerWidth: cornerWidth ?? this.cornerWidth,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    dimColor: dimColor ?? this.dimColor,
    controlsColor: controlsColor ?? this.controlsColor,
    controlScrim: controlScrim ?? this.controlScrim,
    controlSize: controlSize ?? this.controlSize,
    showTorch: showTorch ?? this.showTorch,
    showFlip: showFlip ?? this.showFlip,
    showZoom: showZoom ?? this.showZoom,
    showScanLine: showScanLine ?? this.showScanLine,
    showSuccessFlash: showSuccessFlash ?? this.showSuccessFlash,
    restrictToViewfinder: restrictToViewfinder ?? this.restrictToViewfinder,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    enablePinchZoom: enablePinchZoom ?? this.enablePinchZoom,
    tapToFocus: tapToFocus ?? this.tapToFocus,
    autoZoom: autoZoom ?? this.autoZoom,
    invertImage: invertImage ?? this.invertImage,
    detectionSpeed: detectionSpeed ?? this.detectionSpeed,
    detectionTimeout: detectionTimeout ?? this.detectionTimeout,
    cameraResolution: cameraResolution ?? this.cameraResolution,
  );

  @override
  bool operator ==(Object other) =>
      other is ScannerStyle &&
      other.viewfinderColor == viewfinderColor &&
      other.successColor == successColor &&
      other.viewfinderSize == viewfinderSize &&
      other.viewfinderFraction == viewfinderFraction &&
      other.viewfinderAspect == viewfinderAspect &&
      other.cornerLength == cornerLength &&
      other.cornerWidth == cornerWidth &&
      other.cornerRadius == cornerRadius &&
      other.dimColor == dimColor &&
      other.controlsColor == controlsColor &&
      other.controlScrim == controlScrim &&
      other.controlSize == controlSize &&
      other.showTorch == showTorch &&
      other.showFlip == showFlip &&
      other.showZoom == showZoom &&
      other.showScanLine == showScanLine &&
      other.showSuccessFlash == showSuccessFlash &&
      other.restrictToViewfinder == restrictToViewfinder &&
      other.enableHaptic == enableHaptic &&
      other.enablePinchZoom == enablePinchZoom &&
      other.tapToFocus == tapToFocus &&
      other.autoZoom == autoZoom &&
      other.invertImage == invertImage &&
      other.detectionSpeed == detectionSpeed &&
      other.detectionTimeout == detectionTimeout &&
      other.cameraResolution == cameraResolution;

  @override
  int get hashCode => Object.hashAll([
    viewfinderColor,
    successColor,
    viewfinderSize,
    viewfinderFraction,
    viewfinderAspect,
    cornerLength,
    cornerWidth,
    cornerRadius,
    dimColor,
    controlsColor,
    controlScrim,
    controlSize,
    showTorch,
    showFlip,
    showZoom,
    showScanLine,
    showSuccessFlash,
    restrictToViewfinder,
    enableHaptic,
    enablePinchZoom,
    tapToFocus,
    autoZoom,
    invertImage,
    detectionSpeed,
    detectionTimeout,
    cameraResolution,
  ]);
}

/// A [ScannerStyle] with every question answered.
///
/// Built once per build by `style.resolve(context)`. Nothing
/// downstream takes a nullable field or reaches for `Theme.of` — the
/// widget used to resolve the accent itself, in `build`, which is also
/// where the painter got it from.
@immutable
class ResolvedScannerStyle {
  const ResolvedScannerStyle({
    required this.viewfinderColor,
    required this.successColor,
    required this.viewfinderFraction,
    required this.viewfinderAspect,
    required this.cornerLength,
    required this.cornerWidth,
    required this.cornerRadius,
    required this.dimColor,
    required this.controlsColor,
    required this.controlScrim,
    required this.controlSize,
    required this.showTorch,
    required this.showFlip,
    required this.showZoom,
    required this.showScanLine,
    required this.showSuccessFlash,
    required this.restrictToViewfinder,
    required this.enableHaptic,
    required this.enablePinchZoom,
    required this.tapToFocus,
    required this.autoZoom,
    required this.invertImage,
    required this.detectionSpeed,
    required this.detectionTimeout,
    this.viewfinderSize,
    this.cameraResolution,
  });

  final Color viewfinderColor;
  final Color successColor;

  /// Pinned size, when a caller asked for one. Null means the window
  /// is derived from [viewfinderFraction] and [viewfinderAspect].
  final Size? viewfinderSize;

  final double viewfinderFraction;
  final double viewfinderAspect;
  final double cornerLength;
  final double cornerWidth;
  final double cornerRadius;
  final Color dimColor;
  final Color controlsColor;
  final Color controlScrim;
  final double controlSize;
  final bool showTorch;
  final bool showFlip;
  final bool showZoom;
  final bool showScanLine;
  final bool showSuccessFlash;
  final bool restrictToViewfinder;
  final bool enableHaptic;
  final bool enablePinchZoom;
  final bool tapToFocus;
  final bool autoZoom;
  final bool invertImage;
  final ScannerDetectionSpeed detectionSpeed;
  final Duration detectionTimeout;
  final Size? cameraResolution;

  /// Where the viewfinder sits inside a preview of [size].
  ///
  /// ONE answer, used by the painter, by the scan window and by the
  /// scan line. It was computed in the painter alone, which is exactly
  /// how a drawn box and a scanned region come apart.
  ///
  /// Clamped to the preview: a 300-point window asked for on a
  /// 200-point card would otherwise hang off both sides, and the
  /// plugin refuses a scan window that leaves the picture.
  Rect viewfinderRect(Size size) {
    if (size.isEmpty) return Rect.zero;

    final pinned = viewfinderSize;
    double w;
    double h;
    if (pinned != null) {
      w = pinned.width;
      h = pinned.height;
    } else {
      // Off the SHORT side, both ways up: a window sized off the long
      // one is taller than a landscape phone, which is how a fixed
      // 260-point square ended up clamped to the full height of a
      // rotated screen.
      final short = math.min(size.width, size.height);
      h = short * viewfinderFraction;
      w = h * viewfinderAspect;
      // A wide window on a narrow screen is bounded by the WIDTH, and
      // shrinking only one side would change the shape the reader is
      // asked to line up with.
      if (w > size.width) {
        final scale = size.width / w;
        w = size.width;
        h *= scale;
      }
    }

    w = w.clamp(0.0, size.width);
    h = h.clamp(0.0, size.height);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: w,
      height: h,
    );
  }

  /// A context-free bag, for the moment before the theme is readable.
  ///
  /// The camera controller is built in `initState` and the scan window
  /// is derived from this — resolving needs the inherited theme, which
  /// is only there from `didChangeDependencies`. A `late` field here
  /// would throw on the first frame, which is what the video module
  /// shipped once.
  static const ResolvedScannerStyle fallback = ResolvedScannerStyle(
    viewfinderColor: Colors.white,
    successColor: Colors.white,
    viewfinderFraction: ScannerDefaults.viewfinderFraction,
    viewfinderAspect: ScannerDefaults.viewfinderAspect,
    cornerLength: ScannerDefaults.cornerLength,
    cornerWidth: ScannerDefaults.cornerWidth,
    cornerRadius: ScannerDefaults.cornerRadius,
    dimColor: ScannerDefaults.dimColor,
    controlsColor: Colors.white,
    controlScrim: ScannerDefaults.controlScrim,
    controlSize: ScannerDefaults.controlSize,
    showTorch: true,
    showFlip: true,
    showZoom: true,
    showScanLine: true,
    showSuccessFlash: true,
    restrictToViewfinder: true,
    enableHaptic: true,
    enablePinchZoom: true,
    tapToFocus: true,
    autoZoom: false,
    invertImage: false,
    detectionSpeed: ScannerDetectionSpeed.noDuplicates,
    detectionTimeout: ScannerDefaults.detectionTimeout,
  );
}

/// What the scanner DOES with a read, and what the controls can do.
///
/// Pure, because `GlobalScanner` cannot be built under `flutter_test`
/// at all — it wants a camera — so anything left inside the state has
/// no coverage of any kind.
abstract final class ScannerCapture {
  /// What a detection means.
  ///
  /// [accepted] is the caller's `validate` having its say. It comes
  /// FIRST: a code this scanner does not want is not a read at all,
  /// whatever the mode would have done with one.
  static ScannerCaptureAction decide({
    required ScannerCaptureMode mode,
    required bool hasPending,
    required bool alreadyReported,
    bool accepted = true,
  }) {
    if (!accepted) return ScannerCaptureAction.reject;
    switch (mode) {
      case ScannerCaptureMode.continuous:
        return ScannerCaptureAction.report;
      case ScannerCaptureMode.single:
        // The camera keeps reading for as long as it takes the route
        // to pop, and `noDuplicates` only suppresses the SAME code —
        // a second code in frame reported a second result over the
        // first one's head.
        return alreadyReported
            ? ScannerCaptureAction.ignore
            : ScannerCaptureAction.reportAndStop;
      case ScannerCaptureMode.manual:
        return hasPending
            ? ScannerCaptureAction.ignore
            : ScannerCaptureAction.hold;
    }
  }

  /// Which of several codes in one frame the reader MEANT.
  ///
  /// `barcodes.first` is whatever the detector happened to list first,
  /// which is arbitrary the moment two codes are visible — a sheet of
  /// labels, a poster behind the one being scanned. The one nearest
  /// the middle of the window is the one being aimed at.
  ///
  /// A barcode with no corners (the web reports none) cannot be
  /// placed, so it keeps its listed order behind everything that can.
  static Barcode? pickNearest(List<Barcode> barcodes, Rect window) {
    if (barcodes.isEmpty) return null;
    if (barcodes.length == 1) return barcodes.first;

    final target = window.center;
    Barcode? best;
    var bestDistance = double.infinity;
    for (final b in barcodes) {
      final centre = centreOf(b);
      if (centre == null) continue;
      final d = (centre - target).distanceSquared;
      if (d < bestDistance) {
        bestDistance = d;
        best = b;
      }
    }
    return best ?? barcodes.first;
  }

  /// The middle of a barcode's corner box, or null when it has none.
  @visibleForTesting
  static Offset? centreOf(Barcode barcode) {
    final corners = barcode.corners;
    if (corners.isEmpty) return null;
    var x = 0.0;
    var y = 0.0;
    for (final c in corners) {
      x += c.dx;
      y += c.dy;
    }
    return Offset(x / corners.length, y / corners.length);
  }

  /// Whether the torch control can do anything.
  ///
  /// A front camera has no torch on most phones, and a control that
  /// does nothing when pressed is worse than one that is not there.
  static bool torchUsable(TorchState state) => state != TorchState.unavailable;

  /// Whether there is a second camera to flip TO.
  ///
  /// The plugin reports null until it has started, and a control that
  /// appears a beat later is worse than one that was always there —
  /// so an unknown count is taken as "yes", which is true of every
  /// phone.
  static bool flipUsable(int? availableCameras) =>
      availableCameras == null || availableCameras > 1;
}

/// Result returned by [GlobalScanner.scan]. Holds the raw plugin
/// barcode plus its decoded text for callers that don't want to crack
/// the plugin's type open.
@immutable
class ScannerResult {
  const ScannerResult({
    required this.value,
    required this.format,
    required this.barcode,
  });

  /// Decoded text — UTF-8 string for QR / most barcodes. Empty when
  /// the plugin couldn't decode.
  final String value;

  /// Detected format (QR / EAN-13 / etc).
  final BarcodeFormat format;

  /// Raw plugin barcode for callers that need bytes / corner points.
  final Barcode barcode;
}
