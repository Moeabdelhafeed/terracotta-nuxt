import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/a11y/semantics_extensions.dart';
import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/coming_soon_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/field_strings.dart';
import '../../../core/localization/strings/nav_strings.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../common/text_form_fields/text_form_fields.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_text_button.dart';
import '../container/global_container.dart';
import '../scrollable/global_scrollable.dart';
import '../toast/global_toast.dart';
import 'system_page_parts.dart';

/// Generic "this feature is on the roadmap" landing page.
///
/// Pass a feature name + optional ETA in the route query:
///   `/coming-soon?feature=Analytics&eta=Q3+2026`
///
/// The notify-me capture is optional — set [showNotifyForm] to `false`
/// (or `&notify=false` on the route) for apps with no waiting-list
/// backend, and the page degrades to badge + copy + back link.
///
/// When shown, the default handler logs the request — wire to your CRM /
/// waiting-list endpoint by passing [onNotifyRequested] from the outside
/// (or do the wire-up at `SystemNavigation.toComingSoon`).
class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage({
    this.feature,
    this.eta,
    this.onNotifyRequested,
    this.showNotifyForm = true,
    super.key,
  });

  final String? feature;
  final String? eta;
  final Future<void> Function(String email, String? feature)? onNotifyRequested;

  /// Show the email capture + "Notify me" button. `false` drops both —
  /// the page still explains what is coming and offers the way back.
  final bool showNotifyForm;

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final email = _emailCtrl.text.trim();
    final handler = widget.onNotifyRequested ?? _defaultHandler;
    try {
      await handler(email, widget.feature);
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submitting = false;
      });
      // The form is replaced by a card — without an explicit
      // announcement a screen-reader user gets no confirmation that
      // anything happened.
      announceForAccessibility(context, ComingSoonStrings.successTitle);
    } catch (e, st) {
      Logger.m.e('[ComingSoon] notify-me failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _submitting = false);
      GlobalToast.error(ComingSoonStrings.saveFailed);
    }
  }

  Future<void> _defaultHandler(String email, String? feature) async {
    // Stub. Replace by passing `onNotifyRequested` or by editing
    // `SystemNavigation.toComingSoon` to inject your own callback.
    Logger.m.i('[ComingSoon] notify-me: feature=$feature, email=$email');
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _reset() {
    setState(() {
      _submitted = false;
      _emailCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final btn = context.buttonsColors;
    final spacing = context.spacing;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final feature = widget.feature?.trim().isNotEmpty == true
        ? widget.feature!.trim()
        : ComingSoonStrings.thisFeature;
    final eta = widget.eta?.trim();
    final hasEta = eta?.isNotEmpty ?? false;

    return Scaffold(
      appBar: SystemPageAppBar(title: ComingSoonStrings.title),
      body: SafeArea(
        // .form (not .prose): this page's centrepiece is a form, and at
        // reading width the email field stretches far past its content.
        child: GlobalContainer.form(
          child: Center(
            child: GlobalScrollable(
              // A form page with the keyboard up should let a drag
              // dismiss it rather than trapping the user.
              style: const ScrollableStyle(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
              ),
              padding: EdgeInsets.all(spacing.lg),
              child: SystemPageEntrance(
                enabled: !reduceMotion,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SystemPageBadge(
                      icon: Icons.rocket_launch_rounded,
                      color: btn.primary,
                    ),
                    SizedBox(height: spacing.lg),
                    Text(
                      ComingSoonStrings.featureOnTheWay(feature),
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tx.primary,
                        letterSpacing: -0.4,
                      ),
                    ).asHeader(),
                    if (hasEta) ...[
                      SizedBox(height: spacing.sm + spacing.xs),
                      _EtaPill(eta: eta!),
                    ],
                    SizedBox(height: spacing.sm),
                    Text(
                      widget.showNotifyForm
                          ? ComingSoonStrings.body
                          : ComingSoonStrings.bodyPlain,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: tx.secondary,
                      ),
                    ),
                    if (widget.showNotifyForm) ...[
                      SizedBox(height: spacing.lg + spacing.xs),
                      AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : AppDurations.normal,
                        child: _submitted
                            ? _SuccessCard(
                                key: const ValueKey('success'),
                                email: _emailCtrl.text.trim(),
                                onChangeEmail: _reset,
                              )
                            : _NotifyForm(
                                key: const ValueKey('form'),
                                formKey: _formKey,
                                controller: _emailCtrl,
                                submitting: _submitting,
                                onSubmit: _submit,
                              ),
                      ),
                    ],
                    SizedBox(height: spacing.md),
                    GlobalTextButton(
                      text: NavStrings.backToHome,
                      onPressed: () => context.go(AppRoutes.splash.path),
                      shrinkWidth: true,
                      icon: Icons.home_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Surfaces the ETA as its own object instead of burying it mid-sentence
/// — it is the one piece of hard information this page carries.
class _EtaPill extends StatelessWidget {
  const _EtaPill({required this.eta});

  final String eta;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final btn = context.buttonsColors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm + spacing.xs,
        vertical: spacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: btn.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(context.radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_rounded,
            size: context.iconSizes.sm,
            color: btn.primary,
          ),
          SizedBox(width: spacing.xs + 2),
          Text(
            '${ComingSoonStrings.etaLabel} · $eta',
            style: context.textTheme.labelLarge?.copyWith(
              color: tx.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifyForm extends StatelessWidget {
  const _NotifyForm({
    required this.formKey,
    required this.controller,
    required this.submitting,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool submitting;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          EmailField(
            controller: controller,
            label: FieldStrings.emailLabel,
            enabled: !submitting,
            prefixIcon: Icons.alternate_email_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          SizedBox(height: context.spacing.sm + context.spacing.xs),
          // GlobalFilledButton is fill-width by default — no SizedBox.
          GlobalFilledButton(
            text: submitting
                ? CommonStrings.saving
                : ComingSoonStrings.notifyMe,
            onPressed: submitting ? null : onSubmit,
            isLoading: submitting,
            icon: Icons.notifications_active_outlined,
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.email,
    required this.onChangeEmail,
    super.key,
  });

  final String email;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final st = context.statusColors;
    final bg = context.backgroundColors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: bg.cardBackground,
        border: Border.all(color: st.success.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(context.radii.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: st.success,
                  size: context.iconSizes.lg,
                ),
              ),
              SizedBox(width: spacing.sm + spacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ComingSoonStrings.successTitle,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tx.primary,
                      ),
                    ),
                    SizedBox(height: spacing.xs / 2),
                    Text(
                      ComingSoonStrings.successBody(email),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: tx.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GlobalTextButton(
              text: ComingSoonStrings.changeEmail,
              onPressed: onChangeEmail,
              // A footnote inside a card: link presentation keeps it
              // from competing with real buttons.
              link: true,
              underline: LinkUnderline.onHover,
            ),
          ),
        ],
      ),
      // Announced as a unit when it replaces the form.
    ).asLiveRegion();
  }
}
