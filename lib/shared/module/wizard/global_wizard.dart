import 'package:flutter/material.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/wizard_strings.dart';
import '../../../core/navigation/transitions/route_transition.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../buttons/global_outlined_button.dart';
import '../chip/global_chip.dart';
import '../dialog/global_dialog.dart';
import '../divider/global_divider.dart';
import '../indicator/global_indicator.dart';
import '../progress/global_progress.dart';
import '../scrollable/global_scrollable.dart';
import '../sheet/global_sheet.dart';
import '../stepper/global_stepper.dart';
import '../toast/global_toast.dart';
import 'wizard_controller.dart';
import 'wizard_models.dart';

export 'wizard_controller.dart';
export 'wizard_models.dart';

/// Multi-step form wizard. Drives a [WizardController]:
///   * variant-driven progress header (dots / linear / numbered /
///     chips / vertical via `GlobalStepper`)
///   * animated step transitions (slide / fade / scale / hero)
///   * per-step validators (Next disabled until valid)
///   * async submit with loading button + error rollback
///   * optional draft persistence via `WizardDraftsCubit`
///
/// Use the static [show] / [pushFullPage] / [showBottomSheet] /
/// [showDialog] helpers to mount adaptively, or drop the widget
/// inline (e.g. inside a tab).
class GlobalWizard extends StatefulWidget {
  const GlobalWizard({
    super.key,
    required this.steps,
    required this.onCompleted,
    this.controller,
    this.style = const WizardStyle(),
    this.draftKey,
    this.onCancelled,
    this.onStepChanged,
    this.initialData,
    this.title,
    this.subtitle,
  });

  final List<WizardStep> steps;

  /// Async submit handler. Throw to surface as error in the wizard
  /// footer (button re-enables, error chip appears).
  final Future<void> Function(Map<String, dynamic> data) onCompleted;

  /// Caller-owned controller. When null, the widget creates one
  /// scoped to its lifetime.
  final WizardController? controller;

  final WizardStyle style;

  /// Survives app kill — see [WizardDraftsCubit].
  final String? draftKey;

  /// Cancel callback. Routed by the close button + (sometimes) the
  /// Back-from-first-step gesture depending on style.
  final VoidCallback? onCancelled;

  final ValueChanged<int>? onStepChanged;

  final Map<String, dynamic>? initialData;

  /// Optional headline shown above the stepper.
  final String? title;
  final String? subtitle;

  // ─── Adaptive presentation helpers ──────────────────────────

  /// Picks presentation by window size.
  static Future<void> show({
    required BuildContext context,
    required List<WizardStep> steps,
    required Future<void> Function(Map<String, dynamic>) onCompleted,
    WizardStyle style = const WizardStyle(),
    String? draftKey,
    String? title,
    String? subtitle,
    WizardPresentation presentation = WizardPresentation.adaptive,
    Map<String, dynamic>? initialData,
  }) async {
    final resolved = presentation == WizardPresentation.adaptive
        ? _adaptivePick(context)
        : presentation;
    switch (resolved) {
      case WizardPresentation.fullPage:
        return pushFullPage(
          context: context,
          steps: steps,
          onCompleted: onCompleted,
          style: style,
          draftKey: draftKey,
          title: title,
          subtitle: subtitle,
          initialData: initialData,
        );
      case WizardPresentation.bottomSheet:
        return showAsBottomSheet(
          context: context,
          steps: steps,
          onCompleted: onCompleted,
          style: style,
          draftKey: draftKey,
          title: title,
          subtitle: subtitle,
          initialData: initialData,
        );
      case WizardPresentation.dialog:
        return showAsDialog(
          context: context,
          steps: steps,
          onCompleted: onCompleted,
          style: style,
          draftKey: draftKey,
          title: title,
          subtitle: subtitle,
          initialData: initialData,
        );
      case WizardPresentation.adaptive:
        return; // unreachable — resolved above
    }
  }

  static WizardPresentation _adaptivePick(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return WizardPresentation.bottomSheet;
    if (w < 1200) return WizardPresentation.dialog;
    return WizardPresentation.fullPage;
  }

  static Future<void> pushFullPage({
    required BuildContext context,
    required List<WizardStep> steps,
    required Future<void> Function(Map<String, dynamic>) onCompleted,
    WizardStyle style = const WizardStyle(),
    String? draftKey,
    String? title,
    String? subtitle,
    Map<String, dynamic>? initialData,
  }) async {
    await Navigator.of(context).push(
      // The APP's transition, not Material's — a wizard opened this way
      // used to arrive differently from every other page, and pull back
      // from the wrong edge in Arabic.
      RouteTransition.route<void>(
        context: context,
        name: 'wizard',
        child: Builder(
          builder: (ctx) => Scaffold(
            appBar: AppBar(title: Text(title ?? 'Wizard')),
            body: GlobalWizard(
              steps: steps,
              onCompleted: onCompleted,
              style: style,
              draftKey: draftKey,
              title: title,
              subtitle: subtitle,
              initialData: initialData,
              // The wizard's own context, so cancelling pops the route
              // it is IN rather than the one that opened it.
              onCancelled: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showAsBottomSheet({
    required BuildContext context,
    required List<WizardStep> steps,
    required Future<void> Function(Map<String, dynamic>) onCompleted,
    WizardStyle style = const WizardStyle(),
    String? draftKey,
    String? title,
    String? subtitle,
    Map<String, dynamic>? initialData,
  }) async {
    await GlobalBottomSheet.show<void>(
      context: context,
      title: title ?? 'Wizard',
      subtitle: subtitle,
      style: const SheetStyle(floating: true),
      maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      content: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: GlobalWizard(
          steps: steps,
          onCompleted: onCompleted,
          style: style,
          draftKey: draftKey,
          initialData: initialData,
          onCancelled: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  static Future<void> showAsDialog({
    required BuildContext context,
    required List<WizardStep> steps,
    required Future<void> Function(Map<String, dynamic>) onCompleted,
    WizardStyle style = const WizardStyle(),
    String? draftKey,
    String? title,
    String? subtitle,
    Map<String, dynamic>? initialData,
  }) async {
    await GlobalDialog.builder<void>(
      context,
      builder: (ctx) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: GlobalWizard(
          steps: steps,
          onCompleted: onCompleted,
          style: style,
          draftKey: draftKey,
          title: title,
          subtitle: subtitle,
          initialData: initialData,
          onCancelled: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<GlobalWizard> createState() => _GlobalWizardState();
}

class _GlobalWizardState extends State<GlobalWizard> {
  late WizardController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = WizardController(
        steps: widget.steps,
        draftKey: widget.draftKey,
        initialData: widget.initialData,
      );
      _ownsController = true;
    }
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
    widget.onStepChanged?.call(_controller.currentStep);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  // ─── Navigation handlers ────────────────────────────────────

  Future<void> _handleNext() async {
    if (_controller.isLast) {
      await _handleSubmit();
      return;
    }
    _controller.next();
  }

  Future<void> _handleSubmit() async {
    final ok = await _controller.submit(widget.onCompleted);
    if (!ok && mounted) {
      GlobalToast.e(
        WizardStrings.submitFailed,
        description: '${_controller.submitError}',
      );
    }
  }

  void _handleBack() {
    if (_controller.isFirst) {
      widget.onCancelled?.call();
      return;
    }
    _controller.back();
  }

  Future<void> _handleClose() async {
    if (widget.draftKey != null &&
        widget.style.confirmDiscardDraftOnCancel &&
        _controller.data.isNotEmpty) {
      final discard = await GlobalDialog.confirm(
        context: context,
        title: WizardStrings.discardDraftTitle,
        message: WizardStrings.discardDraftBody,
        confirmText: WizardStrings.discard,
        cancelText: WizardStrings.keepDraft,
      );
      if (discard) _controller.reset();
    }
    widget.onCancelled?.call();
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = widget.style;

    final layout = style.variant == WizardVariant.vertical
        ? _buildVertical(context, cs)
        : _buildHorizontal(context, cs);

    Widget body = ColoredBox(
      color: style.background ?? cs.surface,
      child: layout,
    );

    if (style.borderRadius != null) {
      body = ClipRRect(borderRadius: style.borderRadius!, child: body);
    }
    return body;
  }

  Widget _buildHorizontal(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null || widget.subtitle != null)
          Padding(
            padding: widget.style.headerPadding,
            child: _Header(
              title: widget.title,
              subtitle: widget.subtitle,
              onClose: widget.onCancelled == null ? null : _handleClose,
            ),
          ),
        Padding(
          padding: widget.style.headerPadding,
          child: _buildIndicator(context),
        ),
        Expanded(
          child: _buildBody(context),
        ),
        Padding(
          padding: widget.style.footerPadding,
          child: _buildFooter(context),
        ),
      ],
    );
  }

  Widget _buildVertical(BuildContext context, ColorScheme cs) {
    // Vertical: stepper on the left rail, body + footer on the right.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 200,
          child: ColoredBox(
            color: cs.surfaceContainer,
            child: Padding(
              padding: widget.style.headerPadding,
              child: _buildIndicator(context),
            ),
          ),
        ),
        GlobalDivider.vertical(),
        Expanded(
          child: Column(
            children: [
              if (widget.title != null || widget.subtitle != null)
                Padding(
                  padding: widget.style.headerPadding,
                  child: _Header(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    onClose: widget.onCancelled == null ? null : _handleClose,
                  ),
                ),
              Expanded(child: _buildBody(context)),
              Padding(
                padding: widget.style.footerPadding,
                child: _buildFooter(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Indicator (stepper header) ─────────────────────────────

  Widget _buildIndicator(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = _controller.steps;
    final current = _controller.currentStep;
    switch (widget.style.variant) {
      case WizardVariant.dots:
        return Align(
          alignment: Alignment.center,
          child: GlobalDotIndicator(
            count: steps.length,
            activeIndex: current,
            effect: DotIndicatorEffect.expanding,
            onTap: (i) => _controller.goTo(
              i,
              allowJumpToCompleted: widget.style.allowJumpToCompleted,
            ),
          ),
        );
      case WizardVariant.linear:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Step ${current + 1} of ${steps.length}'
                '${widget.style.showStepLabels ? " · ${steps[current].title}" : ""}',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GlobalProgress.linear(
              value: (current + 1) / steps.length,
              style: const ProgressStyle(thickness: 6),
            ),
          ],
        );
      case WizardVariant.numbered:
        return GlobalStepper(
          steps: [
            for (var i = 0; i < steps.length; i++)
              GlobalStepItem(
                title: widget.style.showStepLabels ? steps[i].title : '',
                isActive: i == current,
                isCompleted: i < current,
                icon: steps[i].icon,
              ),
          ],
          currentStep: current,
          onStepTapped: (i) => _controller.goTo(
            i,
            allowJumpToCompleted: widget.style.allowJumpToCompleted,
          ),
        );
      case WizardVariant.chips:
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var i = 0; i < steps.length; i++)
              GlobalChip(
                label: '${i + 1}. ${steps[i].title}',
                selected: i == current,
                // A step you have not reached is not selectable, and a
                // chip with no onSelected stops announcing itself as a
                // button you could press.
                onSelected: i <= current
                    ? (_) => _controller.goTo(
                        i,
                        allowJumpToCompleted: widget.style.allowJumpToCompleted,
                      )
                    : null,
              ),
          ],
        );
      case WizardVariant.vertical:
        return GlobalStepper(
          orientation: StepperOrientation.vertical,
          steps: [
            for (var i = 0; i < steps.length; i++)
              GlobalStepItem(
                title: steps[i].title,
                subtitle: steps[i].subtitle,
                isActive: i == current,
                isCompleted: i < current,
                icon: steps[i].icon,
              ),
          ],
          currentStep: current,
          onStepTapped: (i) => _controller.goTo(
            i,
            allowJumpToCompleted: widget.style.allowJumpToCompleted,
          ),
        );
    }
  }

  // ─── Body (animated step) ────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    final step = _controller.currentStepModel;
    final body = Padding(
      padding: widget.style.bodyPadding,
      child: KeyedSubtree(
        key: ValueKey(step.id),
        child: step.builder(
          context,
          _controller.data,
          _controller.setData,
        ),
      ),
    );

    final inner = widget.style.scrollable
        ? GlobalScrollable(child: body)
        : body;
    return _transition(child: inner);
  }

  Widget _transition({required Widget child}) {
    final dur = widget.style.transitionDuration;
    switch (widget.style.transition) {
      case WizardTransition.none:
        return child;
      case WizardTransition.fade:
        return AnimatedSwitcher(
          duration: dur,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: child,
        );
      case WizardTransition.slide:
        return AnimatedSwitcher(
          duration: dur,
          transitionBuilder: (c, a) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.15, 0),
              end: Offset.zero,
            ).animate(a),
            child: c,
          ),
          child: child,
        );
      case WizardTransition.slideAndFade:
        return AnimatedSwitcher(
          duration: dur,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.12, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                  ),
              child: c,
            ),
          ),
          child: child,
        );
      case WizardTransition.scale:
        return AnimatedSwitcher(
          duration: dur,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(a),
              child: c,
            ),
          ),
          child: child,
        );
      case WizardTransition.hero:
        // Hero-style — caller wires Hero(tag:) in step bodies. Our
        // crossfade renders the wrapping shell while Hero handles
        // matching widgets.
        return AnimatedSwitcher(
          duration: dur,
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: child,
        );
    }
  }

  // ─── Footer (back / next / submit / cancel) ──────────────────

  Widget _buildFooter(BuildContext context) {
    final style = widget.style;
    final isLast = _controller.isLast;
    final canGo = _controller.canAdvance;
    final showBack = !_controller.isFirst || style.showBackOnFirstStep;
    return Row(
      children: [
        if (showBack)
          Expanded(
            child: GlobalOutlinedButton(
              text: _controller.isFirst
                  ? (style.cancelLabel ?? CommonStrings.cancel)
                  : (style.backLabel ?? WizardStrings.back),
              enabled: !_controller.isSubmitting,
              onPressed: _handleBack,
            ),
          ),
        if (showBack) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GlobalFilledButton(
            text: isLast
                ? (style.submitLabel ?? WizardStrings.submit)
                : (style.nextLabel ?? WizardStrings.next),
            isLoading: _controller.isSubmitting,
            enabled: canGo && !_controller.isSubmitting,
            onPressed: _handleNext,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.title, this.subtitle, this.onClose});
  final String? title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onClose != null)
          GlobalIconButton(
            iconData: Icons.close_rounded,
            onPressed: onClose,
            tooltip: CommonStrings.close,
            semanticLabel: CommonStrings.close,
          ),
      ],
    );
  }
}
