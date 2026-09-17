import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/a11y/semantics_extensions.dart';
import '../../../core/crash_reporting/crash_reporter.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/error_strings.dart';
import '../../../core/localization/strings/nav_strings.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/system_pages/error_payload.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/device/network/connectivity_utils.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../common/containers/containers.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_outlined_button.dart';
import '../buttons/global_text_button.dart';
import '../container/global_container.dart';
import '../scrollable/global_scrollable.dart';
import '../toast/global_toast.dart';
import 'system_page_parts.dart';

/// Placeholder the "Email support" action falls back to when no address
/// is injected. Adopters MUST override it — see the setup checklist.
const kFallbackSupportEmail = 'support@example.com';

/// Mid-session crash / fatal-error landing page.
///
/// Differentiates from [MaintenanceScreen] (server outage), the
/// connectivity banner (offline), and [NotFoundPage] (404). Use only
/// for unrecoverable client-side errors that the app can't keep
/// running through.
///
/// Surfaces:
/// - Friendly title + message
/// - Diagnostics block in debug; collapsed expandable card in release
/// - "Try again" — calls [ErrorPayload.onRetry] or hops to home
/// - "Report" — sends a userReported note to Crashlytics
/// - "Email support" — opens mailto with diagnostics pre-filled
/// - Connectivity hint when offline
///
/// Reach it via [SystemNavigation.toError].
class ErrorPage extends StatefulWidget {
  const ErrorPage({this.payload, this.supportEmail, super.key});

  final ErrorPayload? payload;

  /// Address the "Email support" action opens. Left null the page falls
  /// back to [kFallbackSupportEmail] — a placeholder no adopter should
  /// ship. The route passes the Remote-Config-resolved address; module
  /// code must not reach for services itself.
  final String? supportEmail;

  /// An address is only usable if it was actually configured — every
  /// flavor config ships [kFallbackSupportEmail], so an adopter who
  /// forgets would otherwise ship a button that opens a mail draft to a
  /// nonexistent recipient while the user believes they filed a report.
  static bool isSupportEmailConfigured(String? email) {
    final trimmed = email?.trim() ?? '';
    return trimmed.isNotEmpty &&
        trimmed.toLowerCase() != kFallbackSupportEmail.toLowerCase();
  }

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  bool _online = true;
  bool _reporting = false;
  bool _reported = false;
  PackageInfo? _info;

  /// When the error surfaced. Captured at mount rather than when the
  /// diagnostics are read, so copying twice reports the same instant and
  /// the value can be matched against server logs.
  late final DateTime _occurredAt;

  @override
  void initState() {
    super.initState();
    _occurredAt = DateTime.now();
    _checkOnline();
    PackageInfo.fromPlatform().then((i) {
      if (!mounted) return;
      setState(() => _info = i);
    });
  }

  Future<void> _checkOnline() async {
    final ok = await ConnectivityUtils.hasConnection(forceRefresh: true);
    if (!mounted) return;
    setState(() => _online = ok);
  }

  /// True when the payload gave us something to actually retry. Without
  /// it the primary action can only send the user home — so it SAYS so
  /// rather than promising a retry it cannot perform.
  bool get _canRetry => widget.payload?.onRetry != null;

  Future<void> _retry() async {
    final retry = widget.payload?.onRetry;
    if (retry != null) {
      // The offline hint was captured when the page opened; a retry is
      // exactly when it might have gone stale.
      unawaited(_checkOnline());
      retry();
      return;
    }
    if (!mounted) return;
    context.go(AppRoutes.splash.path);
  }

  Future<void> _copyDiagnostics() async {
    await Clipboard.setData(ClipboardData(text: _diagnosticsText()));
    if (!mounted) return;
    GlobalToast.success(ErrorStrings.diagnosticsCopied);
  }

  Future<void> _report() async {
    final p = widget.payload;
    if (p == null) return;
    setState(() => _reporting = true);
    try {
      await CrashReporter.recordError(
        p.error ?? 'User-reported error',
        stackTrace: p.stack,
        reason: 'userReported: ${p.code ?? p.title ?? 'unspecified'}',
      );
      if (!mounted) return;
      setState(() {
        _reporting = false;
        _reported = true;
      });
      // Swapping the button label is easy to miss and invisible to a
      // screen reader; say it out loud.
      if (mounted) {
        announceForAccessibility(context, ErrorStrings.reportSent);
      }
    } catch (e, st) {
      Logger.m.e('[ErrorPage] report failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _reporting = false);
      // Previously swallowed: the button just un-spun and the user had
      // no idea the report never left.
      GlobalToast.error(ErrorStrings.reportFailed);
    }
  }

  Future<void> _emailSupport() async {
    if (!ErrorPage.isSupportEmailConfigured(widget.supportEmail)) {
      // Actionable detail goes to the log for whoever is building the
      // app; the user gets something they can understand.
      Logger.m.w(
        '[ErrorPage] support email not configured — set SUPPORT_EMAIL in '
        'config/<flavor>.json, or the feedback_support_email Remote Config '
        'key. Falling back would have mailed $kFallbackSupportEmail.',
      );
      GlobalToast.error(ErrorStrings.supportEmailUnconfigured);
      return;
    }
    final body = Uri.encodeComponent(_diagnosticsText());
    final subject = Uri.encodeComponent(
      'App error report — ${widget.payload?.code ?? 'unknown'}',
    );
    final address = widget.supportEmail!.trim();
    final uri = Uri.parse('mailto:$address?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      GlobalToast.error(ErrorStrings.noEmailApp);
    }
  }

  String _diagnosticsText() {
    final p = widget.payload;
    final lines = <String>[
      if (p?.code != null) 'Code: ${p!.code}',
      if (p?.title != null) 'Title: ${p!.title}',
      if (p?.message != null) 'Message: ${p!.message}',
      // ISO-8601 with the UTC offset: unambiguous and sortable, which
      // matters more than prettiness in a support ticket.
      'Time: ${_occurredAt.toIso8601String()} (UTC${_utcOffset(_occurredAt)})',
      if (_info != null)
        'App: ${_info!.appName} ${_info!.version}+${_info!.buildNumber}',
      'Platform: ${defaultTargetPlatform.name}',
      'Online: $_online',
      if (p?.error != null) '\nError:\n${p!.error}',
      if (p?.stack != null) '\nStack:\n${p!.stack}',
    ];
    return lines.join('\n');
  }

  static String _utcOffset(DateTime at) {
    final offset = at.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final abs = offset.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final st = context.statusColors;
    final spacing = context.spacing;
    final p = widget.payload;
    final title = (p?.title?.isNotEmpty ?? false)
        ? p!.title!
        : CommonStrings.somethingWentWrong;
    final message = (p?.message?.isNotEmpty ?? false)
        ? p!.message!
        : ErrorStrings.defaultMessage;

    return Scaffold(
      appBar: SystemPageAppBar(title: CommonStrings.error),
      body: SafeArea(
        child: GlobalContainer.prose(
          child: SystemPageEntrance(
            enabled: !MediaQuery.disableAnimationsOf(context),
            child: GlobalScrollable(
              padding: EdgeInsets.all(spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: spacing.sm),
                  Center(
                    child: SystemPageBadge(
                      icon: Icons.warning_amber_rounded,
                      color: st.error,
                    ),
                  ),
                  SizedBox(height: spacing.md + spacing.xs),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tx.primary,
                      letterSpacing: -0.3,
                    ),
                  ).asHeader(),
                  SizedBox(height: spacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: tx.secondary,
                    ),
                  ),
                  if (!_online) ...[
                    SizedBox(height: spacing.md),
                    const _OfflineHint(),
                  ],
                  if (p?.code?.isNotEmpty ?? false) ...[
                    SizedBox(height: spacing.md),
                    Center(child: _CodeChip(code: p!.code!)),
                  ],
                  SizedBox(height: spacing.lg),
                  GlobalFilledButton(
                    text: _canRetry ? CommonStrings.retry : NavStrings.goHome,
                    onPressed: _retry,
                    icon: _canRetry
                        ? Icons.refresh_rounded
                        : Icons.home_rounded,
                  ),
                  // Reporting needs something TO report. With no payload
                  // the handler returned immediately, leaving a button
                  // that silently did nothing.
                  if (p != null) ...[
                    SizedBox(height: spacing.sm + 2),
                    GlobalOutlinedButton(
                      text: _reported
                          ? ErrorStrings.reportSent
                          : ErrorStrings.reportThis,
                      onPressed: _reported || _reporting ? null : _report,
                      isLoading: _reporting,
                      icon: _reported
                          ? Icons.check_circle_outline_rounded
                          : Icons.bug_report_outlined,
                    ),
                  ],
                  SizedBox(height: spacing.sm + 2),
                  // shrinkWidth: without it every button fills the row and
                  // the Wrap never wraps — three stacked bars instead of a
                  // tidy tertiary row.
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: spacing.sm,
                    runSpacing: spacing.xs,
                    children: [
                      GlobalTextButton(
                        text: ErrorStrings.copyDiagnostics,
                        onPressed: _copyDiagnostics,
                        shrinkWidth: true,
                        icon: Icons.content_copy_rounded,
                      ),
                      GlobalTextButton(
                        text: ErrorStrings.emailSupport,
                        onPressed: _emailSupport,
                        shrinkWidth: true,
                        icon: Icons.mail_outline_rounded,
                      ),
                      // Only when the primary is a real retry — otherwise
                      // this is the same action twice.
                      if (_canRetry)
                        GlobalTextButton(
                          text: NavStrings.goHome,
                          onPressed: () => context.go(AppRoutes.splash.path),
                          shrinkWidth: true,
                          icon: Icons.home_rounded,
                        ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  _DiagnosticsPanel(text: _diagnosticsText()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _OfflineHint extends StatelessWidget {
  const _OfflineHint();

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final st = context.statusColors;
    final bg = context.backgroundColors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.sm + spacing.xs),
      decoration: BoxDecoration(
        color: bg.cardBackground,
        border: Border.all(color: st.warning.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(context.radii.md),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.wifi_off_rounded,
              color: st.warning,
              size: context.iconSizes.md,
            ),
          ),
          SizedBox(width: spacing.sm + 2),
          Expanded(
            child: Text(
              ErrorStrings.offlineHint,
              style: context.textTheme.bodySmall?.copyWith(color: tx.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final bg = context.backgroundColors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm + spacing.xs,
        vertical: spacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg.outlineVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(context.radii.full),
        border: Border.all(color: bg.outlineVariant),
      ),
      // Support tickets quote this code — let it be selected directly.
      child: SelectableText(
        code,
        style: context.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          color: tx.secondary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    // Always available. In debug it's expanded by default for
    // visibility; in release it's collapsed so users aren't dumped
    // a stack trace they don't understand.
    final bg = context.backgroundColors;
    final tx = context.textColors;
    final spacing = context.spacing;
    // `AppExpansionTile` over `ExpansionTile`: the panel then wears the
    // app's own corner, fill and shadow instead of Material's, and a
    // rebrand moves it with every other surface. It also removes the
    // `Theme` override and the transparency `Material` that were only
    // there to stop Material's own tile painting its dividers and its
    // ink on the wrong canvas.
    return AppExpansionTile(
      initiallyExpanded: kDebugMode,
      leading: Icon(
        Icons.terminal_rounded,
        size: context.iconSizes.sm,
        color: tx.secondary,
      ),
      title: ErrorStrings.diagnostics,
      style: ContainerStyle(
        backgroundColor: bg.cardBackground,
        border: Border.all(color: bg.outlineVariant),
        borderRadius: BorderRadius.circular(context.radii.md),
        padding: EdgeInsets.all(spacing.md),
        shadow: const [],
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(spacing.sm + 2),
        decoration: BoxDecoration(
          color: bg.outlineVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(context.radii.sm),
        ),
        child: SelectableText(
          text,
          style: context.textTheme.labelSmall?.copyWith(
            fontFamily: 'monospace',
            height: 1.5,
            color: tx.secondary,
          ),
        ),
      ),
    );
  }
}
