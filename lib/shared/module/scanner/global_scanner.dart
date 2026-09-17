import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/scanner_strings.dart';
import '../../../core/navigation/transitions/route_transition.dart';
import '../app_bar/global_app_bar.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../progress/global_progress.dart';
import 'scanner_controls.dart';
import 'scanner_models.dart';
import 'scanner_overlay.dart';
import 'theme/scanner_theme.dart';

export 'scanner_controls.dart';
export 'scanner_models.dart';
export 'scanner_overlay.dart';
export 'theme/scanner_theme.dart';

/// Drop-in QR / barcode scanner. Wraps [MobileScanner] with a
/// permission flow, a viewfinder, capture-mode logic, and a torch /
/// flip / zoom row.
///
/// Two entry points:
///   1. As a widget — `GlobalScanner(onScan: ...)` mounts it inside a
///      custom UI shell (part of a checkout screen, say).
///   2. As a route — `GlobalScanner.scan(context)` pushes a fullscreen
///      page and returns a [ScannerResult]? (null on cancel).
class GlobalScanner extends StatefulWidget {
  const GlobalScanner({
    super.key,
    required this.onScan,
    this.formats = const [ScannerFormat.any],
    this.captureMode = ScannerCaptureMode.continuous,
    this.style = const ScannerStyle(),
    this.confirmLabel,
    this.retryLabel,
    this.showHint = true,
    this.hintText,
    this.validate,
    this.onRejected,
    this.onPickImage,
    this.overlayBuilder,
  });

  /// Fires for every read in `continuous`, the first read in `single`,
  /// the confirmed read in `manual`. Always on the UI isolate.
  final ValueChanged<ScannerResult> onScan;

  /// Format whitelist. `[ScannerFormat.any]` means every format the
  /// plugin supports.
  final List<ScannerFormat> formats;

  final ScannerCaptureMode captureMode;

  /// How it looks. Layered `caller > GlobalScannerTheme >
  /// ScannerStyle.defaults` and resolved once per build.
  final ScannerStyle style;

  /// Copy for the manual mode's two buttons. On the WIDGET rather than
  /// in the bag: a label is what this particular scan is FOR, not how
  /// scanners in this app look.
  final String? confirmLabel;
  final String? retryLabel;

  /// The line under the viewfinder telling someone what to do with it.
  final bool showHint;

  /// What that line says. Null takes the module's own wording.
  final String? hintText;

  /// Whether this scanner WANTS the code it just read.
  ///
  /// Real flows accept only their own codes — a ticket prefix, a
  /// twelve-digit SKU, a URL on one host. Without this every stray QR
  /// in the room popped the route and the caller had to reopen it;
  /// with it a refused code is named on screen and the camera keeps
  /// looking, which is what the reader expected anyway.
  final bool Function(ScannerResult result)? validate;

  /// Fires for a code [validate] turned down, so an app can say
  /// something better than the module's own line.
  final ValueChanged<ScannerResult>? onRejected;

  /// Hands back the path of an image to read a code OUT of.
  ///
  /// A control appears only when this is given. The picker belongs to
  /// the app — `lib/shared/module` may not reach the media layer — but
  /// the DECODE belongs here, and without the seam a code that arrived
  /// as a screenshot or a saved ticket had no way in at all.
  final Future<String?> Function()? onPickImage;

  /// Drawn over the picture, given the viewfinder's rect.
  ///
  /// So a caller can put a line of their own under the window or a
  /// badge in its corner without guessing where it is.
  final Widget Function(BuildContext context, Rect viewfinder)? overlayBuilder;

  /// Push a fullscreen scanner page and resolve with the result. The
  /// page handles its own back button + cancel.
  static Future<ScannerResult?> scan(
    BuildContext context, {
    List<ScannerFormat> formats = const [ScannerFormat.any],
    ScannerCaptureMode captureMode = ScannerCaptureMode.single,
    ScannerStyle style = const ScannerStyle(),
    String? confirmLabel,
    String? retryLabel,
    String? hintText,
    bool Function(ScannerResult result)? validate,
    ValueChanged<ScannerResult>? onRejected,
    Future<String?> Function()? onPickImage,
  }) {
    return Navigator.of(context).push<ScannerResult>(
      RouteTransition.route<ScannerResult>(
        context: context,
        name: 'scanner',
        child: _ScannerRoute(
          formats: formats,
          captureMode: captureMode,
          style: style,
          confirmLabel: confirmLabel,
          retryLabel: retryLabel,
          hintText: hintText,
          validate: validate,
          onRejected: onRejected,
          onPickImage: onPickImage,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<GlobalScanner> createState() => _GlobalScannerState();
}

class _GlobalScannerState extends State<GlobalScanner>
    with WidgetsBindingObserver {
  // NOT final: a resync REPLACES it — see `_resync`.
  //
  // And not built in `initState` either. Half of what it is
  // constructed with — the detection speed, the timeout, auto-zoom —
  // comes from the RESOLVED bag, and resolving needs a theme that is
  // only there from `didChangeDependencies`. Built there, a caller's
  // detection settings were silently the floor's.
  MobileScannerController? _controllerOrNull;

  MobileScannerController get _controller =>
      _controllerOrNull ??= _buildController();

  /// Bumped per controller, and used as the preview's key.
  ///
  /// `MobileScanner` reads its controller ONCE, in `initState`, so a
  /// new one reaches it only by remounting the subtree.
  int _generation = 0;
  PermissionStatus? _permission;

  /// The resolved bag, held on the STATE because the lifecycle
  /// handlers and the scan window read it between builds.
  ///
  /// NOT `late`: the controller is built in `initState`, and resolving
  /// needs the inherited theme, which is only there from
  /// `didChangeDependencies`. That combination shipped broken in the
  /// video module and threw on every first frame.
  ResolvedScannerStyle _rs = ResolvedScannerStyle.fallback;

  /// Manual-mode pending capture — held until confirmed or dropped.
  ScannerResult? _pending;

  /// Whether `single` has already had its one result.
  bool _reported = false;

  /// The window last handed to the plugin, so an unchanged layout does
  /// not re-send it every frame.
  Rect? _scanWindow;

  /// Ours, because the controller's own `isStarting` is set only AFTER
  /// it has waited to be attached — up to half a second during which a
  /// second call sails past the guard and reaches the platform.
  bool _starting = false;

  /// Whether a resync is already in flight, so the error plate cannot
  /// start a loop of them.
  bool _resyncing = false;

  /// The code that was turned down — named on screen for
  /// [ScannerDefaults.rejectionLinger], then forgotten.
  String? _rejected;
  Timer? _rejectedTimer;

  /// Bumped on every accepted read. The viewfinder watches it and
  /// flashes; a counter rather than a bool because two reads in a row
  /// have to flash twice.
  int _acceptedCount = 0;

  /// Where a pinch started, in the camera's own 0..1 zoom.
  double _zoomAtPinchStart = 0;

  /// How many resyncs this widget has started BY ITSELF.
  ///
  /// Capped at one. A recovery that keeps failing is a spinner for
  /// ever, and after the first attempt the honest thing is to show
  /// what went wrong and let a person decide. Pressing the retry
  /// resets it — that IS a person deciding.
  int _autoResyncs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkPermission());
  }

  MobileScannerController _buildController() => MobileScannerController(
    // An EMPTY list means "no restriction" to the plugin, which is
    // what `any` asks for — and a list holding `any` beside three
    // real formats used to silently become those three.
    formats: ScannerFormat.isUnrestricted(widget.formats)
        ? const []
        : widget.formats
              .map((f) => f.pluginFormat)
              .whereType<BarcodeFormat>()
              .toList(growable: false),
    detectionSpeed: _rs.detectionSpeed.pluginSpeed,
    detectionTimeoutMs: _rs.detectionTimeout.inMilliseconds,
    autoZoom: _rs.autoZoom,
    invertImage: _rs.invertImage,
    cameraResolution: _rs.cameraResolution,
    // ONE starter. `MobileScanner` starts the controller it is given
    // whenever `autoStart` is on, and this state starts it too — on
    // the way back from the background, which the widget cannot do
    // for a controller it did not build. Both ran, the native side
    // answered the second with "the scanner was already started",
    // and that error landed on a camera that WAS running: an error
    // plate over a live preview, with the picture flashing through
    // whenever a new state rebuilt it.
    autoStart: false,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
  }

  @override
  void didUpdateWidget(covariant GlobalScanner old) {
    super.didUpdateWidget(old);
    if (old.style == widget.style && old.formats == widget.formats) return;
    final before = _rs;
    _rs = widget.style.resolve(context);
    // Most of the bag is read per frame and needs nothing. These five
    // are CONSTRUCTOR arguments of the controller, so changing one
    // means building another — otherwise a caller who switched
    // detection speed watched nothing happen.
    final cameraChanged =
        before.detectionSpeed != _rs.detectionSpeed ||
        before.detectionTimeout != _rs.detectionTimeout ||
        before.autoZoom != _rs.autoZoom ||
        before.invertImage != _rs.invertImage ||
        before.cameraResolution != _rs.cameraResolution ||
        old.formats != widget.formats;
    if (cameraChanged && _controllerOrNull != null) unawaited(_resync());
  }

  /// The camera is STOPPED on the way out and started again on the way
  /// back.
  ///
  /// `MobileScanner` only wires its own observer when it built the
  /// controller — pass one in, as this does, and the lifecycle is the
  /// caller's job. Nothing did it: a scanner left for the home screen
  /// came back to a frozen preview on Android, and held the camera
  /// open behind other apps in the meantime.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // The permission may have been flipped in OS settings while
        // the app was away, so this asks again before restarting.
        unawaited(_checkPermission(restart: true));
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rejectedTimer?.cancel();
    // The GETTER would build one just to throw it away.
    unawaited(_controllerOrNull?.dispose());
    super.dispose();
  }

  Future<void> _stop() async {
    final controller = _controllerOrNull;
    if (controller == null || !controller.value.isRunning) return;
    try {
      await controller.stop();
    } on Exception catch (_) {
      // Stopping something already stopping is not a failure worth
      // showing anyone.
    }
  }

  Future<void> _start() async {
    if (_starting || _controller.value.isRunning) return;
    _starting = true;
    try {
      await _controller.start();
    } on Exception catch (_) {
      // The controller reports the failure on its own value, which is
      // what the error plate is built from.
    } finally {
      _starting = false;
    }
  }

  /// Throws the camera away and builds a new one.
  ///
  /// Stopping is NOT enough, and that is the whole reason this exists:
  /// `MobileScannerController.stop` does nothing at all when its own
  /// state says the camera is not running — which is exactly the state
  /// it is in after "already started". The native scanner keeps
  /// running, the next start is refused for the same reason, and the
  /// retry button spins for ever.
  ///
  /// `dispose` is the one call that reaches the platform
  /// unconditionally. So the controller is replaced: dispose the old
  /// one, build another, remount the preview under a new key — because
  /// `MobileScanner` reads its controller once, in `initState`, and
  /// would otherwise keep talking to the dead one.
  Future<void> _resync() async {
    if (_resyncing || !mounted) return;
    _resyncing = true;
    final old = _controllerOrNull;
    try {
      // The new controller goes in FIRST, so the preview unmounts from
      // the old one before it is disposed.
      setState(() {
        _controllerOrNull = _buildController();
        _generation++;
        // Belongs to the controller that is going away; the new one
        // has never been told about a window.
        _scanWindow = null;
        _starting = false;
      });
      await old?.dispose();
      if (!mounted) return;
      await _start();
    } finally {
      _resyncing = false;
    }
  }

  Future<void> _checkPermission({bool restart = false}) async {
    if (kIsWeb) {
      // mobile_scanner handles its own browser prompt on web; treat as
      // granted so the preview mounts and the browser does the ask.
      if (mounted) setState(() => _permission = PermissionStatus.granted);
      return;
    }
    var status = await Permission.camera.status;
    if (!mounted) return;
    if (!status.isGranted && !status.isLimited && !status.isProvisional) {
      status = await Permission.camera.request();
      if (!mounted) return;
    }
    setState(() => _permission = status);
    // The camera is started HERE, whatever brought us here: nothing
    // else does it now, and a granted permission is the moment it
    // becomes possible.
    if (status.isGranted || status.isLimited || status.isProvisional) {
      await _start();
    }
  }

  /// Pushes the viewfinder's rect to the plugin as the SCAN WINDOW.
  ///
  /// Same rect the box is drawn from, so what is shown and what is
  /// read cannot drift. Without it the whole frame is scanned and the
  /// box is decoration that lies — a code well outside it reads, and
  /// the reader is told they aimed.
  void _syncScanWindow(Size size) {
    if (!_rs.restrictToViewfinder) {
      if (_scanWindow != null) {
        _scanWindow = null;
        unawaited(_controller.updateScanWindow(null));
      }
      return;
    }
    final rect = _rs.viewfinderRect(size);
    if (rect == _scanWindow) return;
    _scanWindow = rect;
    unawaited(_controller.updateScanWindow(rect));
  }

  void _onDetect(BarcodeCapture capture) {
    // Which of several the reader MEANT — `first` is whatever the
    // detector happened to list first, and that is arbitrary the
    // moment two codes are in frame.
    final barcode = ScannerCapture.pickNearest(
      capture.barcodes,
      _scanWindow ?? Rect.zero,
    );
    if (barcode == null) return;
    _handle(
      ScannerResult(
        value: barcode.rawValue ?? '',
        format: barcode.format,
        barcode: barcode,
      ),
    );
  }

  /// One path for a code, wherever it came from — the camera, or an
  /// image the reader picked.
  void _handle(ScannerResult result) {
    switch (ScannerCapture.decide(
      mode: widget.captureMode,
      hasPending: _pending != null,
      alreadyReported: _reported,
      accepted: widget.validate?.call(result) ?? true,
    )) {
      case ScannerCaptureAction.ignore:
        return;
      case ScannerCaptureAction.reject:
        _reject(result);
      case ScannerCaptureAction.report:
        _accept();
        widget.onScan(result);
      case ScannerCaptureAction.reportAndStop:
        _reported = true;
        _accept();
        // Stopped BEFORE the callback: the caller usually pops the
        // route, and a camera still reading during that pop reports
        // again into a widget on its way out.
        unawaited(_stop());
        widget.onScan(result);
      case ScannerCaptureAction.hold:
        _accept();
        setState(() => _pending = result);
    }
  }

  /// Marks a code the scanner took: a tick, and a flash of the
  /// brackets.
  void _accept() {
    _tick();
    if (!mounted) return;
    setState(() {
      _acceptedCount++;
      _rejected = null;
    });
    _rejectedTimer?.cancel();
  }

  /// Says so, and keeps looking.
  ///
  /// Not a haptic and not a flash — those mean "that worked". The line
  /// clears itself, because a refusal that stayed on screen would
  /// still be there over the code that IS accepted a second later.
  void _reject(ScannerResult result) {
    widget.onRejected?.call(result);
    if (!mounted) return;
    setState(() => _rejected = ScannerStrings.rejected);
    _rejectedTimer?.cancel();
    _rejectedTimer = Timer(ScannerDefaults.rejectionLinger, () {
      if (mounted) setState(() => _rejected = null);
    });
  }

  /// Reads a code out of a picture the app handed back.
  ///
  /// The picker belongs to the app — this module may not reach the
  /// media layer — but the DECODE belongs here, beside the formats
  /// the caller already chose.
  Future<void> _scanImage() async {
    final path = await widget.onPickImage?.call();
    if (path == null || !mounted) return;
    BarcodeCapture? capture;
    try {
      capture = await _controller.analyzeImage(
        path,
        formats: ScannerFormat.isUnrestricted(widget.formats)
            ? const []
            : widget.formats
                  .map((f) => f.pluginFormat)
                  .whereType<BarcodeFormat>()
                  .toList(growable: false),
      );
    } on Exception catch (_) {
      capture = null;
    }
    if (!mounted) return;
    final barcode = capture?.barcodes.firstOrNull;
    if (barcode == null) {
      // Same line as a refusal, and the same reason: it is a thing
      // that did not work, said where the reader is looking.
      setState(() => _rejected = ScannerStrings.imageNoCode);
      _rejectedTimer?.cancel();
      _rejectedTimer = Timer(ScannerDefaults.rejectionLinger, () {
        if (mounted) setState(() => _rejected = null);
      });
      return;
    }
    _handle(
      ScannerResult(
        value: barcode.rawValue ?? '',
        format: barcode.format,
        barcode: barcode,
      ),
    );
  }

  void _onPinchStart(ScaleStartDetails _) {
    _zoomAtPinchStart = _controller.value.zoomScale;
  }

  /// A pinch is a RATIO around 1; the camera's zoom is 0..1.
  ///
  /// Measured on a phone, a full two-finger spread is about 2.5x, and
  /// mapping that onto the whole range makes small corrections
  /// impossible — so half the range per spread, and a second spread
  /// reaches the end.
  void _onPinchUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    final next =
        _zoomAtPinchStart +
        (details.scale - 1) * ScannerDefaults.pinchSensitivity;
    unawaited(_controller.setZoomScale(next.clamp(0.0, 1.0)));
  }

  /// The only feedback there is that a code was read — the screen is
  /// usually about to close, and the picture it was showing is gone
  /// before anyone has read anything.
  void _tick() {
    if (_rs.enableHaptic) unawaited(HapticFeedback.selectionClick());
  }

  void _confirmPending() {
    final r = _pending;
    if (r == null) return;
    setState(() => _pending = null);
    widget.onScan(r);
  }

  void _retryPending() => setState(() => _pending = null);

  @override
  Widget build(BuildContext context) {
    final perm = _permission;
    if (perm == null) return const _LoadingState();
    if (perm.isPermanentlyDenied) return const _DeniedState(blocked: true);
    if (perm.isDenied || perm.isRestricted) {
      return const _DeniedState(blocked: false);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // In layout, not in `build` above it: the window is a fraction
        // of the PREVIEW, and a scanner in a card is not the size of
        // one on a page.
        _syncScanWindow(constraints.biggest);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Pinch to zoom, over the preview and UNDER the chrome —
            // the first gesture anyone tries on a camera, and the
            // slider was the only way in. A scale recogniser claims
            // nothing until the fingers move, so the plugin's own
            // tap-to-focus still gets its taps.
            GestureDetector(
              onScaleStart: _rs.enablePinchZoom ? _onPinchStart : null,
              onScaleUpdate: _rs.enablePinchZoom ? _onPinchUpdate : null,
              child: MobileScanner(
                // Keyed BY GENERATION, and distinctly from the chrome
                // beside it: two siblings of one `Stack` carrying the
                // same key is a duplicate-key throw, which is what the
                // bare `ValueKey(_generation)` on both was.
                key: ValueKey('scanner-preview-$_generation'),
                controller: _controller,
                onDetect: _onDetect,
                tapToFocus: _rs.tapToFocus,
                scanWindow: _scanWindow,
                errorBuilder: (context, error) {
                  // "Already started" is not a broken camera — it is
                  // this side and the platform disagreeing about whether
                  // one is running. It gets ONE silent recovery; after
                  // that the plate says what happened, because a
                  // recovery that keeps failing is a spinner for ever.
                  final recoverable =
                      error.errorCode ==
                      MobileScannerErrorCode.controllerAlreadyInitialized;
                  if (recoverable && _autoResyncs < 1) {
                    _autoResyncs++;
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => unawaited(_resync()),
                    );
                    return const _LoadingState();
                  }
                  return _ErrorState(
                    error: error,
                    onRetry: () {
                      // A person pressed it, so the automatic budget
                      // is theirs again.
                      _autoResyncs = 0;
                      unawaited(_resync());
                    },
                  );
                },
                placeholderBuilder: (_) => const _LoadingState(),
              ),
            ),
            // The CAMERA's state drives the chrome. Three local flags
            // used to mirror it, and a mirror is wrong whenever the
            // platform refuses.
            ValueListenableBuilder<MobileScannerState>(
              // Keyed too: a new controller is a new listenable, and
              // the builder must not go on listening to the old one.
              key: ValueKey('scanner-chrome-$_generation'),
              valueListenable: _controller,
              builder: (context, state, _) {
                // Nothing is drawn over a camera that is not there yet.
                // A viewfinder and a full control row on top of the
                // warm-up spinner read as a scanner that has started
                // and is refusing to see anything — and the torch
                // button, pressed then, does nothing.
                if (!state.isInitialized || state.error != null) {
                  return const SizedBox.shrink();
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ScannerViewfinder(
                      style: _rs,
                      acceptedCount: _acceptedCount,
                    ),
                    if (widget.showHint || _rejected != null)
                      _Hint(
                        style: _rs,
                        // A refusal REPLACES the instruction rather
                        // than stacking under it: two lines of white
                        // text under a viewfinder is a paragraph
                        // nobody reads mid-scan.
                        text:
                            _rejected ?? widget.hintText ?? ScannerStrings.hint,
                        alert: _rejected != null,
                      ),
                    if (widget.overlayBuilder != null)
                      widget.overlayBuilder!(
                        context,
                        _rs.viewfinderRect(constraints.biggest),
                      ),
                    if (_pending != null)
                      ScannerPendingPlate(
                        result: _pending!,
                        style: _rs,
                        confirmLabel: widget.confirmLabel,
                        retryLabel: widget.retryLabel,
                        onConfirm: _confirmPending,
                        onRetry: _retryPending,
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: ScannerControlRow(
                          style: _rs,
                          state: state,
                          onTorch: () => unawaited(_controller.toggleTorch()),
                          onFlip: () => unawaited(_controller.switchCamera()),
                          onZoom: (v) => unawaited(_controller.setZoomScale(v)),
                          // Only when an app has a picker to offer. A
                          // control for something that cannot happen
                          // is a control that lies.
                          onPickImage: widget.onPickImage == null
                              ? null
                              : () => unawaited(_scanImage()),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Fullscreen route shell
// ─────────────────────────────────────────────────────────────

class _ScannerRoute extends StatelessWidget {
  const _ScannerRoute({
    required this.formats,
    required this.captureMode,
    required this.style,
    this.confirmLabel,
    this.retryLabel,
    this.hintText,
    this.validate,
    this.onRejected,
    this.onPickImage,
  });

  final List<ScannerFormat> formats;
  final ScannerCaptureMode captureMode;
  final ScannerStyle style;
  final String? confirmLabel;
  final String? retryLabel;
  final String? hintText;
  final bool Function(ScannerResult result)? validate;
  final ValueChanged<ScannerResult>? onRejected;
  final Future<String?> Function()? onPickImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      // `GlobalAppBar`, not Material's. Every other page in the app
      // wears this one, and a raw `AppBar` here wrote its own title
      // style — so the one screen pushed over everything else was the
      // one screen that ignored the app's typography and its bar
      // theme.
      //
      // `transparent` is the variant that HAS no surface: it resolves
      // to a transparent background and white foreground whatever the
      // palette says, which is what a bar floating on a camera picture
      // needs.
      appBar: GlobalAppBar(
        title: ScannerStrings.title,
        variant: AppBarVariant.transparent,
        // A close, not a back arrow — this is a fullscreen dialog, and
        // the gesture that dismisses it is a dismissal rather than a
        // step backwards.
        leading: GlobalIconButton(
          iconData: Icons.close_rounded,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: CommonStrings.close,
          semanticLabel: CommonStrings.close,
          style: const ButtonStateStyle(foregroundColor: Colors.white),
        ),
      ),
      body: GlobalScanner(
        formats: formats,
        captureMode: captureMode,
        style: style,
        confirmLabel: confirmLabel,
        retryLabel: retryLabel,
        hintText: hintText,
        validate: validate,
        onRejected: onRejected,
        onPickImage: onPickImage,
        onScan: (r) => Navigator.of(context).pop(r),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────

class _Hint extends StatelessWidget {
  const _Hint({
    required this.style,
    required this.text,
    required this.alert,
  });

  final ResolvedScannerStyle style;
  final String text;

  /// A refusal rather than an instruction — it announces itself, and
  /// wears the accent so it does not read as more of the same advice.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rect = style.viewfinderRect(size);
    return Positioned(
      top: rect.bottom + ScannerDefaults.gapLg,
      left: ScannerDefaults.pendingInset,
      right: ScannerDefaults.pendingInset,
      child: Semantics(
        liveRegion: alert,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: alert
                ? style.viewfinderColor
                : style.controlsColor.withValues(alpha: 0.85),
            fontSize: context.textTheme.bodyMedium?.fontSize,
            fontWeight: alert ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: GlobalProgress.loading(
          type: ProgressType.circular,
          style: const ProgressStyle(color: Colors.white),
        ),
      ),
    );
  }
}

/// The camera refused to start.
///
/// Distinct from a refused PERMISSION, which is the reader's decision
/// and has its own plate. This one is a camera held by another app, a
/// simulator with none, or a driver that failed — all of which are
/// worth a retry rather than a dead screen.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _BlackPlate(
    icon: Icons.videocam_off_rounded,
    title: ScannerStrings.cameraFailed,
    message: error.errorDetails?.message ?? ScannerStrings.cameraFailedHint,
    actionLabel: ScannerStrings.retry,
    actionIcon: Icons.refresh_rounded,
    onAction: onRetry,
  );
}

class _DeniedState extends StatelessWidget {
  const _DeniedState({required this.blocked});

  /// Permanently denied — the OS will not ask again, so the only way
  /// back is Settings.
  final bool blocked;

  @override
  Widget build(BuildContext context) => _BlackPlate(
    icon: Icons.no_photography_rounded,
    title: blocked
        ? ScannerStrings.cameraAccessBlocked
        : ScannerStrings.cameraPermissionRequired,
    message: blocked
        ? ScannerStrings.openSettingsHint
        : ScannerStrings.allowCameraHint,
    actionLabel: blocked
        ? ScannerStrings.openSettings
        : ScannerStrings.grantAccess,
    actionIcon: blocked ? Icons.settings_rounded : Icons.lock_open_rounded,
    onAction: blocked
        ? () => unawaited(openAppSettings())
        : () => unawaited(Permission.camera.request()),
  );
}

/// One plate for the two things that stop a scan before it starts.
///
/// They were the same twenty lines twice, which is how a fix to one of
/// them misses the other.
class _BlackPlate extends StatelessWidget {
  const _BlackPlate({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: ScannerDefaults.deniedPadding,
          child: Semantics(
            liveRegion: true,
            explicitChildNodes: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white70,
                  size: ScannerDefaults.deniedGlyphSize,
                ),
                const SizedBox(height: ScannerDefaults.gapLg),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: context.textTheme.bodyLarge?.fontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ScannerDefaults.gapSm),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: context.textTheme.bodySmall?.fontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ScannerDefaults.gapLg),
                GlobalFilledButton(
                  text: actionLabel,
                  onPressed: onAction,
                  icon: actionIcon,
                  shrinkWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
