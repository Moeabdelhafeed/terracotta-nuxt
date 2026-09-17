import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/booking/booking_piece.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/text_field/global_text_field.dart';
import '../../_shared/terracotta_cta_style.dart';
import 'sheet_shell.dart';

/// Change one piece's NAME.
///
/// ## The same rule as naming it in the first place
///
/// A name is what the studio tells two pieces apart by, so a booking
/// cannot hold two of them. Matched case- and whitespace-insensitively
/// against every OTHER piece — «Test» and «test » are the same name to
/// everybody except a string comparison — and the piece being renamed
/// is excluded, or keeping your own name would read as a collision
/// with yourself.
///
/// ## What it calls, and the caveat
///
/// `WorkshopApis.renamePiece`, a PATCH on the piece. **That verb is
/// not in `/docs.openapi` yet** — the spec lists one create and two
/// deletes on a piece and nothing else, and `piece_labels[]` is read
/// when a piece is made and never again.
///
/// It is wired anyway because the alternative is worse in every
/// direction: renaming client-side would mean deleting the piece and
/// re-uploading its photographs, which the app cannot do — it holds
/// urls, not files — and would mint a new piece id, breaking the
/// `own_pieces` and `painting_session` references that point at the
/// old one.
///
/// Until the backend ships it, the save shows the server's own
/// message. Nothing else has to change when it does.
class PieceRenameSheet extends StatefulWidget {
  const PieceRenameSheet({
    required this.piece,
    required this.taken,
    required this.onRename,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    super.key,
  });

  final BookingPiece piece;

  /// Every OTHER name on this booking, already lower-cased and
  /// trimmed.
  final Set<String> taken;

  /// Answers null when the server took it, or the reason it did not.
  final Future<String?> Function(String label) onRename;

  final WorkshopFamily family;
  final String? wireColor;

  @override
  State<PieceRenameSheet> createState() => _PieceRenameSheetState();
}

class _PieceRenameSheetState extends State<PieceRenameSheet> {
  late final _controller = TextEditingController(
    text: (widget.piece.label ?? '').trim(),
  );
  late String _label = _controller.text;

  bool _sending = false;
  String? _serverError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// WHOSE NAME this is. On «صمم قطعتك» a label is a PERSON — the
  /// studio writes it on what that person made — and on the catalogue
  /// types it names the object they bought. «تعديل» alone said
  /// neither, and beside a camera and a bin it read as "edit the
  /// photographs".
  bool get _asksForPerson => widget.family == WorkshopFamily.makeYourPiece;

  String get _clean => _label.trim();

  bool get _duplicate => widget.taken.contains(_clean.toLowerCase());

  bool get _canSave =>
      _clean.isNotEmpty &&
      !_duplicate &&
      !_sending &&
      _clean != (widget.piece.label ?? '').trim();

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() {
      _sending = true;
      _serverError = null;
    });
    final error = await widget.onRename(_clean);
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    // THE SERVER'S OWN WORDS. Until the rename endpoint exists this is
    // where its absence shows — as whatever the backend answers, not
    // as a silent no-op.
    setState(() {
      _sending = false;
      _serverError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: widget.family,
      isDark: context.isDarkMode,
      wireColor: widget.wireColor,
    );

    return SheetShell(
      title: _asksForPerson
          ? BookingStrings.editPersonName
          : BookingStrings.editPieceName,
      heightFactor: null,
      maxHeightFactor: 0.6,
      footer: GlobalFilledButton(
        text: BookingStrings.save,
        enabled: _canSave,
        isLoading: _sending,
        style: terracottaCtaStyle(
          showArrow: false,
        ).copyWith(backgroundColor: fam.primary),
        onPressed: () => unawaited(_save()),
      ),
      children: [
        GlobalTextFormField(
          identifier: BookingStrings.pieceName,
          hint: _asksForPerson
              ? BookingStrings.personNameHint
              : BookingStrings.pieceLabelHint,
          controller: _controller,
          // 60 is the server's own ceiling on a label.
          behavior: const TextFieldBehavior(maxLength: 60),
          validation: TextFieldValidation(
            // THE COLLISION SHOWS AS IT IS TYPED. A name already taken
            // is a fact the moment it is written, and finding out on
            // the press means typing it twice.
            errorText: _duplicate
                ? BookingStrings.nameTakenFor(person: _asksForPerson)
                : _clean.isEmpty
                ? BookingStrings.pieceLabelRequired
                : null,
          ),
          callbacks: TextFieldCallbacks(
            onChanged: (value) => setState(() {
              _label = value;
              _serverError = null;
            }),
          ),
        ),
        if (_serverError case final message?) ...[
          SizedBox(height: spacing.sm),
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.statusColors.error,
            ),
          ),
        ],
        SizedBox(height: spacing.md),
      ],
    );
  }
}

/// Opens [PieceRenameSheet] over the booking.
Future<void> showPieceRenameSheet(
  BuildContext context, {
  required BookingPiece piece,
  required Set<String> taken,
  required Future<String?> Function(String label) onRename,
  WorkshopFamily family = WorkshopFamily.makeYourPiece,
  String? wireColor,
}) => showTerracottaSheet<void>(
  context,
  builder: (_) => PieceRenameSheet(
    piece: piece,
    taken: taken,
    onRename: onRename,
    family: family,
    wireColor: wireColor,
  ),
);
