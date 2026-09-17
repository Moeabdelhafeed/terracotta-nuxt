import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/scan_strings.dart';
import '../../../core/tokens/extensions.dart';

/// The camera, and nothing else.
///
/// ## Why it answers rather than acts
///
/// It pops with the decoded string and lets the desk screen do the
/// check-in. The scan is one step of a conversation the server may
/// continue — a party of several comes back asking for a headcount —
/// and that conversation belongs where the day's list is, not inside a
/// camera preview.
///
/// ## One code, once
///
/// `mobile_scanner` fires continuously while a symbol is in frame,
/// which would send the same booking a dozen times a second. The first
/// readable code wins and the detector is closed behind it.
class ScanCameraPage extends StatefulWidget {
  const ScanCameraPage({super.key});

  @override
  State<ScanCameraPage> createState() => _ScanCameraPageState();
}

class _ScanCameraPageState extends State<ScanCameraPage> {
  final _controller = MobileScannerController(
    // The desk points at ONE code on a customer's phone. Reading
    // several at once would make which booking got checked in a matter
    // of luck.
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Claimed by the first readable symbol, so the rest of the burst is
  /// ignored while the route pops.
  bool _handled = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue ?? '')
        .firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;

    _handled = true;
    Navigator.of(context).pop(code.trim());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: Text(ScanStrings.scanCode),
      actions: [
        IconButton(
          onPressed: () => unawaited(_controller.toggleTorch()),
          icon: const Icon(Icons.flashlight_on_outlined),
        ),
      ],
    ),
    extendBodyBehindAppBar: true,
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          // A camera that cannot start is not a dead end: the eight
          // digits under every customer's symbol are typed in instead.
          errorBuilder: (context, error) => _CameraUnavailable(
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
        // The frame to aim with, and the one line of instruction.
        IgnorePointer(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(context.radii.lg),
                  ),
                ),
                SizedBox(height: context.spacing.md),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.xl,
                  ),
                  child: Text(
                    ScanStrings.pointCamera,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// No camera — permission refused, or none on the device.
class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 48,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              ScanStrings.cameraDenied,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            SizedBox(height: context.spacing.lg),
            TextButton(
              onPressed: onBack,
              child: Text(
                CommonStrings.back,
                style: context.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
