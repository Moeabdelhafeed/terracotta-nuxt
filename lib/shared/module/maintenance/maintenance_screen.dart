import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/maintenance_strings.dart';
import '../../../core/maintenance/maintenance_config.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_outlined_button.dart';

/// Fullscreen maintenance UI. Self-contained — does not depend on the
/// app's theme extensions or routing so it can render at any moment
/// (mid-session 503 takeover, cold-start RC flag, etc).
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({
    required this.config,
    required this.onRetry,
    super.key,
  });

  final MaintenanceConfig config;
  final VoidCallback onRetry;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  Timer? _ticker;
  // Cooldown so users can't spam the retry button.
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    if (widget.config.eta != null) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_cooldown > 0) _cooldown--;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _handleRetry() {
    if (_cooldown > 0) return;
    setState(() => _cooldown = 5);
    widget.onRetry();
    if (_ticker == null) _startTicker();
  }

  Future<void> _openSupport() async {
    final url = widget.config.supportUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatEta(DateTime eta) {
    final remaining = eta.difference(DateTime.now());
    if (remaining.isNegative) return MaintenanceStrings.etaAnyMoment;
    if (remaining.inHours > 0) {
      return MaintenanceStrings.etaHoursMinutes(
        remaining.inHours,
        remaining.inMinutes % 60,
      );
    }
    if (remaining.inMinutes > 0) {
      return MaintenanceStrings.etaMinutes(remaining.inMinutes);
    }
    return MaintenanceStrings.etaSeconds(remaining.inSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final hasEta = cfg.eta != null;
    final hasSupport = (cfg.supportUrl ?? '').isNotEmpty;

    return Material(
      color: const Color(0xFF0F172A), // slate-900 — neutral dark backdrop
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.construction_rounded,
                      size: 44,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    cfg.title.isEmpty
                        ? MaintenanceStrings.defaultTitle
                        : cfg.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.textTheme.headlineSmall?.fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cfg.message.isEmpty
                        ? MaintenanceStrings.defaultMessage
                        : cfg.message,
                    style: TextStyle(
                      color: const Color(0xFFCBD5E1),
                      fontSize: context.textTheme.bodyMedium?.fontSize,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasEta) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            MaintenanceStrings.backEta(_formatEta(cfg.eta!)),
                            style: TextStyle(
                              color: const Color(0xFFFBBF24),
                              fontSize: context.textTheme.bodySmall?.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  GlobalFilledButton(
                    text: _cooldown > 0
                        ? MaintenanceStrings.retryInSeconds(_cooldown)
                        : CommonStrings.tryAgain,
                    onPressed: _handleRetry,
                    enabled: _cooldown == 0,
                    style: ButtonStateStyle(
                      backgroundColor: const Color(0xFF6453D8),
                      foregroundColor: Colors.white,
                      height: 48,
                      borderRadius: BorderRadius.circular(12),
                      textStyle: TextStyle(
                        fontSize: context.textTheme.bodyMedium?.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasSupport) ...[
                    const SizedBox(height: 12),
                    GlobalOutlinedButton(
                      text: CommonStrings.contactSupport,
                      onPressed: _openSupport,
                      style: ButtonStateStyle(
                        foregroundColor: Colors.white,
                        border: const BorderSide(color: Color(0xFF334155)),
                        height: 48,
                        borderRadius: BorderRadius.circular(12),
                        textStyle: TextStyle(
                          fontSize: context.textTheme.bodyMedium?.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
