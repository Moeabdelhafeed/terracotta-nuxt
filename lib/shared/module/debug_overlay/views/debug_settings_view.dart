import 'package:flutter/material.dart';

import '../../../../core/constants/enums/app/log_level.dart';
import '../../../../core/utils/loggers/log_buffer.dart';
import '../../../../core/utils/loggers/logger.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../drop_down/global_drop_down.dart';
import '../../text_field/text_field.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_switch.dart';
import '../widgets/debug_text_field.dart';

/// Logger configuration — live-edits `Logger.m`'s output format
/// (top-bar segments, colors, min level, env tag) and the in-memory
/// buffer size. The preview line at the top shows exactly what a log
/// will look like with the current knobs.
class DebugSettingsView extends StatefulWidget {
  const DebugSettingsView({super.key});

  @override
  State<DebugSettingsView> createState() => _DebugSettingsViewState();
}

class _DebugSettingsViewState extends State<DebugSettingsView> {
  late bool _colors;
  late bool _showSequence;
  late bool _showDelta;
  late bool _showSource;
  late bool _showBorders;
  late LogLevel _minLevel;
  late double _bufferSize;
  late double _lineLength;
  final _envCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFromLogger();
  }

  void _syncFromLogger() {
    final m = Logger.m;
    _colors = m.colors;
    _showSequence = m.showSequence;
    _showDelta = m.showDelta;
    _showSource = m.showSource;
    _showBorders = m.showBorders;
    _minLevel = m.minLevel;
    _envCtrl.text = m.environment ?? '';
    _bufferSize = LogBuffer.maxSize.toDouble();
    _lineLength = m.lineLength.toDouble();
  }

  @override
  void dispose() {
    _envCtrl.dispose();
    super.dispose();
  }

  /// Persist the current knobs so `initDi` re-applies them next boot.
  void _saveKnobs() {
    final env = _envCtrl.text.trim();
    DebugOverlayPrefs.saveLoggerConfig({
      'colors': _colors,
      'showSequence': _showSequence,
      'showDelta': _showDelta,
      'showSource': _showSource,
      'showBorders': _showBorders,
      'minLevel': _minLevel.name,
      if (env.isNotEmpty) 'environment': env,
      'bufferSize': _bufferSize.round(),
      'lineLength': _lineLength.round(),
    });
  }

  void _applyEnv(String v) {
    final trimmed = v.trim();
    final m = Logger.m;
    // configure() treats null as "keep current", which makes a blanked
    // field un-clearable — rebuild the full config so null sticks.
    Logger.configureWithConfig(
      LoggerConfig(
        colors: m.colors,
        errorMethodCount: m.errorMethodCount,
        methodCount: m.methodCount,
        lineLength: m.lineLength,
        minLevel: m.minLevel,
        environment: trimmed.isEmpty ? null : trimmed,
        showSequence: m.showSequence,
        showDelta: m.showDelta,
        showSource: m.showSource,
        showBorders: m.showBorders,
      ),
    );
    _saveKnobs();
    setState(() {});
  }

  void _emitTestLogs() {
    Logger.m
      ..t('[UiLab] trace sample')
      ..d('[UiLab] debug sample')
      ..i('[UiLab] info sample')
      ..w('[UiLab] warning sample')
      ..e('[UiLab] error sample')
      ..f('[UiLab] fatal sample');
    GlobalToast.info(
      'Six test logs emitted',
      description:
          'Levels below ${_minLevel.name.toUpperCase()} are suppressed',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        Text(
          'Configures Logger.m output — terminal, IDE console and the '
          'Logs tool all follow these knobs.',
          style: DebugOverlayTheme.ui.copyWith(
            fontSize: 10.5,
            color: DebugOverlayTheme.textDim,
          ),
        ),
        const SizedBox(height: 10),
        _PreviewLine(
          showSequence: _showSequence,
          showDelta: _showDelta,
          showSource: _showSource,
          colors: _colors,
          borders: _showBorders,
          environment: _envCtrl.text.trim(),
        ),
        const SizedBox(height: 14),
        _FlatSection(
          title: 'Top-bar segments',
          icon: Icons.short_text_rounded,
          child: _TileGroup(
            children: [
              _SwitchTile(
                label: 'Sequence  [#N]',
                value: _showSequence,
                onChanged: (v) {
                  setState(() => _showSequence = v);
                  Logger.configure(showSequence: v);
                  _saveKnobs();
                },
              ),
              _SwitchTile(
                label: 'Delta  [+Nms]',
                value: _showDelta,
                onChanged: (v) {
                  setState(() => _showDelta = v);
                  Logger.configure(showDelta: v);
                  _saveKnobs();
                },
              ),
              _SwitchTile(
                label: 'Source  [file:line]',
                value: _showSource,
                onChanged: (v) {
                  setState(() => _showSource = v);
                  Logger.configure(showSource: v);
                  _saveKnobs();
                },
              ),
              _SwitchTile(
                label: 'ANSI colors',
                value: _colors,
                onChanged: (v) {
                  setState(() => _colors = v);
                  Logger.configure(colors: v);
                  _saveKnobs();
                },
              ),
              _SwitchTile(
                label: 'Box borders  ╭─│─╯',
                value: _showBorders,
                onChanged: (v) {
                  setState(() => _showBorders = v);
                  Logger.configure(showBorders: v);
                  _saveKnobs();
                },
              ),
            ],
          ),
        ),
        _FlatSection(
          title: 'Filtering',
          icon: Icons.filter_alt_rounded,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              color: DebugOverlayTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DebugOverlayTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Suppress below',
                    style: DebugOverlayTheme.ui.copyWith(fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: DebugConsoleTheme(
                    fontSize: 11,
                    child: GlobalDropdown<LogLevel>(
                      items: [
                        for (final l in LogLevel.values)
                          DropdownItem(value: l, label: l.name.toUpperCase()),
                      ],
                      selectedValue: _minLevel,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _minLevel = v);
                        Logger.configure(minLevel: v);
                        _saveKnobs();
                      },
                      behavior: const DropdownBehavior(denseTrigger: true),
                      style: debugTextFieldStyle(
                        radius: 6,
                        fontSize: 11,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      dropdownStyle: DropdownStyle(
                        accentColor: DebugOverlayTheme.accent,
                        itemTextStyle: DebugOverlayTheme.mono.copyWith(
                          fontSize: 11,
                          color: DebugOverlayTheme.text,
                        ),
                      ),
                      sizing: const TextFieldSizing(height: 30),
                      popupOptions: GlobalPopupOptions(
                        surfaceStyle: GlobalPopupSurfaceStyle(
                          color: DebugOverlayTheme.surfaceHigh,
                          borderColor: DebugOverlayTheme.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _FlatSection(
          title: 'Environment tag',
          icon: Icons.sell_rounded,
          child: DebugTextField(
            controller: _envCtrl,
            hint: 'DEV, STAGING, PROD  (blank = off)',
            onChanged: _applyEnv,
          ),
        ),
        _FlatSection(
          title: 'Buffer',
          icon: Icons.inbox_rounded,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            decoration: BoxDecoration(
              color: DebugOverlayTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DebugOverlayTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Max retained entries',
                        style: DebugOverlayTheme.ui.copyWith(fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DebugOverlayTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: DebugOverlayTheme.accent.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Text(
                        _bufferSize.round().toString(),
                        style: DebugOverlayTheme.mono.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: DebugOverlayTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _bufferSize,
                  min: 50,
                  max: 2000,
                  divisions: 39,
                  activeColor: DebugOverlayTheme.accent,
                  inactiveColor: DebugOverlayTheme.border,
                  onChanged: (v) => setState(() {
                    _bufferSize = v;
                    LogBuffer.maxSize = v.round();
                  }),
                  onChangeEnd: (_) => _saveKnobs(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final t in const ['50', '2000'])
                        Text(
                          t,
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 9,
                            color: DebugOverlayTheme.textDimmer,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shrinking drops the oldest entries immediately.',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    color: DebugOverlayTheme.textDimmer,
                  ),
                ),
              ],
            ),
          ),
        ),
        _FlatSection(
          title: 'Box width',
          icon: Icons.width_wide_rounded,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            decoration: BoxDecoration(
              color: DebugOverlayTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DebugOverlayTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Line length (chars)',
                        style: DebugOverlayTheme.ui.copyWith(fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DebugOverlayTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: DebugOverlayTheme.accent.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Text(
                        _lineLength.round().toString(),
                        style: DebugOverlayTheme.mono.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: DebugOverlayTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _lineLength,
                  min: 60,
                  max: 200,
                  divisions: 14,
                  activeColor: DebugOverlayTheme.accent,
                  inactiveColor: DebugOverlayTheme.border,
                  onChanged: (v) {
                    setState(() => _lineLength = v);
                    Logger.configure(lineLength: v.round());
                  },
                  onChangeEnd: (_) => _saveKnobs(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final t in const ['60', '200'])
                        Text(
                          t,
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 9,
                            color: DebugOverlayTheme.textDimmer,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Width of the ┃-boxed multiline log frame. Match your '
                  'terminal width so rows don\'t wrap.',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    color: DebugOverlayTheme.textDimmer,
                  ),
                ),
              ],
            ),
          ),
        ),
        _FlatSection(
          title: 'Actions',
          icon: Icons.play_circle_outline_rounded,
          child: _TileGroup(
            children: [
              _ActionTile(
                icon: Icons.playlist_add_rounded,
                label: 'Emit test logs (all 6 levels)',
                description:
                    'Verifies min-level filtering + feeds the Logs tool',
                onTap: _emitTestLogs,
              ),
              _ActionTile(
                icon: Icons.refresh_rounded,
                label: 'Reset logger config',
                description: 'Back to compiled defaults',
                onTap: () {
                  Logger.reset();
                  LogBuffer.maxSize = 500;
                  DebugOverlayPrefs.clearLoggerConfig();
                  setState(_syncFromLogger);
                  GlobalToast.info('Logger config reset');
                },
              ),
              _ActionTile(
                icon: Icons.delete_sweep_outlined,
                label: 'Clear log buffer',
                description: 'Empties the in-memory ring buffer',
                onTap: () {
                  LogBuffer.clear();
                  setState(() {});
                  GlobalToast.info('Log buffer cleared');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// What a log line will look like with the CURRENT knobs — approximates
/// the terminal top bar (segments toggle in/out live; colors toggle
/// tints the level tag).
class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.showSequence,
    required this.showDelta,
    required this.showSource,
    required this.colors,
    required this.borders,
    required this.environment,
  });

  final bool showSequence;
  final bool showDelta;
  final bool showSource;
  final bool colors;
  final bool borders;
  final String environment;

  @override
  Widget build(BuildContext context) {
    final dim = DebugOverlayTheme.mono.copyWith(
      fontSize: 10.5,
      color: DebugOverlayTheme.textDim,
    );
    final infoColor = colors ? const Color(0xFF66BB6A) : DebugOverlayTheme.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: DebugOverlayTheme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (showSequence) TextSpan(text: '[#42] ', style: dim),
            if (showDelta) TextSpan(text: '[+12ms] ', style: dim),
            if (environment.isNotEmpty)
              TextSpan(text: '[$environment] ', style: dim),
            if (showSource)
              TextSpan(text: '[settings_page.dart:87] ', style: dim),
            TextSpan(
              text: borders ? '┃ INFO ' : 'INFO ',
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: infoColor,
              ),
            ),
            TextSpan(
              text: '[Auth] sign-in succeeded',
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 10.5,
                color: DebugOverlayTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatSection extends StatelessWidget {
  const _FlatSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: DebugOverlayTheme.ui.copyWith(fontSize: 12),
              ),
            ),
            DebugSwitch(
              value: value,
              onChanged: onChanged,
              semanticLabel: label,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                child: Icon(icon, size: 14, color: DebugOverlayTheme.accent),
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
