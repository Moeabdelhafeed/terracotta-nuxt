import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/enums/app/log_level.dart';
import '../../../../core/crash_reporting/crash_reporter.dart';
import '../../../../core/error/error_storm.dart';
import '../../../../core/utils/loggers/logger.dart';
import '../../toast/global_toast.dart';
import '../global_debug_overlay.dart';
import '../widgets/debug_surfaces.dart';

/// Crash + log pipeline tester. Devs verify the reporting chain end-to-
/// end without writing throwaway code: every log level, locally-caught
/// throw flavors, REAL uncaught throws that exercise the global
/// handlers installed in bootstrap, and the [CrashReporter] facade.
class DebugCrashInjectorView extends StatelessWidget {
  const DebugCrashInjectorView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        const _Banner(),
        const SizedBox(height: 14),
        _Section(
          title: 'Log levels',
          icon: Icons.terminal_rounded,
          child: _TileGroup(
            children: [
              for (final level in LogLevel.values)
                _ActionTile(
                  color: DebugOverlayTheme.levelColor(level),
                  icon: _iconFor(level),
                  label: 'Logger.m.${_methodFor(level)}(...)',
                  description: 'Emit a synthetic ${level.name} entry',
                  onTap: () {
                    _emitLog(level);
                    GlobalToast.info('${level.name} emitted — check Logs');
                  },
                ),
            ],
          ),
        ),
        const _Section(
          title: 'Caught locally',
          icon: Icons.security_rounded,
          caption:
              'Wrapped in try/catch at the call site — the error is '
              'logged, global handlers never see it.',
          child: _TileGroup(
            children: [
              _ActionTile(
                color: Color(0xFFFFA726),
                icon: Icons.bolt_rounded,
                label: 'Sync throw',
                description: 'throw → catch → Logger.m.e',
                onTap: _throwSync,
              ),
              _ActionTile(
                color: Color(0xFFFFA726),
                icon: Icons.flash_on_rounded,
                label: 'Async throw',
                description: 'Awaited future completes with error → caught',
                onTap: _throwAsync,
              ),
              _ActionTile(
                color: Color(0xFFFFA726),
                icon: Icons.shield_moon_rounded,
                label: 'Zone-guarded throw',
                description: 'Local runZonedGuarded catches the microtask',
                onTap: _throwInZone,
              ),
            ],
          ),
        ),
        _Section(
          title: 'Uncaught — real pipeline',
          icon: Icons.local_fire_department_rounded,
          caption:
              'Nothing catches these. They must land in the handlers '
              'bootstrap installed (GlobalErrorHandler → CrashReporter). '
              'App stays up — the handlers absorb them.',
          child: _TileGroup(
            children: [
              _ActionTile(
                color: const Color(0xFFEF5350),
                icon: Icons.cloud_upload_rounded,
                label: 'Unhandled async throw',
                description: 'Unawaited future → PlatformDispatcher.onError',
                onTap: () {
                  Logger.m.i('[CrashInjector] firing UNHANDLED async throw…');
                  // Deliberately unawaited + unguarded: must surface via the
                  // root-zone / PlatformDispatcher error handler.
                  unawaited(
                    Future<void>.delayed(
                      const Duration(milliseconds: 50),
                    ).then(
                      (_) => throw StateError(
                        'synthetic UNHANDLED async throw — crash injector',
                      ),
                    ),
                  );
                  GlobalToast.info(
                    'Unhandled throw scheduled',
                    description: 'Watch Logs for the global handler entry',
                  );
                },
              ),
              const _ActionTile(
                color: Color(0xFFEF5350),
                icon: Icons.flutter_dash_rounded,
                label: 'FlutterError.reportError(...)',
                description: 'Framework sink → FlutterError.onError',
                onTap: _reportFlutterError,
              ),
            ],
          ),
        ),
        _Section(
          title: 'Crash reporter',
          icon: Icons.cloud_upload_rounded,
          child: _TileGroup(
            children: [
              _ActionTile(
                color: DebugOverlayTheme.accent,
                icon: Icons.report_rounded,
                label: 'CrashReporter.recordError(...)',
                description: 'Direct non-fatal to the reporter facade',
                onTap: () async {
                  await _recordError();
                  GlobalToast.info('recordError sent');
                },
              ),
              _ActionTile(
                color: DebugOverlayTheme.accent,
                icon: Icons.edit_note_rounded,
                label: 'CrashReporter.log(...)',
                description: 'Breadcrumb attached to the next report',
                onTap: () async {
                  await CrashReporter.log(
                    '[CrashInjector] synthetic breadcrumb '
                    '${DateTime.now().toIso8601String()}',
                  );
                  GlobalToast.info('Breadcrumb logged');
                },
              ),
              _ActionTile(
                color: const Color(0xFFEF5350),
                icon: Icons.dangerous_rounded,
                label: 'CrashReporter.crash()',
                description:
                    'Native test crash — KILLS the app '
                    '(no-op unless Crashlytics is registered)',
                onTap: () => _confirmNativeCrash(context),
              ),
            ],
          ),
        ),
        const _Section(
          title: 'Storm folding',
          icon: Icons.filter_alt_rounded,
          caption:
              'A build/layout error repeats every FRAME. ErrorStorm '
              'prints the first few, then counts the rest — otherwise the '
              'first (readable) copy scrolls away and the log ring is '
              'wiped. Fire the storm and watch Logs stay usable.',
          child: _StormPanel(),
        ),
        // Jump to the trail every action leaves behind.
        _LinkTile(
          icon: Icons.receipt_long_rounded,
          label: 'Open Logs',
          description: 'Every injector action prints a [CrashInjector] entry',
          onTap: () => DebugOverlayController.openTool(DevTool.logs),
        ),
      ],
    );
  }

  // ─── Log emitters ─────────────────────────────────────────

  static void _emitLog(LogLevel level) {
    final msg =
        '[CrashInjector] synthetic ${level.name} at '
        '${DateTime.now().toIso8601String()}';
    final err = level.index >= LogLevel.error.index
        ? Exception('synthetic-${level.name}')
        : null;
    final st = err == null ? null : StackTrace.current;
    switch (level) {
      case LogLevel.trace:
        Logger.m.t(msg);
      case LogLevel.debug:
        Logger.m.d(msg);
      case LogLevel.info:
        Logger.m.i(msg);
      case LogLevel.warning:
        Logger.m.w(msg, error: err, stackTrace: st);
      case LogLevel.error:
        Logger.m.e(msg, error: err, stackTrace: st);
      case LogLevel.fatal:
        Logger.m.f(msg, error: err, stackTrace: st);
    }
  }

  // ─── Caught throws ────────────────────────────────────────

  static void _throwSync() {
    Logger.m.i('[CrashInjector] firing sync throw…');
    try {
      throw StateError('synthetic sync throw — debug crash injector');
    } catch (e, st) {
      Logger.m.e('[CrashInjector] sync caught', error: e, stackTrace: st);
    }
  }

  static Future<void> _throwAsync() async {
    Logger.m.i('[CrashInjector] firing async throw…');
    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      throw StateError('synthetic async throw — debug crash injector');
    } catch (e, st) {
      Logger.m.e('[CrashInjector] async caught', error: e, stackTrace: st);
    }
  }

  static void _throwInZone() {
    Logger.m.i('[CrashInjector] firing zone-guarded throw…');
    runZonedGuarded(
      () {
        Future<void>.microtask(() {
          throw StateError('synthetic zone throw — debug crash injector');
        });
      },
      (e, st) {
        Logger.m.e('[CrashInjector] zone caught', error: e, stackTrace: st);
      },
    );
  }

  // ─── Reporter ─────────────────────────────────────────────

  static Future<void> _recordError() async {
    Logger.m.i('[CrashInjector] CrashReporter.recordError…');
    try {
      throw StateError('synthetic recordError — debug crash injector');
    } catch (e, st) {
      await CrashReporter.recordError(
        e,
        stackTrace: st,
        reason: 'crash injector test',
      );
    }
  }

  static void _reportFlutterError() {
    Logger.m.i('[CrashInjector] FlutterError.reportError…');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('synthetic FlutterError — debug crash injector'),
        stack: StackTrace.current,
        library: 'crash_injector',
        context: ErrorDescription('Triggered from debug overlay'),
      ),
    );
  }

  static Future<void> _confirmNativeCrash(BuildContext context) async {
    final ok = await debugConfirmDialog(
      context,
      title: 'Kill the app?',
      body:
          'CrashReporter.crash() forces a native test crash so the report '
          'shows up in Crashlytics on the NEXT launch. With the no-op '
          'reporter (dev default) nothing happens.',
      confirmLabel: 'Crash it',
      destructive: true,
    );
    if (ok) {
      Logger.m.f('[CrashInjector] native test crash requested');
      await CrashReporter.crash();
      GlobalToast.info('No-op reporter — nothing crashed');
    }
  }

  // ─── Icon mapping ─────────────────────────────────────────

  static IconData _iconFor(LogLevel level) => switch (level) {
    LogLevel.trace => Icons.more_horiz_rounded,
    LogLevel.debug => Icons.bug_report_outlined,
    LogLevel.info => Icons.info_outline_rounded,
    LogLevel.warning => Icons.warning_amber_outlined,
    LogLevel.error => Icons.error_outline_rounded,
    LogLevel.fatal => Icons.local_fire_department_rounded,
  };

  static String _methodFor(LogLevel level) => switch (level) {
    LogLevel.trace => 't',
    LogLevel.debug => 'd',
    LogLevel.info => 'i',
    LogLevel.warning => 'w',
    LogLevel.error => 'e',
    LogLevel.fatal => 'f',
  };
}

// ─────────────────────────────────────────────────────────────
// UI primitives
// ─────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final color = DebugOverlayTheme.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Synthetic events for testing the logging + crash-reporting '
              'chain. Everything leaves a [CrashInjector] trail in Logs.',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.caption,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: DebugOverlayTheme.textDim),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.textDim,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 10,
                color: DebugOverlayTheme.textDimmer,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: DebugOverlayTheme.border.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String description;
  final FutureOr<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      description,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_arrow_rounded,
                size: 15,
                color: DebugOverlayTheme.textDimmer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live fold tally + a way to actually produce a storm.
///
/// The tally has to poll: folded occurrences deliberately never reach
/// the logger, so there is no stream to listen to — that IS the feature.
class _StormPanel extends StatefulWidget {
  const _StormPanel();

  @override
  State<_StormPanel> createState() => _StormPanelState();
}

class _StormPanelState extends State<_StormPanel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ErrorStorm.snapshot();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TileGroup(
          children: [
            _ActionTile(
              color: const Color(0xFFEF5350),
              icon: Icons.repeat_rounded,
              label: 'Fire 300 identical errors',
              description: 'Same exception + stack, as fast as possible',
              onTap: _storm,
            ),
            _ActionTile(
              color: DebugOverlayTheme.accent,
              icon: Icons.restart_alt_rounded,
              label: 'ErrorStorm.reset()',
              description: 'Forget every fingerprint — all print fully again',
              onTap: () {
                ErrorStorm.reset();
                setState(() {});
                GlobalToast.info('Fold state cleared');
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Text(
            'Nothing folded — no error has repeated.',
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 10,
              color: DebugOverlayTheme.textDimmer,
            ),
          )
        else
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 46,
                    child: Text(
                      '×${e.count}',
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF5350),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.label,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  void _storm() {
    Logger.m.i('[CrashInjector] firing a 300× error storm…');
    // One captured trace reused for every copy: a real per-frame error
    // throws from the same place each time, and the fold has to key on
    // that sameness.
    final stack = StackTrace.current;
    for (var i = 0; i < 300; i++) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: StateError('synthetic storm — crash injector'),
          stack: stack,
          library: 'crash_injector',
        ),
      );
    }
    setState(() {});
    GlobalToast.info('300 fired — check Logs, then this tally');
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DebugOverlayTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DebugOverlayTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: DebugOverlayTheme.accentDefault,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: DebugOverlayTheme.textDimmer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
