import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/scan_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/scan/scan_result.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/text_field/global_text_field.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../booking/widgets/sheet_shell.dart';

/// «كم شخصاً حضر؟» — the second half of a party's check-in.
///
/// The server answers `needs_count: true` having written NOTHING, so
/// this is not a confirmation of something already done: it is the
/// question, and the code goes again with the answer. A wrong number
/// is not correctable by scanning twice, which is why the server
/// refuses to guess and why every option is one tap.
Future<int?> showHeadcountSheet(
  BuildContext context, {
  required ScanResult result,
}) => showTerracottaSheet<int>(
  context,
  builder: (_) => _HeadcountSheet(result: result),
);

class _HeadcountSheet extends StatefulWidget {
  const _HeadcountSheet({required this.result});

  final ScanResult result;

  @override
  State<_HeadcountSheet> createState() => _HeadcountSheetState();
}

class _HeadcountSheetState extends State<_HeadcountSheet> {
  /// Defaults to the whole party — the common case is everyone
  /// turning up, and the desk should not have to say so.
  late int _count = widget.result.peopleCount;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final booked = widget.result.peopleCount;

    return SheetShell(
      title: ScanStrings.howManyTitle,
      heightFactor: null,
      maxHeightFactor: 0.7,
      footer: GlobalFilledButton(
        text: ScanStrings.confirmCount,
        onPressed: () => Navigator.of(context).pop(_count),
        style: terracottaCtaStyle(showArrow: false),
      ),
      children: [
        Text(
          ScanStrings.howManyBody(
            widget.result.userName ?? '',
            AppNumbers.localizeDigits('$booked'),
          ),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
        SizedBox(height: spacing.lg),
        // ONE TAP PER ANSWER. A party is small — a stepper would make
        // the desk press twice for the answer it wants most.
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (var n = 1; n <= booked; n++)
              _CountChip(
                value: n,
                selected: n == _count,
                onTap: () => setState(() => _count = n),
              ),
          ],
        ),
        SizedBox(height: spacing.md),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColors.primary;
    // The brand is LIFTED in dark, so a selected tile is a light
    // ground and white on it is 3.2:1. Measured instead — see
    // [WorkshopFamilyColors.onWireColor].
    final ink = WorkshopFamilyColors.onWireColor(accent);
    final radius = BorderRadius.circular(context.radii.md);

    return Material(
      color: selected ? accent : context.backgroundColors.container,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Text(
              AppNumbers.localizeDigits('$value'),
              style: context.textTheme.titleMedium?.copyWith(
                color: selected ? ink : context.textColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «أدخل الرمز» — the eight digits printed under every symbol.
///
/// The fallback the spec builds in: a camera that will not focus, a
/// phone screen too dim to read, a customer whose battery died. The
/// server takes the same value either way, so this and the camera go
/// through one call.
Future<String?> showCodeEntrySheet(BuildContext context) =>
    showTerracottaSheet<String>(
      context,
      builder: (_) => const _CodeEntrySheet(),
    );

class _CodeEntrySheet extends StatefulWidget {
  const _CodeEntrySheet();

  @override
  State<_CodeEntrySheet> createState() => _CodeEntrySheetState();
}

class _CodeEntrySheetState extends State<_CodeEntrySheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // The desk opened this to TYPE. Anything else asks for a second
    // tap to do what the first one meant.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) => SheetShell(
    title: ScanStrings.enterCode,
    heightFactor: null,
    maxHeightFactor: 0.7,
    footer: GlobalFilledButton(
      text: ScanStrings.confirmCount,
      onPressed: _submit,
      style: terracottaCtaStyle(showArrow: false),
    ),
    children: [
      GlobalTextFormField(
        controller: _controller,
        focusNode: _focus,
        hint: ScanStrings.codeHint,
        // DIGITS, and always left-to-right: the code is typed into a
        // till, not read as prose, and Arabic-Indic digits are not
        // what is printed on the customer's screen.
        behavior: TextFieldBehavior(
          keyboardType: TextInputType.number,
          maxLength: 8,
          textDirection: TextDirection.ltr,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        callbacks: TextFieldCallbacks(onSubmitted: (_) => _submit()),
      ),
      SizedBox(height: context.spacing.md),
    ],
  );
}
