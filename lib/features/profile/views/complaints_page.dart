import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/complaint_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/account/complaint.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/drop_down/index.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/text_field/global_text_field.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/complaints_cubit.dart';

/// «تواصل معنا» — telling the studio something went wrong, and what
/// came of it.
///
/// TWO halves on one screen, because they are the same conversation:
/// the form at the top, everything already said underneath.
///
/// **Filing is public; listing is not.** `POST /api/complaints` takes a
/// complaint from a signed-out visitor — who then has to say who they
/// are — while `GET /api/complaints` is the caller's own list and needs
/// a session. So a guest sees the form and no history, which is the
/// truth rather than an empty state.
///
/// The message REFUSES HTML rather than stripping it (`NoHtml`), so the
/// server's own refusal is shown under the box it came from.
class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({this.cubit, super.key});

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final ComplaintsCubit? cubit;

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late final _complaints = widget.cubit ?? ComplaintsCubit();

  final _message = TextEditingController();
  final _reference = TextEditingController();
  final _name = TextEditingController();
  final _contact = TextEditingController();

  ComplaintType _type = ComplaintType.order;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only for someone who HAS an account: the list is the caller's
    // own, and asking for it signed out is a 401 that says nothing.
    if (_loaded || !AuthGate.has(context)) return;
    _loaded = true;
    unawaited(_complaints.load());
  }

  @override
  void dispose() {
    if (widget.cubit == null) unawaited(_complaints.close());
    _message.dispose();
    _reference.dispose();
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final signedIn = AuthGate.has(context);

    final sent = await _complaints.send(
      type: _type.wire,
      message: _message.text,
      reference: _reference.text.trim().isEmpty ? null : _reference.text,
      // The server takes these from the ACCOUNT when there is one and
      // ignores what is sent — so a signed-in caller must not send
      // them, or the 422 lands on boxes this form is not showing.
      name: signedIn ? null : _name.text,
      contact: signedIn ? null : _contact.text,
    );
    if (!mounted || !sent) return;

    _message.clear();
    _reference.clear();
    GlobalToast.success(ComplaintStrings.sent);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final signedIn = AuthGate.has(context);

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: TerracottaPageBar(title: ComplaintStrings.title),
      body: BlocBuilder<ComplaintsCubit, ComplaintsState>(
        bloc: _complaints,
        builder: (context, state) => GlobalRefreshable(
          onRefresh: signedIn ? _complaints.load : () async {},
          child: GlobalScrollable(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: spacing.md),
                  Text(
                    ComplaintStrings.newOne,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.textColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  GlobalDropdownFormField<ComplaintType>(
                    hint: ComplaintStrings.type,
                    identifier: ComplaintStrings.type,
                    initialValue: _type,
                    items: [
                      for (final type in ComplaintType.values)
                        DropdownItem(
                          value: type,
                          label: ComplaintStrings.kind(type),
                        ),
                    ],
                    onChanged: (type) =>
                        setState(() => _type = type ?? ComplaintType.other),
                  ),
                  SizedBox(height: spacing.md),
                  GlobalTextFormField(
                    controller: _reference,
                    identifier: ComplaintStrings.reference,
                    hint: ComplaintStrings.referenceHint,
                    validation: TextFieldValidation(
                      errorText: state.fieldErrors['reference'],
                      showErrorImmediately: true,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  GlobalTextFormField(
                    controller: _message,
                    identifier: ComplaintStrings.message,
                    hint: ComplaintStrings.messageHint,
                    required: true,
                    behavior: const TextFieldBehavior(
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 3,
                    ),
                    validation: TextFieldValidation(
                      // The server's own words — and one of them is
                      // that HTML is refused, not stripped.
                      errorText: state.fieldErrors['message'],
                      showErrorImmediately: true,
                    ),
                  ),
                  // A visitor with no account has to say how to reach
                  // them; someone signed in already has.
                  if (!signedIn) ...[
                    SizedBox(height: spacing.md),
                    GlobalTextFormField(
                      controller: _name,
                      identifier: ComplaintStrings.name,
                      hint: ComplaintStrings.name,
                      required: true,
                      validation: TextFieldValidation(
                        errorText: state.fieldErrors['name'],
                        showErrorImmediately: true,
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    GlobalTextFormField(
                      controller: _contact,
                      identifier: ComplaintStrings.contact,
                      hint: ComplaintStrings.contact,
                      required: true,
                      validation: TextFieldValidation(
                        errorText: state.fieldErrors['contact'],
                        showErrorImmediately: true,
                      ),
                    ),
                  ],
                  SizedBox(height: spacing.lg),
                  GlobalFilledButton(
                    text: ComplaintStrings.send,
                    isLoading: state.sending,
                    onPressed: () => unawaited(_send()),
                  ),
                  SizedBox(height: spacing.xl),
                  if (signedIn) ...[
                    Text(
                      ComplaintStrings.mine,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.textColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    _Filed(state: state),
                  ],
                  SizedBox(height: spacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything already said, newest first.
class _Filed extends StatelessWidget {
  const _Filed({required this.state});

  final ComplaintsState state;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (state.loading && state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (state.items.isEmpty) {
      return GlobalEmptyState(
        icon: state.error != null
            ? Icons.wifi_off_rounded
            : Icons.forum_outlined,
        title: state.error != null
            ? AuthStrings.errorGeneric
            : ComplaintStrings.empty,
        subtitle: state.error != null ? null : ComplaintStrings.emptyBody,
        variant: EmptyStateVariant.compact,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // STAGGERED. The rows arrive one after another as the screen
      // settles, rather than the whole block appearing at once.
      children: ScreenEntrance.stage([
        for (final complaint in state.items) ...[
          _Row(complaint: complaint),
          SizedBox(height: spacing.sm),
        ],
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).toString();
    final open = complaint.statusKind.isOpen;

    return TerracottaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ComplaintStrings.kind(complaint.kind),
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.textColors.primary,
                  ),
                ),
              ),
              StatusChip(
                label: ComplaintStrings.status(complaint.statusKind),
                // Open is the studio's colour; done is the mint every
                // other finished thing wears.
                color: open
                    ? context.primaryColors.primary
                    : context.statusColors.success,
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Text(
            complaint.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            DateFormat.yMMMd(locale).format(complaint.createdAt),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
