import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/flavor/flavor_config.dart';

/// Last-resort UI shown when `bootstrap()` throws before the real
/// app can mount. Self-contained — does not depend on `AppTheme`,
/// DI, GoRouter, or localization (any of which may be the thing
/// that crashed).
///
/// Surfaces:
/// - Friendly title + short message
/// - Diagnostics block (expanded in debug, collapsed in release)
/// - Copy diagnostics → clipboard
/// - Email support → mailto with diagnostics pre-filled
/// - Restart hint (no programmatic Phoenix restart yet — manual)
class ErrorApp extends StatelessWidget {
  const ErrorApp({
    required this.errorMessage,
    required this.errorDetails,
    this.error,
    this.stack,
    super.key,
  });

  final String errorMessage;
  final String errorDetails;
  final Object? error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use the platform brightness so dark-mode users don't get
      // a glaring white panel on a fatal boot error.
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6453D8),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6453D8),
      ),
      themeMode: ThemeMode.system,
      home: _ErrorAppBody(
        errorMessage: errorMessage,
        errorDetails: errorDetails,
        error: error,
        stack: stack,
      ),
    );
  }
}

class _ErrorAppBody extends StatelessWidget {
  const _ErrorAppBody({
    required this.errorMessage,
    required this.errorDetails,
    this.error,
    this.stack,
  });

  final String errorMessage;
  final String errorDetails;
  final Object? error;
  final StackTrace? stack;

  String _diagnostics() {
    final lines = <String>[
      'Stage: bootstrap',
      'Message: $errorMessage',
      if (errorDetails.isNotEmpty) 'Details: $errorDetails',
      'Platform: ${defaultTargetPlatform.name}',
      if (error != null) '\nError:\n$error',
      if (stack != null) '\nStack:\n$stack',
    ];
    return lines.join('\n');
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _diagnostics()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics copied to clipboard')),
    );
  }

  Future<void> _email(BuildContext context) async {
    // FlavorConfig may not be set if bootstrap crashed before it was
    // initialized — fall back to a sentinel so the button still works
    // in dev and the adopter notices the unset value.
    final email = FlavorConfig.maybeInstance?.supportEmail.trim() ?? '';
    if (email.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Support email not configured (SUPPORT_EMAIL in config/<flavor>.json)',
            ),
          ),
        );
      }
      return;
    }
    final body = Uri.encodeComponent(_diagnostics());
    final subject = Uri.encodeComponent('App failed to start');
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.error.withValues(alpha: 0.20),
                          cs.error.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 44,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'The app failed to start',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please close and reopen the app. If the problem '
                    'continues, send us the diagnostics below.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _copy(context),
                        icon: const Icon(Icons.content_copy_rounded),
                        label: const Text('Copy diagnostics'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _email(context),
                        icon: const Icon(Icons.mail_outline_rounded),
                        label: const Text('Email support'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DiagnosticsCard(text: _diagnostics(), cs: cs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.text, required this.cs});

  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          initiallyExpanded: kDebugMode,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Diagnostics',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
