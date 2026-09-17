import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/strings/scanner_strings.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../buttons/global_outlined_button.dart';
import 'scanner_models.dart';

/// A control glyph over camera pixels.
///
/// `GlobalIconButton` rather than a hand-rolled `Material` + `InkWell`
/// + `Icon`, which is what these were: that spelling draws its own
/// disc, enforces no touch target and — the reason it matters here —
/// carries no name, so every control on this screen announced nothing
/// at all.
///
/// [label] is REQUIRED, for the same reason the video module's is:
/// each of these is a bare icon on a picture, with no text near it to
/// fall back on.
class ScannerControlButton extends StatelessWidget {
  const ScannerControlButton({
    required this.icon,
    required this.label,
    required this.style,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final ResolvedScannerStyle style;
  final VoidCallback onTap;

  /// Reported to a screen reader, and it is what makes the torch
  /// button a TOGGLE rather than two buttons that look alike.
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: selected,
    child: GlobalIconButton(
      iconData: icon,
      iconSize: style.controlSize,
      onPressed: onTap,
      semanticLabel: label,
      style: ButtonStateStyle(
        foregroundColor: style.controlsColor,
        backgroundColor: style.controlScrim,
        borderRadius: BorderRadius.circular(style.controlSize * 2),
        // Sized to the GLYPH. Left unset the painted box falls back to
        // the 48dp touch target, which puts the disc a long way off
        // the icon inside it; `MinTouchTarget` keeps the HIT area at
        // 48 either way.
        width: style.controlSize * 2,
        height: style.controlSize * 2,
      ),
    ),
  );
}

/// Torch, camera flip and zoom.
///
/// Every value here is read from the CONTROLLER rather than kept
/// beside it. Three local flags used to mirror the camera's state, and
/// a mirror is wrong whenever the platform refuses: a front camera has
/// no torch, so the glyph said "on" over a light that never came on.
class ScannerControlRow extends StatelessWidget {
  const ScannerControlRow({
    required this.style,
    required this.state,
    required this.onTorch,
    required this.onFlip,
    required this.onZoom,
    this.onPickImage,
    super.key,
  });

  final ResolvedScannerStyle style;

  /// The camera's own report — torch, zoom, how many cameras there
  /// are.
  final MobileScannerState state;

  final VoidCallback onTorch;
  final VoidCallback onFlip;
  final ValueChanged<double> onZoom;

  /// Null when the app has no picker to offer — and then no control is
  /// drawn, like every other one here.
  final VoidCallback? onPickImage;

  @override
  Widget build(BuildContext context) {
    // Nothing appears that cannot work: no torch on this camera, or
    // no second camera to flip to, and the control is not drawn. A
    // control that does nothing when pressed is worse than one that is
    // not there.
    final torch =
        style.showTorch && ScannerCapture.torchUsable(state.torchState);
    final flip =
        style.showFlip && ScannerCapture.flipUsable(state.availableCameras);
    final on = state.torchState == TorchState.on;

    return Padding(
      padding: ScannerDefaults.controlsPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.showZoom)
            Semantics(
              label: ScannerStrings.zoom,
              slider: true,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: ScannerDefaults.trackHeight,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: ScannerDefaults.thumbRadius,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: ScannerDefaults.overlayRadius,
                  ),
                  activeTrackColor: style.controlsColor,
                  inactiveTrackColor: style.controlsColor.withValues(
                    alpha: 0.3,
                  ),
                  thumbColor: style.controlsColor,
                ),
                child: Slider(
                  // The CAMERA's zoom, not a number kept beside it —
                  // a pinch on the preview moves this too.
                  value: state.zoomScale.clamp(0.0, 1.0),
                  onChanged: onZoom,
                ),
              ),
            ),
          if (torch || flip || onPickImage != null) ...[
            const SizedBox(height: ScannerDefaults.controlGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (torch)
                  ScannerControlButton(
                    icon: on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    // The label says what pressing it DOES, which is
                    // the opposite of what the glyph shows.
                    label: on
                        ? ScannerStrings.torchOff
                        : ScannerStrings.torchOn,
                    selected: on,
                    style: style,
                    onTap: onTorch,
                  ),
                if (flip)
                  ScannerControlButton(
                    icon: Icons.cameraswitch_rounded,
                    label: ScannerStrings.flipCamera,
                    style: style,
                    onTap: onFlip,
                  ),
                if (onPickImage != null)
                  ScannerControlButton(
                    icon: Icons.photo_library_rounded,
                    label: ScannerStrings.fromImage,
                    style: style,
                    onTap: onPickImage!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The plate that holds a read until it is confirmed.
///
/// `ScannerCaptureMode.manual` only. It is a LIVE REGION: the code
/// arrives without anyone touching the screen, so a reader who cannot
/// see it is otherwise told nothing at all.
class ScannerPendingPlate extends StatelessWidget {
  const ScannerPendingPlate({
    required this.result,
    required this.style,
    required this.onConfirm,
    required this.onRetry,
    this.confirmLabel,
    this.retryLabel,
    super.key,
  });

  final ScannerResult result;
  final ResolvedScannerStyle style;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final String? confirmLabel;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final value = result.value.isEmpty
        ? ScannerStrings.emptyValue
        : result.value;
    return Positioned(
      left: ScannerDefaults.pendingInset,
      right: ScannerDefaults.pendingInset,
      bottom: ScannerDefaults.pendingBottom,
      child: SafeArea(
        top: false,
        child: Semantics(
          liveRegion: true,
          explicitChildNodes: true,
          label: '${ScannerStrings.pendingCode}: $value',
          child: Material(
            color: ScannerDefaults.pendingSurface,
            borderRadius: BorderRadius.circular(
              ScannerDefaults.pendingRadius,
            ),
            child: Padding(
              padding: ScannerDefaults.pendingPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      result.format.name.toUpperCase(),
                      style: TextStyle(
                        color: style.controlsColor.withValues(alpha: 0.6),
                        fontSize: context.textTheme.labelSmall?.fontSize,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: ScannerDefaults.gapXs),
                  ExcludeSemantics(
                    child: SelectableText(
                      value,
                      style: TextStyle(
                        color: style.controlsColor,
                        fontSize: context.textTheme.bodyMedium?.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: ScannerDefaults.pendingMaxLines,
                    ),
                  ),
                  const SizedBox(height: ScannerDefaults.gapMd),
                  Row(
                    children: [
                      Expanded(
                        child: GlobalOutlinedButton(
                          text: retryLabel ?? ScannerStrings.scanAgain,
                          onPressed: onRetry,
                          style: ButtonStateStyle(
                            foregroundColor: style.controlsColor,
                            border: BorderSide(
                              color: style.controlsColor.withValues(
                                alpha: 0.24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: ScannerDefaults.gapSm),
                      Expanded(
                        child: GlobalFilledButton(
                          text: confirmLabel ?? ScannerStrings.useThisCode,
                          onPressed: onConfirm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
