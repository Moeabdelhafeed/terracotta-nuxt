import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/loading/loading_cubit.dart';
import '../../../../core/loading/loading_show_options.dart';
import '../../../../core/loading/loading_token.dart';
import '../../banner/global_banner.dart';
import '../../dialog/global_dialog.dart';
import '../../sheet/global_sheet.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';

/// Visual QA panel — fires every transient surface the project exposes
/// (toasts, snackbars, dialogs, sheets, banners, loading overlays,
/// haptics) so a restyle can be verified across all entry points from
/// one place.
class DebugUiLabView extends StatelessWidget {
  const DebugUiLabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        _FlatSection(
          title: 'Toasts',
          icon: Icons.notifications_active_outlined,
          child: _TileGroup(
            children: [
              _Tile(
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF66BB6A),
                label: 'Success',
                description: 'GlobalToast.success(...)',
                onTap: () => GlobalToast.success(
                  'Saved',
                  description: 'Synthetic success toast',
                ),
              ),
              _Tile(
                icon: Icons.error_rounded,
                color: const Color(0xFFEF5350),
                label: 'Error',
                description: 'GlobalToast.error(...)',
                onTap: () => GlobalToast.error(
                  'Something broke',
                  description: 'Synthetic error toast',
                ),
              ),
              _Tile(
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFFFA726),
                label: 'Warning',
                description: 'GlobalToast.warning(...)',
                onTap: () => GlobalToast.warning(
                  'Heads up',
                  description: 'Synthetic warning toast',
                ),
              ),
              _Tile(
                icon: Icons.info_outline_rounded,
                color: const Color(0xFF64B5F6),
                label: 'Info',
                description: 'GlobalToast.info(...)',
                onTap: () => GlobalToast.info(
                  'FYI',
                  description: 'Synthetic info toast',
                ),
              ),
              _Tile(
                icon: Icons.touch_app_rounded,
                color: DebugOverlayTheme.accent,
                label: 'With action',
                description: 'Action button + onAction callback',
                onTap: () => GlobalToast.info(
                  'Pending sync',
                  description: 'Tap retry to fire the action callback',
                  actionLabel: 'Retry',
                  onAction: () => GlobalToast.success(
                    'Retried',
                    description: 'Action fired',
                  ),
                ),
              ),
              _Tile(
                icon: Icons.dynamic_feed_rounded,
                color: DebugOverlayTheme.accent,
                label: 'Stack ×3 (stress)',
                description: 'Three toasts back-to-back — queue/stacking QA',
                onTap: () {
                  GlobalToast.success('First');
                  GlobalToast.warning('Second');
                  GlobalToast.error('Third');
                },
              ),
              const _Tile(
                icon: Icons.layers_clear_rounded,
                color: DebugOverlayTheme.textDim,
                label: 'Dismiss all',
                description: 'GlobalToast.dismissAll()',
                onTap: GlobalToast.dismissAll,
              ),
            ],
          ),
        ),
        _FlatSection(
          title: 'SnackBars',
          icon: Icons.message_outlined,
          child: _TileGroup(
            children: [
              _Tile(
                icon: Icons.message_rounded,
                color: const Color(0xFF64B5F6),
                label: 'Default snack',
                description: 'ScaffoldMessenger.showSnackBar(...)',
                onTap: () =>
                    _snack(context, content: const Text('Synthetic snackbar')),
              ),
              _Tile(
                icon: Icons.report_rounded,
                color: const Color(0xFFEF5350),
                label: 'Error snack',
                description: 'Red bg + retry action',
                onTap: () => _snack(
                  context,
                  bg: const Color(0xFFEF5350),
                  content: const Text('Operation failed'),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              ),
              _Tile(
                icon: Icons.timer_rounded,
                color: const Color(0xFFFFA726),
                label: '8-second snack',
                description: 'Long duration for stress-testing layout',
                onTap: () => _snack(
                  context,
                  duration: const Duration(seconds: 8),
                  content: const Text('Sticking around for 8s'),
                ),
              ),
            ],
          ),
        ),
        _FlatSection(
          title: 'Dialogs',
          icon: Icons.web_asset_rounded,
          child: _TileGroup(
            children: [
              _Tile(
                icon: Icons.help_outline_rounded,
                color: DebugOverlayTheme.accent,
                label: 'Confirm',
                description: 'GlobalDialog.confirm(...) → bool',
                onTap: () async {
                  final ok = await GlobalDialog.confirm(
                    title: 'Apply changes?',
                    message: 'Synthetic confirm dialog.',
                  );
                  GlobalToast.info(ok ? 'Confirmed' : 'Cancelled');
                },
              ),
              _Tile(
                icon: Icons.delete_forever_rounded,
                color: const Color(0xFFEF5350),
                label: 'Destructive confirm',
                description: 'isDestructive: true — red accent CTA',
                onTap: () async {
                  final ok = await GlobalDialog.confirm(
                    title: 'Delete item?',
                    message: 'This cannot be undone.',
                    isDestructive: true,
                  );
                  GlobalToast.info(ok ? 'Deleted' : 'Kept');
                },
              ),
              _Tile(
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF66BB6A),
                label: 'Success dialog',
                description: 'GlobalDialog.success(...)',
                onTap: () => GlobalDialog.success(
                  title: 'All done',
                  message: 'Synthetic success dialog.',
                ),
              ),
              _Tile(
                icon: Icons.error_outline_rounded,
                color: const Color(0xFFEF5350),
                label: 'Error dialog',
                description: 'GlobalDialog.error(...)',
                onTap: () => GlobalDialog.error(
                  title: 'Failed',
                  message: 'Synthetic error dialog.',
                ),
              ),
            ],
          ),
        ),
        _FlatSection(
          title: 'Sheets',
          icon: Icons.call_to_action_outlined,
          child: _TileGroup(
            children: [
              _Tile(
                icon: Icons.vertical_align_bottom_rounded,
                color: DebugOverlayTheme.accent,
                label: 'Bottom sheet',
                description: 'GlobalBottomSheet.show — side-sheet on medium+',
                onTap: () => GlobalBottomSheet.show<void>(
                  title: 'Synthetic sheet',
                  subtitle: 'Resize the window past 600dp → side sheet',
                  content: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Sheet content goes here.'),
                  ),
                ),
              ),
              _Tile(
                icon: Icons.height_rounded,
                color: const Color(0xFFFFA726),
                label: 'Tall scrollable sheet',
                description: '40 rows — drag + overscroll behavior',
                onTap: () => GlobalBottomSheet.show<void>(
                  title: 'Tall sheet',
                  content: SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: 40,
                      itemBuilder: (_, i) =>
                          ListTile(dense: true, title: Text('Row $i')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _FlatSection(
          title: 'Banners (inline)',
          icon: Icons.campaign_outlined,
          child: Column(
            children: [
              for (final (type, title) in const [
                (BannerType.info, 'Info banner'),
                (BannerType.success, 'Success banner'),
                (BannerType.warning, 'Warning banner'),
                (BannerType.error, 'Error banner'),
              ]) ...[
                GlobalBanner(
                  title: title,
                  message: 'Inline ${type.name} styling as rendered in-app.',
                  type: type,
                  dismissible: true,
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        _FlatSection(
          title: 'Loading overlay',
          icon: Icons.hourglass_empty_rounded,
          child: _TileGroup(
            children: [
              _Tile(
                icon: Icons.hourglass_top_rounded,
                color: DebugOverlayTheme.accent,
                label: 'Plain (2s)',
                description: 'Default scrim + spinner',
                onTap: () => _showLoading(context),
              ),
              _Tile(
                icon: Icons.short_text_rounded,
                color: DebugOverlayTheme.accent,
                label: 'With label (2s)',
                description: 'Spinner + status text',
                onTap: () => _showLoading(
                  context,
                  options: const LoadingShowOptions(
                    label: 'Crunching numbers…',
                  ),
                ),
              ),
              _Tile(
                icon: Icons.cancel_outlined,
                color: const Color(0xFFFFA726),
                label: 'Cancellable (5s)',
                description: 'Cancel button dismisses early',
                onTap: () => _showCancellable(context),
              ),
              _Tile(
                icon: Icons.linear_scale_rounded,
                color: DebugOverlayTheme.accent,
                label: 'Determinate progress',
                description: '0→1 over 3s, top-bar variant',
                onTap: () => _showProgress(context),
              ),
              _Tile(
                icon: Icons.layers_rounded,
                color: const Color(0xFF66BB6A),
                label: 'Top-bar (input not blocked)',
                description: 'blockInput=false → app stays interactive',
                onTap: () => _showLoading(
                  context,
                  options: const LoadingShowOptions(
                    blockInput: false,
                    label: 'Syncing…',
                  ),
                ),
              ),
              _Tile(
                icon: Icons.flip_to_front_rounded,
                color: const Color(0xFFFFA726),
                label: 'Toast over loading (z-order)',
                description: 'Loading 3s + toast at 1s — layering QA',
                onTap: () {
                  _showLoading(context, timeout: const Duration(seconds: 3));
                  Future.delayed(
                    const Duration(seconds: 1),
                    () => GlobalToast.info('Above the scrim?'),
                  );
                },
              ),
            ],
          ),
        ),
        _FlatSection(
          title: 'Haptics',
          icon: Icons.vibration_rounded,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, fire) in <(String, VoidCallback)>[
                ('light', HapticFeedback.lightImpact),
                ('medium', HapticFeedback.mediumImpact),
                ('heavy', HapticFeedback.heavyImpact),
                ('selection', HapticFeedback.selectionClick),
                ('vibrate', HapticFeedback.vibrate),
              ])
                _HapticChip(label: label, onTap: fire),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Snackbar helper ──────────────────────────────────────

  static void _snack(
    BuildContext context, {
    required Widget content,
    Color? bg,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      GlobalToast.error(
        'No ScaffoldMessenger',
        description: 'Snackbar requires a Scaffold ancestor',
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: bg,
        action: action,
        duration: duration,
      ),
    );
  }

  // ─── Loading helpers ──────────────────────────────────────
  // Each variant auto-disposes its token after a timer so the dev
  // doesn't have to remember to dismiss. Cancellable variants honor
  // the user's tap immediately; the timer becomes the safety net.

  static void _showLoading(
    BuildContext context, {
    LoadingShowOptions options = const LoadingShowOptions(),
    Duration timeout = const Duration(seconds: 2),
  }) {
    final cubit = context.read<LoadingCubit>();
    final token = cubit.show(options);
    Future.delayed(timeout, token.dispose);
  }

  static void _showCancellable(BuildContext context) {
    final cubit = context.read<LoadingCubit>();
    LoadingToken? token;
    token = cubit.show(
      LoadingShowOptions(
        label: 'Tap cancel or wait 5s',
        cancellable: () {
          token?.dispose();
          GlobalToast.info('Cancelled', description: 'User dismissed loading');
        },
      ),
    );
    Future.delayed(const Duration(seconds: 5), () => token?.dispose());
  }

  static void _showProgress(BuildContext context) {
    final cubit = context.read<LoadingCubit>();
    final progress = ValueNotifier<double>(0);
    final token = cubit.show(
      LoadingShowOptions(
        label: 'Uploading…',
        progress: progress,
      ),
    );
    const total = 3000;
    const step = 50;
    var elapsed = 0;
    Timer.periodic(const Duration(milliseconds: step), (timer) {
      elapsed += step;
      progress.value = (elapsed / total).clamp(0.0, 1.0);
      if (elapsed >= total) {
        timer.cancel();
        token.dispose();
        progress.dispose();
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────
// UI primitives
// ─────────────────────────────────────────────────────────────

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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
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
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      description,
                      style: DebugOverlayTheme.mono.copyWith(
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

class _HapticChip extends StatelessWidget {
  const _HapticChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: DebugOverlayTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.vibration_rounded,
                size: 12,
                color: DebugOverlayTheme.textDim,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
