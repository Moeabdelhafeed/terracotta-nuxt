import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/sort_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// One sort choice for [SortDropdownField] — value + localized label +
/// optional leading icon.
@immutable
class SortOption<T> {
  const SortOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// The sort presets every list screen reaches for. Pair with
/// [CommonSortDropdownField], or map onto your own query params.
enum CommonSort {
  newest,
  oldest,
  priceLowToHigh,
  priceHighToLow,
  nameAToZ,
  nameZToA,
  ratingHighToLow,
  relevance,
}

extension CommonSortLabel on CommonSort {
  String get label => switch (this) {
    CommonSort.newest => SortStrings.newest,
    CommonSort.oldest => SortStrings.oldest,
    CommonSort.priceLowToHigh => SortStrings.priceLowHigh,
    CommonSort.priceHighToLow => SortStrings.priceHighLow,
    CommonSort.nameAToZ => SortStrings.nameAz,
    CommonSort.nameZToA => SortStrings.nameZa,
    CommonSort.ratingHighToLow => SortStrings.rating,
    CommonSort.relevance => SortStrings.relevance,
  };

  IconData get icon => switch (this) {
    CommonSort.newest => Icons.schedule_rounded,
    CommonSort.oldest => Icons.history_rounded,
    CommonSort.priceLowToHigh => Icons.trending_up_rounded,
    CommonSort.priceHighToLow => Icons.trending_down_rounded,
    CommonSort.nameAToZ => Icons.sort_by_alpha_rounded,
    CommonSort.nameZToA => Icons.sort_by_alpha_rounded,
    CommonSort.ratingHighToLow => Icons.star_outline_rounded,
    CommonSort.relevance => Icons.auto_awesome_outlined,
  };
}

/// Generic sort-by picker over caller-supplied [SortOption]s — use when
/// the sort keys are your own enum/query strings. For the stock preset
/// set see [CommonSortDropdownField].
class SortDropdownField<T> extends StatelessWidget {
  const SortDropdownField({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final List<SortOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Canonical sort row.
  static DropdownItem<T> itemFor<T>(SortOption<T> o) => DropdownItem(
    value: o.value,
    label: o.label,
    leading: o.icon == null ? null : Icon(o.icon, size: 20),
  );

  @override
  Widget build(BuildContext context) {
    return SimpleDropdownField<T>(
      items: options.map(itemFor).toList(),
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.sortByLabel,
      hint: hint ?? DropDownStrings.sortByHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}

/// Sort-by picker over the [CommonSort] presets — localized labels +
/// icons baked in. [sorts] trims the set to what the screen actually
/// supports (a list without prices shouldn't offer price sorts).
class CommonSortDropdownField extends StatelessWidget {
  const CommonSortDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.sorts = CommonSort.values,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final CommonSort? value;
  final ValueChanged<CommonSort?>? onChanged;

  /// Presets offered (defaults to all eight). Shrinking this after a
  /// pick doesn't clear an already-seeded selection — the parent owns
  /// clearing its stored value.
  final List<CommonSort> sorts;

  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return SortDropdownField<CommonSort>(
      options: [
        for (final s in sorts)
          SortOption(value: s, label: s.label, icon: s.icon),
      ],
      value: value,
      onChanged: onChanged,
      label: label,
      hint: hint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
