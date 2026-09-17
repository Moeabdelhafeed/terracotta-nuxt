import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../navigation/go_router_config.dart';
import 'app_remount.dart';

/// Debug replacement for Flutter's red error box.
///
/// ## What is wrong with the default
///
/// `RenderErrorBox` takes **as much space as it is offered**. A widget
/// that fails halfway down a long page paints a red slab over
/// everything below it, so the one thing you need — which widget
/// actually broke — is the one thing you cannot see. And when the
/// failure is high enough to cover the page, there is nothing left to
/// tap: no back, no retry, and (in the hot-reload late-init case) no
/// recovery short of restarting the app.
///
/// ## What this does instead
///
/// - **Hugs its content.** Sizing to content is not enough on its own:
///   a failed widget often sits in a slot with TIGHT constraints (a
///   `SizedBox`, an `Expanded`, a fixed-height row), and nothing can
///   shrink below a tight constraint. So the panel is aligned to the
///   top-start inside whatever it is given and the leftover space is
///   left TRANSPARENT — the slot is still occupied, but it no longer
///   paints a red wall over the page.
/// - **Leads with the location.** `foo_page.dart:42` is the actionable
///   fact; the exception type is not. Location first, then the symbol,
///   then the message, then the type — plus the app frames that called
///   it, because the frame that threw is often not the guilty one.
/// - **Offers a way out**: copy the full report, pop the route, or
///   [AppRemount.remount] — which recreates every `State` below the
///   router and is the only thing that clears a late-init failure
///   without a restart.
///
/// Debug only. Release keeps the neutral placeholder, because none of
/// this is for users.
///
/// ## Constraints on this widget itself
///
/// It is inserted wherever the failure happened, which may be ABOVE
/// `MaterialApp` — so it may have no `Directionality`, no `MediaQuery`,
/// no `Theme` and no `Material` ancestor. Everything here is drawn with
/// primitives from `widgets.dart` and its own inherited widgets. Do not
/// reach for a Material widget in this file.
class DebugErrorWidget extends StatefulWidget {
  const DebugErrorWidget({required this.details, super.key});

  final FlutterErrorDetails details;

  static const _red = Color(0xFFE0483C);
  static const _redDeep = Color(0xFFB3261E);
  static const _bg = Color(0xFF241012);
  static const _fg = Color(0xFFFFE9E7);
  static const _dim = Color(0xFFD79E99);

  /// Below this height only a one-line marker fits.
  static const _tinyHeight = 56.0;

  /// Below this height the action row is dropped in favour of content.
  static const _compactHeight = 200.0;

  /// The panel stops growing here however much room it is offered —
  /// beyond this it is a wall again, which is the thing being fixed.
  static const _maxPanelHeight = 300.0;
  static const _maxPanelWidth = 460.0;

  /// Identifies the painted panel, as distinct from the slot it sits in.
  static const panelKey = Key('debug-error-panel');

  @override
  State<DebugErrorWidget> createState() => _DebugErrorWidgetState();
}

class _DebugErrorWidgetState extends State<DebugErrorWidget> {
  Timer? _copiedTimer;
  bool _copied = false;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 11,
          color: DebugErrorWidget._fg,
          decoration: TextDecoration.none,
          fontFamilyFallback: ['monospace'],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Unbounded is the dangerous direction: given infinity the
            // default box takes it. Fall back to a fixed budget.
            final height = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : DebugErrorWidget._compactHeight;
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : DebugErrorWidget._maxPanelWidth;

            if (height < DebugErrorWidget._tinyHeight || width < 150) {
              return _tiny(height, width);
            }

            // Align hands the panel LOOSE constraints even when this
            // widget was given tight ones, so it hugs its content and
            // the rest of the slot stays transparent instead of red.
            return Align(
              alignment: AlignmentDirectional.topStart,
              child: _panel(
                maxHeight: height < DebugErrorWidget._maxPanelHeight
                    ? height
                    : DebugErrorWidget._maxPanelHeight,
                maxWidth: width < DebugErrorWidget._maxPanelWidth
                    ? width
                    : DebugErrorWidget._maxPanelWidth,
                withActions: height >= DebugErrorWidget._compactHeight,
              ),
            );
          },
        ),
      ),
    );
  }

  // ── layouts ────────────────────────────────────────────────────────

  /// The slot is too small for anything but a marker — a list row, a
  /// chip, a fixed-height cell. Still tappable: a tap copies the whole
  /// report, which is what you wanted anyway.
  ///
  /// Styled as the panel's small sibling (dark fill, red border, text
  /// at the reading start) rather than a solid red bar. A slab of flat
  /// red among normal rows reads as "everything here is broken"; this
  /// reads as one broken row, which is the truth.
  Widget _tiny(double height, double width) {
    // Below this even the border and padding do not fit, so drop to a
    // bare bar rather than overflowing — an error box that itself
    // overflows is a second error on top of the first.
    final bare = height < 26;

    return GestureDetector(
      onTap: _copy,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: bare ? DebugErrorWidget._redDeep : DebugErrorWidget._bg,
          border: bare
              ? null
              : Border.all(color: DebugErrorWidget._red, width: 1.5),
          borderRadius: bare ? null : BorderRadius.circular(6),
        ),
        padding: EdgeInsetsDirectional.only(start: bare ? 4 : 6, end: 6),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            if (!bare) ...[
              Container(
                width: 14,
                height: 14,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DebugErrorWidget._red,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  '!',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                _copied ? 'copied' : (_location() ?? 'build failed'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: bare ? const Color(0xFFFFFFFF) : DebugErrorWidget._fg,
                ),
              ),
            ),
            if (!bare && width > 260)
              Text(
                _symbol() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: DebugErrorWidget._dim,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _panel({
    required double maxHeight,
    required double maxWidth,
    required bool withActions,
  }) {
    final widgetName = _culpritWidget();
    final trail = _appFrames().skip(1).take(2).toList();

    final panel = Container(
      // Keyed so a test can measure the PAINTED panel rather than the
      // slot, which is the whole distinction being made here.
      key: DebugErrorWidget.panelKey,
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: DebugErrorWidget._bg,
        border: Border.all(color: DebugErrorWidget._red, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _message(),
                    style: const TextStyle(fontSize: 11.5, height: 1.35),
                  ),
                  if (widgetName != null) ...[
                    const SizedBox(height: 8),
                    _label('widget'),
                    Text(widgetName, style: const TextStyle(fontSize: 10.5)),
                  ],
                  if (trail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    // The frame that threw is often not the frame that
                    // is wrong — the caller above it usually is.
                    _label('called from'),
                    for (final frame in trail)
                      Text(
                        '${frame.symbol}  ·  ${frame.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: DebugErrorWidget._dim,
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  _label(_meta()),
                ],
              ),
            ),
          ),
          if (withActions) _footer(),
        ],
      ),
    );

    // With no visible Copy button, the whole panel is the button.
    return withActions ? panel : GestureDetector(onTap: _copy, child: panel);
  }

  Widget _header() {
    final symbol = _symbol();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: const BoxDecoration(
        color: DebugErrorWidget._redDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // The location is the actionable fact, so it leads. Falls
            // back to the type only when no app frame was captured.
            _location() ?? widget.details.exception.runtimeType.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (symbol != null)
            Text(
              symbol,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFFFD4CF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Action(
                label: _copied ? 'Copied' : 'Copy',
                filled: true,
                onTap: _copy,
              ),
              const _Action(label: 'Remount', onTap: AppRemount.remount),
              if (_canPop()) _Action(label: 'Back', onTap: _pop),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Remount rebuilds every page from scratch — clears a stale '
            'State (late init), loses scroll and form state.',
            style: TextStyle(
              fontSize: 9,
              height: 1.3,
              color: DebugErrorWidget._dim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 8.5,
      color: DebugErrorWidget._dim,
      letterSpacing: 0.7,
      fontWeight: FontWeight.w700,
    ),
  );

  // ── content extraction ─────────────────────────────────────────────

  String _meta() {
    final library = widget.details.library;
    final type = widget.details.exception.runtimeType.toString();
    return library == null ? type : '$type · $library';
  }

  String _message() {
    final text = widget.details.exceptionAsString().trim();
    return text.isEmpty ? '(no message)' : text;
  }

  String? _location() =>
      _appFrames().isEmpty ? null : _appFrames().first.location;

  String? _symbol() => _appFrames().isEmpty ? null : _appFrames().first.symbol;

  List<_Frame>? _cachedFrames;

  /// Stack frames belonging to THIS app, in order.
  ///
  /// A framework stack is twenty frames of `framework.dart` before it
  /// reaches anything you wrote, and the frames you wrote are the whole
  /// answer to "what is causing this".
  List<_Frame> _appFrames() {
    final cached = _cachedFrames;
    if (cached != null) return cached;

    final frames = <_Frame>[];
    final stack = widget.details.stack?.toString();
    if (stack != null) {
      for (final line in stack.split('\n')) {
        final match = _framePattern.firstMatch(line);
        if (match == null) continue;
        frames.add(
          _Frame(
            symbol: match.group(1)!,
            // Basename only. The directory is noise beside a filename
            // that is unique in practice, and `file.dart:42` is what an
            // editor jump wants.
            location: match.group(2)!.split('/').last,
          ),
        );
        if (frames.length == 4) break;
      }
    }
    return _cachedFrames = frames;
  }

  static final RegExp _framePattern = RegExp(
    r'#\d+\s+(\S+)\s+\((package:terracotta/[^)]+)\)',
  );

  /// The framework's own "relevant error-causing widget" note, when it
  /// collected one.
  String? _culpritWidget() {
    final information = widget.details.informationCollector?.call();
    if (information == null) return null;
    for (final node in information) {
      final text = node.toString();
      if (text.contains('error-causing widget')) {
        return text.replaceFirst(RegExp(r'^.*widget was:\s*'), '').trim();
      }
    }
    return null;
  }

  String _report() {
    final buffer = StringBuffer()
      ..writeln(_meta())
      ..writeln(_message());
    final widgetName = _culpritWidget();
    if (widgetName != null) buffer.writeln('widget: $widgetName');
    final stack = widget.details.stack;
    if (stack != null) buffer.writeln(stack.toString());
    return buffer.toString();
  }

  void _copy() {
    unawaited(Clipboard.setData(ClipboardData(text: _report())));
    // A copy with no acknowledgement gets pressed three times.
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  // ── navigation, without a usable BuildContext ──────────────────────
  //
  // The context this widget is built with sits inside the subtree that
  // just failed, so it is not something to navigate from. The router is
  // reachable directly.

  bool _canPop() {
    try {
      return GoRouterConfig.router.canPop();
    } catch (_) {
      // Before the router exists (a failure during boot) there is
      // nothing to pop back to.
      return false;
    }
  }

  void _pop() {
    try {
      if (GoRouterConfig.router.canPop()) GoRouterConfig.router.pop();
    } catch (_) {
      // Nothing to do — the button simply does not work that early.
    }
  }
}

class _Frame {
  const _Frame({required this.symbol, required this.location});

  final String symbol;
  final String location;
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled
              ? DebugErrorWidget._red
              : DebugErrorWidget._red.withValues(alpha: 0.18),
          border: Border.all(color: DebugErrorWidget._red),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: filled ? const Color(0xFFFFFFFF) : DebugErrorWidget._fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
