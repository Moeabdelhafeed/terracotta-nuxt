import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../../shared/module/chip/global_chip.dart';
import '../../../shared/module/sheet/global_sheet.dart';
import '../../../shared/module/switch/global_switch.dart';
import '../../../shared/module/text_field/global_text_field.dart';
import '../../_shared/terracotta_cta_style.dart';

/// What the reader chose in the filter sheet.
@immutable
class ProductFilters {
  const ProductFilters({
    this.featuredOnly = false,
    this.onSaleOnly = false,
    this.sort,
    this.minPrice,
    this.maxPrice,
  });

  final bool featuredOnly;
  final bool onSaleOnly;

  /// The range, or null for unbounded on that end. Whole numbers: the
  /// catalogue is priced in whole riyals and a decimal box invites a
  /// precision the shelf does not have.
  final int? minPrice;
  final int? maxPrice;

  /// Null is the studio's own catalogue order — a deliberate
  /// arrangement, and the right default.
  final ProductSort? sort;

  /// Whether anything is narrowing or reordering the list.
  bool get isActive =>
      featuredOnly ||
      onSaleOnly ||
      sort != null ||
      minPrice != null ||
      maxPrice != null;
}

/// «عوامل التصفية» — every filter the API actually honours.
///
/// `GET /api/shop/products` narrows on `featured` and `on_sale`, and
/// since 2026-09-13 it also ORDERS on `sort` — probed live on
/// 2026-09-14: `price_asc` and `price_desc` really order now, and an
/// unknown value is a 422. Before that it accepted `sort` and ignored
/// it, answering the whole catalogue either way, which is why this
/// sheet used to offer two switches and nothing else.
///
/// `min_price` / `max_price` are offered as two number boxes. Both
/// compare on what the customer PAYS — the sale price on a piece that
/// is on offer, not the struck-through one — and the server answers
/// 422 on a max below the min, so the sheet refuses that first.
///
/// Category and sub-category are filters too, but they are the rails on
/// the screen behind this — putting them here as well would be two
/// places to change one thing.
class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({required this.initial, super.key});

  final ProductFilters initial;

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late bool _featured = widget.initial.featuredOnly;
  late bool _onSale = widget.initial.onSaleOnly;
  late ProductSort? _sort = widget.initial.sort;
  late final _min = TextEditingController(
    text: widget.initial.minPrice?.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: widget.initial.maxPrice?.toString() ?? '',
  );

  /// Set when «إلى» is below «من». The server answers 422 on that, so
  /// the sheet says it before the round trip.
  String? _rangeError;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  int? _read(TextEditingController c) {
    final text = c.text.trim();
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    return value == null || value < 0 ? null : value;
  }

  /// The orders offered, the studio's own first. Null IS an option
  /// here rather than the absence of one.
  static const _sorts = <(ProductSort?, String Function())>[
    (null, _defaultLabel),
    (ProductSort.newest, _newestLabel),
    (ProductSort.priceAsc, _priceAscLabel),
    (ProductSort.priceDesc, _priceDescLabel),
  ];

  static String _defaultLabel() => ShopStrings.sortDefault;
  static String _newestLabel() => ShopStrings.sortNewest;
  static String _priceAscLabel() => ShopStrings.sortPriceAsc;
  static String _priceDescLabel() => ShopStrings.sortPriceDesc;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toggle(
          label: ShopStrings.filterFeatured,
          value: _featured,
          onChanged: (v) => setState(() => _featured = v),
        ),
        _Toggle(
          label: ShopStrings.filterOnSale,
          value: _onSale,
          onChanged: (v) => setState(() => _onSale = v),
        ),
        SizedBox(height: spacing.md),
        Text(
          ShopStrings.priceRange,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Expanded(
              child: _PriceBox(
                controller: _min,
                hint: ShopStrings.priceMin,
                onChanged: (_) => setState(() => _rangeError = null),
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: _PriceBox(
                controller: _max,
                hint: ShopStrings.priceMax,
                onChanged: (_) => setState(() => _rangeError = null),
              ),
            ),
          ],
        ),
        if (_rangeError case final message?) ...[
          SizedBox(height: spacing.xs),
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.statusColors.error,
            ),
          ),
        ],
        SizedBox(height: spacing.md),
        Text(
          ShopStrings.sortLabel,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            // `GlobalChip`, not Material's `ChoiceChip` — the app has
            // one chip and a guard that says so.
            for (final (value, label) in _sorts)
              GlobalChip(
                label: label(),
                selected: _sort == value,
                onSelected: (_) => setState(() => _sort = value),
              ),
          ],
        ),
        SizedBox(height: spacing.lg),
        GlobalFilledButton(
          text: ShopStrings.filterApply,
          onPressed: () {
            final min = _read(_min);
            final max = _read(_max);
            // BACKWARDS IS A 422. Caught here so the reader fixes it
            // with the boxes in front of them rather than after a
            // round trip.
            if (min != null && max != null && max < min) {
              setState(() => _rangeError = ShopStrings.priceRangeInvalid);
              return;
            }
            Navigator.of(context).pop(
              ProductFilters(
                featuredOnly: _featured,
                onSaleOnly: _onSale,
                sort: _sort,
                minPrice: min,
                maxPrice: max,
              ),
            );
          },
          style: terracottaCtaStyle(showArrow: false),
        ),
        SizedBox(height: spacing.sm),
        GlobalOutlinedButton(
          text: ShopStrings.filterClear,
          // Clears and closes in one, rather than making the reader
          // untick two things and then confirm.
          onPressed: () => Navigator.of(context).pop(const ProductFilters()),
        ),
      ],
    );
  }
}

/// One filter, as a labelled switch.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodyLarge,
          ),
        ),
        GlobalSwitch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

/// Opens the filter sheet. Answers null when dismissed without a
/// choice, so the caller leaves the filters as they were.
Future<ProductFilters?> showProductFilterSheet(
  BuildContext context, {
  required ProductFilters initial,
}) => GlobalBottomSheet.show<ProductFilters>(
  context: context,
  title: ShopStrings.filters,
  content: ProductFilterSheet(initial: initial),
);

/// One end of the price range. Digits only — the catalogue is priced
/// in whole riyals.
class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => GlobalTextFormField(
    controller: controller,
    hint: hint,
    behavior: TextFieldBehavior(
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      maxLength: 6,
    ),
    callbacks: TextFieldCallbacks(onChanged: onChanged),
  );
}
