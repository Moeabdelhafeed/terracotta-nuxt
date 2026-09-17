import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/utils/loggers/logger.dart';
import '../buttons/global_icon_button.dart';
import '../container/global_container.dart';
import '../progress/global_progress.dart';
import 'share_models.dart';
import 'theme/share_theme.dart';

// The package's own types appear in this module's API — `XFile` goes
// in, `ShareResult` comes out — so they are re-exported. Otherwise
// every caller has to import `share_plus` itself, which is the one
// thing the adoption guard forbids.
export 'package:share_plus/share_plus.dart'
    show ShareResult, ShareResultStatus, XFile;
export 'share_models.dart';
export 'theme/share_theme.dart';

/// Adopter-friendly wrapper around `share_plus`. Surface text, files,
/// or a URL through the OS share sheet (mobile) or desktop equivalent.
///
/// ```dart
/// // Static helpers — no widget needed:
/// await GlobalShare.text('Check out this app');
/// await GlobalShare.uri(Uri.parse('https://example.com'));
/// await GlobalShare.files([XFile('/tmp/report.pdf')], text: 'Latest report');
///
/// // Widget — drop in a settings row, app bar, or content card:
/// GlobalShareButton.tile(shareText: 'Look at this')
/// ```
///
/// Visual configuration is the themeable bag [ShareButtonStyle] —
/// `caller > GlobalShareTheme.style > ShareButtonStyle.defaults`. The
/// VARIANT is not part of it: which shape a share control takes is the
/// caller's decision, not a house's.
class GlobalShareButton extends StatefulWidget {
  const GlobalShareButton({
    super.key,
    this.shareText,
    this.shareSubject,
    this.shareUri,
    this.shareFiles,
    this.variant = ShareButtonVariant.icon,
    this.label,
    this.tooltip,
    this.heroTag,
    this.style = const ShareButtonStyle(),
    this.onShared,
    this.onError,
  }) : assert(
         shareText != null || shareUri != null || shareFiles != null,
         'GlobalShareButton needs at least one of shareText / shareUri / '
         'shareFiles.',
       );

  /// Icon-only. The default shape.
  const GlobalShareButton.icon({
    Key? key,
    String? shareText,
    String? shareSubject,
    Uri? shareUri,
    List<XFile>? shareFiles,
    String? label,
    String? tooltip,
    Object? heroTag,
    ShareButtonStyle style = const ShareButtonStyle(),
    ValueChanged<ShareResultStatus>? onShared,
    ValueChanged<Object>? onError,
  }) : this(
         key: key,
         shareText: shareText,
         shareSubject: shareSubject,
         shareUri: shareUri,
         shareFiles: shareFiles,
         label: label,
         tooltip: tooltip,
         heroTag: heroTag,
         style: style,
         onShared: onShared,
         onError: onError,
       );

  /// Floating action button.
  const GlobalShareButton.fab({
    Key? key,
    String? shareText,
    String? shareSubject,
    Uri? shareUri,
    List<XFile>? shareFiles,
    String? label,
    String? tooltip,
    Object? heroTag,
    ShareButtonStyle style = const ShareButtonStyle(),
    ValueChanged<ShareResultStatus>? onShared,
    ValueChanged<Object>? onError,
  }) : this(
         key: key,
         shareText: shareText,
         shareSubject: shareSubject,
         shareUri: shareUri,
         shareFiles: shareFiles,
         variant: ShareButtonVariant.fab,
         label: label,
         tooltip: tooltip,
         heroTag: heroTag,
         style: style,
         onShared: onShared,
         onError: onError,
       );

  /// A settings-row tile.
  const GlobalShareButton.tile({
    Key? key,
    String? shareText,
    String? shareSubject,
    Uri? shareUri,
    List<XFile>? shareFiles,
    String? label,
    String? tooltip,
    Object? heroTag,
    ShareButtonStyle style = const ShareButtonStyle(),
    ValueChanged<ShareResultStatus>? onShared,
    ValueChanged<Object>? onError,
  }) : this(
         key: key,
         shareText: shareText,
         shareSubject: shareSubject,
         shareUri: shareUri,
         shareFiles: shareFiles,
         variant: ShareButtonVariant.tile,
         label: label,
         tooltip: tooltip,
         heroTag: heroTag,
         style: style,
         onShared: onShared,
         onError: onError,
       );

  /// Body text passed to the share sheet.
  final String? shareText;

  /// Subject hint (used by mail apps as the email subject).
  final String? shareSubject;

  /// URL to share — preferred over [shareText] when sharing a link.
  final Uri? shareUri;

  /// File attachments. Pass `XFile` from `image_picker` / `file_picker`
  /// or construct directly from a local path.
  final List<XFile>? shareFiles;

  /// Which shape the control takes.
  final ShareButtonVariant variant;

  /// The tile's text, and the fallback tooltip. `null` renders the
  /// localized "Share".
  final String? label;

  /// Tooltip on hover / long-press. Falls back to [label].
  final String? tooltip;

  /// The FAB's hero tag. **Null by default, which turns the flight
  /// OFF.**
  ///
  /// Material gives every `FloatingActionButton` the same default tag,
  /// and two of them in one route is "multiple heroes share the same
  /// tag" — a red screen. A share button is a COMPONENT: a page can
  /// hold several, and a showcase certainly does. A flight is opt-in
  /// here, and the caller supplying a tag is the one who knows it is
  /// unique.
  final Object? heroTag;

  final ShareButtonStyle style;

  /// Fires after the share sheet closes with the user's result.
  /// `ShareResultStatus.success` = user picked a target;
  /// `.dismissed` = user cancelled; `.unavailable` = no share UI on
  /// platform.
  final ValueChanged<ShareResultStatus>? onShared;

  /// Fires if `share_plus` throws (e.g. file not found, platform
  /// error).
  ///
  /// Without one the failure goes to `FlutterError.reportError` — it
  /// used to be logged at WARNING and dropped, so a share that never
  /// happened looked exactly like one the reader cancelled.
  final ValueChanged<Object>? onError;

  @override
  State<GlobalShareButton> createState() => _GlobalShareButtonState();
}

class _GlobalShareButtonState extends State<GlobalShareButton> {
  /// True from the tap until the OS sheet has closed.
  ///
  /// Opening it is a platform round-trip, and on a cold channel it is
  /// long enough to look like nothing happened — so the reader taps
  /// again, and a second sheet queues behind the first.
  bool _busy = false;

  Future<void> _share(ResolvedShareButtonStyle rs) async {
    if (_busy) return;
    setState(() => _busy = true);
    // NOT awaited. The tick is feedback for the tap; the share sheet
    // is what the reader is waiting for, and holding one behind the
    // other puts a platform round-trip in front of every share.
    if (rs.enableHaptic) unawaited(HapticFeedback.selectionClick());
    // Resolve the iPad popover origin BEFORE awaiting — the render
    // object can be gone after async gaps.
    final origin = _sharePositionOrigin(context);
    try {
      final result = await GlobalShare.run(
        text: widget.shareText,
        subject: widget.shareSubject,
        uri: widget.shareUri,
        files: widget.shareFiles,
        sharePositionOrigin: origin,
      );
      if (result.status == ShareResultStatus.unavailable) {
        // Not an exception, and not a dismissal either: the platform
        // has no share UI at all. Say so once rather than reporting a
        // silent success.
        Logger.m.w('[Share] no share UI on this platform');
      }
      widget.onShared?.call(result.status);
    } catch (e, st) {
      Logger.m.w('[Share] failed', error: e, stackTrace: st);
      if (widget.onError != null) {
        widget.onError!(e);
        return;
      }
      // Never NOWHERE — the same call the refreshable makes for a
      // failed pull.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'global_share_button',
          context: ErrorDescription('sharing from a GlobalShareButton'),
        ),
      );
    } finally {
      // The sheet has closed, however it closed.
      if (mounted) setState(() => _busy = false);
    }
  }

  /// iPad needs a rect to anchor the share popover. Resolve from the
  /// tapped widget's render box.
  Rect? _sharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.style.resolve(context);
    final name = widget.label ?? CommonStrings.share;
    final hint = widget.tooltip ?? name;
    // The palette answers for the two flat variants. The FAB's is left
    // to Material, which fills it and picks a matching foreground —
    // forcing the primary in there put a primary glyph on a primary
    // fill, and the button painted as a solid coloured square.
    final flatForeground = rs.foregroundColor ?? context.primaryColors.primary;

    void onTap() {
      // Fire-and-forget the share future; outcome handled via
      // onShared / onError callbacks. Widget callbacks expect
      // VoidCallback, not Future-returning.
      _share(rs);
    }

    switch (widget.variant) {
      case ShareButtonVariant.icon:
        return GlobalIconButton(
          iconData: rs.icon,
          iconSize: rs.iconSize,
          style: ButtonStateStyle(foregroundColor: flatForeground),
          onPressed: onTap,
          isLoading: _busy,
          tooltip: hint,
        );
      case ShareButtonVariant.fab:
        // A FAB's glyph is decoration; the NAME belongs to the button.
        // Material gives it a tooltip and nothing else, so a screen
        // reader met an unlabelled control.
        // MERGED, not stacked: Material's FAB publishes its own node
        // with the button flag and the tap, and a `Semantics` wrapper
        // above it is a SECOND node — so the label sat on one and the
        // action on the other, and a reader focusing the button heard
        // nothing.
        return MergeSemantics(
          child: Semantics(
            label: name,
            child: FloatingActionButton(
              onPressed: _busy ? null : onTap,
              tooltip: hint,
              elevation: rs.fabElevation,
              foregroundColor: rs.foregroundColor,
              backgroundColor: rs.backgroundColor,
              // OFF unless a caller names one — Material's default tag
              // is shared by every FAB, and two in a route is a red
              // screen.
              heroTag: widget.heroTag,
              // `GlobalProgress`, not Material's raw indicator — the
              // adoption guard for that module caught this the first
              // time round.
              child: _busy
                  // The FAB sets an `IconTheme` for its child in
                  // whatever foreground it resolved — Material's
                  // `onPrimaryContainer`, or a caller's own. Reading
                  // that is how the spinner matches the glyph it
                  // replaced; a `GlobalProgress` left to its own
                  // default paints the PRIMARY, which on a primary
                  // container fill is invisible. Same trap the glyph
                  // itself fell into.
                  ? Builder(
                      builder: (ctx) => GlobalProgress(
                        type: ProgressType.circular,
                        style: ProgressStyle(
                          size: rs.iconSize,
                          indeterminate: true,
                          color: IconTheme.of(ctx).color,
                          // NO grace period. The app theme makes every
                          // spinner wait 300ms so fast work never
                          // flashes one — right for a page, wrong for a
                          // control that has already REPLACED its glyph
                          // with it: the button just sits empty for
                          // those 300ms, and an empty button is the
                          // flash that rule exists to prevent.
                          appearAfter: Duration.zero,
                        ),
                      ),
                    )
                  : Icon(rs.icon, size: rs.iconSize),
            ),
          ),
        );
      case ShareButtonVariant.tile:
        // `GlobalContainer.tile`, not `AppTile`: this is a PRIMITIVE
        // module and primitives never import `shared/common/`.
        return GlobalContainer.tile(
          leading: Icon(rs.icon, color: flatForeground),
          title: name,
          onTap: _busy ? null : onTap,
          enabled: !_busy,
          // The tile factory has no loading slot of its own, and the
          // TRAILING one is where a row shows work in this app.
          trailing: _busy
              ? GlobalProgress(
                  type: ProgressType.circular,
                  style: ProgressStyle(
                    size: rs.iconSize,
                    indeterminate: true,
                    // The tile sits on the page's own surface, so the
                    // spinner takes the same colour its glyph does.
                    color: flatForeground,
                    // Same reason as the FAB's: the row's trailing
                    // slot is empty until it appears.
                    appearAfter: Duration.zero,
                  ),
                )
              : null,
          semanticLabel: name,
          style: ContainerStyle(
            backgroundColor: rs.backgroundColor,
            shadow: const [],
          ),
        );
    }
  }
}

/// Static facade — call from anywhere (button onPress, swipe action,
/// menu item) without instantiating a widget.
///
/// ```dart
/// await GlobalShare.text('Hello world');
/// await GlobalShare.uri(Uri.parse('https://example.com'));
/// await GlobalShare.files([XFile(path)], text: 'My export');
/// ```
class GlobalShare {
  const GlobalShare._();

  /// Share plain text. Returns the resolved [ShareResult] from
  /// `share_plus`. Throws on platform failure.
  static Future<ShareResult> text(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) {
    return run(
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share a URL. Subject is appended as title metadata where the OS
  /// supports it (Android Direct Share, iOS mail subject).
  static Future<ShareResult> uri(
    Uri uri, {
    String? subject,
    Rect? sharePositionOrigin,
  }) {
    return run(
      uri: uri,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share one or more files. Accompanying [text] becomes the body /
  /// caption depending on the target app.
  static Future<ShareResult> files(
    List<XFile> files, {
    String? text,
    String? subject,
    Rect? sharePositionOrigin,
  }) {
    return run(
      files: files,
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// The share currently in flight, if any.
  ///
  /// The OS sheet is a SINGLE, app-wide resource: one is open or none
  /// is. Two share buttons each tracking their own "busy" flag cannot
  /// know that — press one, close the sheet, and press another before
  /// the first call has finished resolving, and `share_plus` is asked
  /// to share while it is still finishing. It answers the second call
  /// never, and that button spins for the rest of the session.
  static Future<ShareResult>? _inFlight;

  /// Whether a share is open or still settling.
  static bool get isSharing => _inFlight != null;

  /// How long a share may hang before it is given up on.
  ///
  /// A platform channel that never answers must not leave a control
  /// spinning forever. Generous, because the clock covers a human
  /// reading a share sheet, not a network call.
  static const timeout = Duration(minutes: 2);

  /// Test seam — replaces the platform call.
  ///
  /// `share_plus` resolves to a host implementation under
  /// `flutter_test` that answers nothing, so without this every test
  /// of what happens AFTER a share hangs forever.
  @visibleForTesting
  static Future<ShareResult> Function(ShareParams params)? debugRunner;

  /// Low-level entry — pass any combination of the supported payloads.
  /// Prefer the typed helpers above unless you need flexibility.
  ///
  /// Shares are SERIALIZED: called while one is in flight, this waits
  /// for it and then runs. Refusing outright would be simpler and
  /// wrong — the reader asked for a share sheet, and a tap that lands
  /// a moment early should still get one.
  static Future<ShareResult> run({
    String? text,
    String? subject,
    Uri? uri,
    List<XFile>? files,
    Rect? sharePositionOrigin,
  }) async {
    final pending = _inFlight;
    if (pending != null) {
      // Whatever it did — succeeded, was dismissed, threw — is not
      // this caller's business; it only has to be OVER.
      await pending.catchError(
        (_) => const ShareResult('', ShareResultStatus.dismissed),
      );
    }
    final future = _share(
      ShareParams(
        text: text,
        subject: subject,
        uri: uri,
        files: files,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    _inFlight = future;
    try {
      return await future;
    } finally {
      // Only if nothing has queued behind us.
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  static Future<ShareResult> _share(ShareParams params) {
    final runner = debugRunner;
    final future = runner != null
        ? runner(params)
        : SharePlus.instance.share(params);
    return future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'the share sheet never answered',
        timeout,
      ),
    );
  }
}
