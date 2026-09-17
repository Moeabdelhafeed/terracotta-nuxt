import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/connectivity/connectivity_cubit.dart';
import '../../../core/connectivity/offline_action.dart';
import '../../../core/connectivity/offline_action_queue.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/feedback/feedback_diagnostics.dart';
import '../../../core/feedback/feedback_options.dart';
import '../../../core/feedback/feedback_payload.dart';
import '../../../core/feedback/feedback_strings.dart';
import '../../../core/feedback/feedback_submitter.dart';
import '../../../core/feedback/feedback_type.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../../core/utils/validators/validators.dart';
import '../../../data/services/remote_config_service.dart';
import '../../common/text_form_fields/text_form_fields.dart';
import '../app_bar/global_app_bar.dart';
import '../buttons/global_filled_button.dart';
import '../chip/global_chip.dart';
import '../container/global_container.dart';
import '../media_picker/global_image_picker.dart';
import '../media_picker/media_picker_models.dart';
import '../media_picker/media_picker_style.dart';
import '../switch/global_switch.dart';
import 'feedback_style.dart';
import 'theme/feedback_theme.dart';

/// Drop-in feedback / bug-report screen.
///
/// ```dart
/// FeedbackScreen()                                      // RC-driven defaults
/// FeedbackScreen(options: FeedbackOptions(submitter: MailtoFeedbackSubmitter(toEmail: '...')))
/// ```
///
/// When `options.contentBuilder` is set, the screen hands off entirely
/// to the caller's UI; the builder still receives the `submit`
/// callback so the custom UI can drive submission.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    this.options = const FeedbackOptions(),
    this.style = const FeedbackStyle(),
    super.key,
  });

  /// What the form ASKS — types, fields, limits, the submitter.
  final FeedbackOptions options;

  /// How it LOOKS. Themeable through `GlobalFeedbackTheme`.
  final FeedbackStyle style;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static DateTime? _lastSubmittedAt;

  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _reproCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  late FeedbackPayload _draft;
  bool _submitting = false;
  FeedbackResult? _result;

  @override
  void initState() {
    super.initState();
    final attachDefault = RemoteConfigService.feedbackAttachDiagnosticsDefault;
    _draft = FeedbackPayload(
      type: widget.options.types.isEmpty
          ? FeedbackType.bug
          : widget.options.types.first,
      description: '',
      attachDiagnostics: attachDefault,
    );
    _bootstrapDiagnostics();
  }

  Future<void> _bootstrapDiagnostics() async {
    final diag = await FeedbackDiagnostics.collect(
      context: context,
      includeLogs: widget.options.collectLogs,
      logTailLines: widget.options.logTailLines,
    );
    if (!mounted) return;
    setState(() => _draft = _draft.copyWith(diagnostics: diag));
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _reproCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ─── Field updates ───────────────────────────────────────

  void _setType(FeedbackType t) => setState(
    () => _draft = _draft.copyWith(
      type: t,
      // Severity / repro only meaningful for bugs.
      severity: t == FeedbackType.bug ? _draft.severity : null,
    ),
  );

  void _setSeverity(FeedbackSeverity? s) =>
      setState(() => _draft = _draft.copyWith(severity: s));

  void _setAttachDiagnostics(bool v) =>
      setState(() => _draft = _draft.copyWith(attachDiagnostics: v));

  // ─── Attachments ─────────────────────────────────────────

  /// The picker hands back the whole list, already capped and already
  /// previewed. Two things are left for this screen: reading a
  /// freshly picked FILE into bytes, and the BUDGET — a screenshot
  /// straight off a modern phone is several megabytes, and
  /// `maxAttachmentBytes` is what keeps a bug report postable.
  Future<void> _setAttachments(List<PickerItem> items) async {
    final next = <FeedbackAttachment>[];
    for (final item in items) {
      final attachment = await _toAttachment(item);
      if (attachment == null) continue;
      next.add(
        attachment.bytes.length <= widget.options.maxAttachmentBytes
            ? attachment
            : await _compressed(attachment),
      );
    }
    if (!mounted) return;
    setState(() => _draft = _draft.copyWith(attachments: next));
  }

  /// One picker item as something the payload can post.
  ///
  /// A URL item is skipped: feedback sends BYTES to the submitter, and
  /// this screen is not going to fetch somebody else's image to do it.
  Future<FeedbackAttachment?> _toAttachment(PickerItem item) async {
    switch (item) {
      case PickerItemBytes(:final bytes, :final filename):
        return FeedbackAttachment(
          bytes: bytes,
          fileName: filename,
          mimeType: _mimeFor(filename),
        );
      case PickerItemFile(:final file):
        try {
          final name = file.uri.pathSegments.last;
          return FeedbackAttachment(
            bytes: await file.readAsBytes(),
            fileName: name,
            mimeType: _mimeFor(name),
          );
        } catch (e, st) {
          Logger.m.w(
            '[Feedback] attachment read failed',
            error: e,
            stackTrace: st,
          );
          return null;
        }
      case PickerItemUrl():
        return null;
    }
  }

  /// The payload needs a type to label the part in the request, and
  /// the name is all there is to go on.
  static String _mimeFor(String name) =>
      name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

  Future<FeedbackAttachment> _compressed(FeedbackAttachment a) async {
    try {
      final out = await FlutterImageCompress.compressWithList(
        a.bytes,
        quality: widget.options.compressQuality,
      );
      return a.bytes.length <= out.length
          ? a
          : FeedbackAttachment(
              bytes: Uint8List.fromList(out),
              fileName: a.fileName,
              mimeType: a.mimeType,
            );
    } catch (e, st) {
      Logger.m.w('[Feedback] compress failed', error: e, stackTrace: st);
      return a;
    }
  }

  // ─── Submission ──────────────────────────────────────────

  /// How many attachments this report may carry.
  ///
  /// Remote first, then the caller's, exactly as the cooldown
  /// resolves — it is the limit an operator most wants to move during
  /// an incident, and it was the one feedback setting that could only
  /// change in a release.
  int get _maxAttachments {
    final remote = RemoteConfigService.feedbackMaxAttachments;
    return remote > 0 ? remote : widget.options.maxAttachments;
  }

  Duration get _cooldown {
    final rcSeconds = RemoteConfigService.feedbackCooldownSeconds;
    return rcSeconds > 0
        ? Duration(seconds: rcSeconds)
        : widget.options.cooldown;
  }

  bool _withinCooldown() {
    final last = _lastSubmittedAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < _cooldown;
  }

  FeedbackSubmitter _resolveSubmitter() {
    final injected = widget.options.submitter;
    if (injected != null) return injected;
    final endpoint = RemoteConfigService.feedbackEndpoint;
    final email = RemoteConfigService.feedbackSupportEmail;
    if (endpoint.isEmpty) return MailtoFeedbackSubmitter(toEmail: email);
    return FallbackFeedbackSubmitter(
      primary: ApiFeedbackSubmitter(endpoint: endpoint),
      fallback: MailtoFeedbackSubmitter(toEmail: email),
    );
  }

  Future<FeedbackResult> _submit(FeedbackPayload draft) async {
    // Cooldown
    if (_withinCooldown()) return FeedbackResult.cooldown();

    setState(() => _submitting = true);

    // Offline → queue
    if (getIt.isRegistered<ConnectivityCubit>() &&
        getIt<ConnectivityCubit>().state.offline &&
        getIt.isRegistered<OfflineActionQueue>()) {
      await getIt<OfflineActionQueue>().enqueue(
        OfflineAction(
          id: 'feedback-${DateTime.now().microsecondsSinceEpoch}',
          kind: 'feedback.submit',
          label: draft.type.label,
          payload: draft.toJson(),
        ),
      );
      _lastSubmittedAt = DateTime.now();
      final r = FeedbackResult.queued();
      if (!mounted) return r;
      setState(() {
        _submitting = false;
        _result = r;
      });
      widget.options.onSubmitted?.call(draft, r);
      return r;
    }

    final submitter = _resolveSubmitter();
    final r = await submitter.submit(draft);
    _lastSubmittedAt = DateTime.now();
    if (!mounted) return r;
    setState(() {
      _submitting = false;
      _result = r;
    });
    widget.options.onSubmitted?.call(draft, r);
    return r;
  }

  void _onSubmitTapped() {
    if (!_formKey.currentState!.validate()) return;
    final next = _draft.copyWith(
      description: _descriptionCtrl.text.trim(),
      repro: _reproCtrl.text.trim().isEmpty ? null : _reproCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
    );
    setState(() => _draft = next);
    unawaited(_submit(next));
  }

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final opts = widget.options;
    // ONE resolve per build, handed down. Every leaf re-reading the
    // theme is the drift the bag exists to stop.
    final style = widget.style.resolve(context);
    if (!opts.enabled || !RemoteConfigService.feedbackEnabled) {
      return _Disabled(strings: opts.strings);
    }

    if (opts.contentBuilder != null) {
      return Scaffold(
        body: SafeArea(child: opts.contentBuilder!(context, _submit)),
      );
    }

    if (_result != null) {
      return Scaffold(
        body: SafeArea(
          child: GlobalContainer.prose(
            child:
                opts.resultBuilder?.call(context, _result!) ??
                _ResultView(
                  result: _result!,
                  strings: opts.strings,
                  style: style,
                ),
          ),
        ),
      );
    }

    return Scaffold(
      // `GlobalAppBar`, not Material's. It was the one bar in the app
      // wearing Material's own title size and surface, so the feedback
      // page read as a screen from a different app.
      appBar: GlobalAppBar(title: opts.strings.title),
      // `bottom: false`, and the inset moves into the list's own
      // padding instead. A `SafeArea` SHORTENS the viewport, so the
      // form stopped above the gesture bar with a dead strip under it
      // — the content should scroll under the inset and merely END
      // clear of it.
      body: SafeArea(
        bottom: false,
        child: GlobalContainer.prose(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: style.contentPadding.add(
                EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
              ),
              children: [
                opts.headerBuilder?.call(context) ??
                    _Header(strings: opts.strings),
                SizedBox(height: style.sectionGap),
                opts.fieldsBuilder?.call(context, _draft, _applyDraft) ??
                    _Fields(
                      style: style,
                      options: opts,
                      draft: _draft,
                      descriptionCtrl: _descriptionCtrl,
                      reproCtrl: _reproCtrl,
                      emailCtrl: _emailCtrl,
                      onTypeChanged: _setType,
                      onSeverityChanged: _setSeverity,
                      onAttachDiagnostics: _setAttachDiagnostics,
                      onAttachmentsChanged: _setAttachments,
                      maxAttachments: _maxAttachments,
                    ),
                const SizedBox(height: 24),
                opts.footerBuilder?.call(
                      context,
                      _submitting,
                      _onSubmitTapped,
                    ) ??
                    _Footer(
                      strings: opts.strings,
                      submitting: _submitting,
                      onSubmit: _onSubmitTapped,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyDraft(FeedbackPayload next) {
    setState(() => _draft = next);
  }
}

// ─────────────────────────────────────────────────────────────
// Pieces
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.strings});

  final FeedbackStrings strings;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.title,
            style: TextStyle(
              fontSize: context.textTheme.titleLarge?.fontSize,
              fontWeight: FontWeight.w700,
              color: tx.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: tx.secondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({
    required this.options,
    required this.draft,
    required this.descriptionCtrl,
    required this.reproCtrl,
    required this.emailCtrl,
    required this.onTypeChanged,
    required this.onSeverityChanged,
    required this.onAttachDiagnostics,
    required this.onAttachmentsChanged,
    required this.maxAttachments,
    required this.style,
  });

  /// The resolved look, passed DOWN rather than re-resolved in every
  /// leaf — one read per build, like the audio player's.
  final ResolvedFeedbackStyle style;

  final FeedbackOptions options;
  final FeedbackPayload draft;
  final TextEditingController descriptionCtrl;
  final TextEditingController reproCtrl;
  final TextEditingController emailCtrl;
  final ValueChanged<FeedbackType> onTypeChanged;
  final ValueChanged<FeedbackSeverity?> onSeverityChanged;
  final ValueChanged<bool> onAttachDiagnostics;
  final ValueChanged<List<PickerItem>> onAttachmentsChanged;
  final int maxAttachments;

  @override
  Widget build(BuildContext context) {
    final s = options.strings;
    final isBug = draft.type == FeedbackType.bug;
    final emailRequired = options.requireEmailFor.contains(draft.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(text: s.typeLabel),
        SizedBox(height: style.labelGap),
        _TypeChips(
          types: options.types,
          selected: draft.type,
          onChanged: onTypeChanged,
        ),
        if (options.showSeverity && isBug) ...[
          SizedBox(height: style.sectionGap),
          _SectionLabel(text: s.severityLabel),
          SizedBox(height: style.labelGap),
          _SeverityChips(
            selected: draft.severity,
            onChanged: onSeverityChanged,
          ),
        ],
        SizedBox(height: style.sectionGap),
        _SectionLabel(text: s.descriptionLabel),
        SizedBox(height: style.labelGap),
        MultilineTextField(
          controller: descriptionCtrl,
          hint: s.descriptionHint,
          minLines: 1,
          maxLines: 5,
          required: true,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? s.descriptionRequired : null,
        ),
        if (options.showRepro && isBug) ...[
          SizedBox(height: style.sectionGap),
          _SectionLabel(text: s.reproLabel),
          SizedBox(height: style.labelGap),
          MultilineTextField(
            controller: reproCtrl,
            hint: s.reproHint,
            minLines: 1,
            maxLines: 4,
          ),
        ],
        if (options.showEmail) ...[
          SizedBox(height: style.sectionGap),
          // Plain header — the field marks required (like the
          // description/repro sections); a manual star here double-marked
          // it once EmailField started appending its own.
          _SectionLabel(text: s.emailLabel),
          SizedBox(height: style.labelGap),
          EmailField(
            controller: emailCtrl,
            required: emailRequired,
            hint: s.emailHint,
            // Preserve the per-screen FeedbackStrings.emailInvalid
            // override (+ its remote-translation key) the wrapper's
            // default Validators message would otherwise silence.
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return emailRequired ? s.emailInvalid : null;
              return Validators.validateEmail(v) == null
                  ? null
                  : s.emailInvalid;
            },
          ),
        ],
        if (options.screenshotMode != FeedbackScreenshotMode.off) ...[
          SizedBox(height: style.sectionGap),
          _SectionLabel(text: s.attachmentsLabel),
          SizedBox(height: style.labelGap),
          _AttachmentsRow(
            style: style,
            options: options,
            attachments: draft.attachments,
            maxAttachments: maxAttachments,
            onChanged: onAttachmentsChanged,
          ),
        ],
        SizedBox(height: style.sectionGap),
        _DiagnosticsBlock(
          style: style,
          options: options,
          diagnostics: draft.diagnostics,
          attached: draft.attachDiagnostics,
          onChanged: onAttachDiagnostics,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: context.textTheme.labelSmall?.fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: tx.secondary,
      ),
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({
    required this.types,
    required this.selected,
    required this.onChanged,
  });
  final List<FeedbackType> types;
  final FeedbackType selected;
  final ValueChanged<FeedbackType> onChanged;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in types)
          GlobalChip(
            label: t.label,
            selected: t == selected,
            onSelected: (_) => onChanged(t),
          ),
      ],
    );
  }
}

class _SeverityChips extends StatelessWidget {
  const _SeverityChips({required this.selected, required this.onChanged});
  final FeedbackSeverity? selected;
  final ValueChanged<FeedbackSeverity?> onChanged;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in FeedbackSeverity.values)
          GlobalChip(
            label: s.label,
            selected: s == selected,
            onSelected: (sel) => onChanged(sel ? s : null),
          ),
      ],
    );
  }
}

/// The attachments row — `GlobalImagePicker`, not a hand-rolled one.
///
/// It used to be its own thumbnail strip, its own remove button and
/// its own three source buttons: a second, smaller media picker living
/// inside the feedback screen. The module already does the previews,
/// the remove, the cap, the validators and the semantics.
///
/// The bridge is `PickerItemBytes`. Feedback carries BYTES all the way
/// to the submitter — the payload has no file paths in it — and the
/// picker speaks that variant natively, so nothing needs writing to
/// disk to be shown.
class _AttachmentsRow extends StatelessWidget {
  const _AttachmentsRow({
    required this.options,
    required this.attachments,
    required this.maxAttachments,
    required this.onChanged,
    required this.style,
  });

  /// Resolved upstream: remote first, then the caller's.
  final int maxAttachments;

  final ResolvedFeedbackStyle style;
  final FeedbackOptions options;
  final List<FeedbackAttachment> attachments;

  /// The whole list, after the picker changed it — in the picker's
  /// own items, converted upstream where reading a file can be
  /// awaited.
  final ValueChanged<List<PickerItem>> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = options.strings;
    final mode = options.screenshotMode;
    // The picker always offers the gallery — there is no
    // `allowGallery` to turn off — so `camera` alone cannot be
    // expressed. It reads as "camera TOO", which is the only honest
    // mapping and the harmless direction to be wrong in.
    final allowCamera =
        !kIsWeb &&
        (mode == FeedbackScreenshotMode.camera ||
            mode == FeedbackScreenshotMode.all);

    return GlobalImagePicker(
      multiple: true,
      images: [
        for (final a in attachments)
          PickerItemBytes(a.bytes, filename: a.fileName),
      ],
      maxImages: maxAttachments,
      galleryLabel: s.pickGallery,
      cameraLabel: s.pickCamera,
      style: MediaPickerStyle(
        allowCamera: allowCamera,
        tileHeight: style.thumbSize,
        tileGap: style.thumbSpacing,
        tileRadius: style.thumbRadius,
      ),
      // The raw items go UP. A freshly picked image comes back as a
      // `PickerItemFile` — the plugin hands over a path — while what
      // is already attached comes back as the `PickerItemBytes` this
      // screen put in. Keeping only the bytes variant silently
      // dropped every gallery pick: the sheet closed, and nothing
      // appeared.
      onChanged: (value) =>
          onChanged((value as List<PickerItem>?) ?? const <PickerItem>[]),
    );
  }
}

class _DiagnosticsBlock extends StatelessWidget {
  const _DiagnosticsBlock({
    required this.options,
    required this.diagnostics,
    required this.attached,
    required this.onChanged,
    required this.style,
  });

  final FeedbackOptions options;
  final Map<String, dynamic> diagnostics;
  final bool attached;
  final ValueChanged<bool> onChanged;
  final ResolvedFeedbackStyle style;

  @override
  Widget build(BuildContext context) {
    final s = options.strings;
    final tx = context.textColors;
    final bg = context.backgroundColors;
    // ONE container, not a hand-rolled card wrapped around a
    // `GlobalExpandableContainer` that already draws its own. The
    // outer `Container` painted a second fill, a second corner and a
    // second border — so a rebrand moved the inner one and left this
    // card on its own numbers.
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: GlobalExpandableContainer(
        style: ContainerStyle(
          padding: EdgeInsets.all(style.labelGap + 4),
          shadow: const [],
          backgroundColor: bg.cardBackground,
          borderColor: bg.outlineVariant,
          borderRadius: BorderRadius.circular(style.thumbRadius + 4),
        ),
        header: Row(
          children: [
            Icon(Icons.terminal_rounded, size: 18, color: tx.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.diagnosticsLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: tx.primary,
                    ),
                  ),
                  Text(
                    s.diagnosticsHint,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: tx.secondary,
                    ),
                  ),
                ],
              ),
            ),
            GlobalSwitch.material(value: attached, onChanged: onChanged),
          ],
        ),
        child: diagnostics.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Collecting…',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: tx.secondary,
                  ),
                ),
              )
            : SelectableText(
                diagnostics.toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: context.textTheme.labelSmall?.fontSize,
                  color: tx.secondary,
                  height: 1.45,
                ),
              ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.strings,
    required this.submitting,
    required this.onSubmit,
  });

  final FeedbackStrings strings;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlobalFilledButton(
        text: submitting ? strings.submitting : strings.submit,
        onPressed: submitting ? null : onSubmit,
        isLoading: submitting,
        style: const ButtonStateStyle(
          leading: Icon(Icons.send_rounded),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.strings,
    required this.style,
  });

  final FeedbackResult result;
  final FeedbackStrings strings;
  final ResolvedFeedbackStyle style;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final st = context.statusColors;
    final (icon, color, title, body) = switch (result.kind) {
      FeedbackResultKind.success => (
        Icons.check_circle_rounded,
        st.success,
        strings.successTitle,
        strings.successBody,
      ),
      FeedbackResultKind.queuedOffline => (
        Icons.cloud_queue_rounded,
        st.warning,
        strings.offlineQueuedTitle,
        strings.offlineQueuedBody,
      ),
      FeedbackResultKind.cooldown => (
        Icons.timer_outlined,
        st.warning,
        strings.cooldownTitle,
        strings.cooldownHint,
      ),
      FeedbackResultKind.failure => (
        Icons.error_outline_rounded,
        st.error,
        strings.failureTitle,
        result.message ?? strings.failureBody,
      ),
    };
    return Padding(
      padding: style.contentPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          SizedBox(height: style.sectionGap),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.textTheme.titleLarge?.fontSize,
              fontWeight: FontWeight.w700,
              color: tx.primary,
            ),
          ),
          SizedBox(height: style.labelGap),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: tx.secondary,
              height: 1.5,
            ),
          ),
          if ((result.referenceId ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tx.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Ref ${result.referenceId}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: context.textTheme.bodySmall?.fontSize,
                  color: tx.secondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          GlobalFilledButton(
            text: CommonStrings.done,
            onPressed: () => Navigator.of(context).maybePop(),
            shrinkWidth: true,
          ),
        ],
      ),
    );
  }
}

class _Disabled extends StatelessWidget {
  const _Disabled({required this.strings});
  final FeedbackStrings strings;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(strings.disabled, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
