import 'package:flutter/material.dart';

/// One field in a [ResponsiveFieldRow] — its widget plus the layout
/// intent that decides how it packs.
@immutable
class ResponsiveField {
  const ResponsiveField({
    required this.child,
    this.minWidth = 200,
    this.flex,
    this.keepWithNext = false,
  });

  final Widget child;

  /// Comfortable minimum width. Rows pack consecutive fields while their
  /// `minWidth`s (plus spacing) fit the available width; a field that
  /// won't fit drops to the next row. This is the tuning knob — a wide
  /// field naturally lands on its own line as the viewport narrows.
  final double minWidth;

  /// Share of the row's width (relative to siblings). Null → proportional
  /// to [minWidth], so a 300-wide field takes more than a 140-wide one.
  final int? flex;

  /// Bind this field to the NEXT one so they never split across rows —
  /// they pack (and wrap) as a single unit. Chain it to bind three+.
  final bool keepWithNext;
}

/// Width-aware field layout: packs [ResponsiveField]s into rows greedily
/// by their [ResponsiveField.minWidth], wrapping to a new row when the
/// next field won't fit, and collapsing to one-per-row when narrow.
///
/// Declarative grouping without breakpoint math: give each field the
/// width it needs and, where two must stay side by side, mark the first
/// [ResponsiveField.keepWithNext]. The classic case —
///
/// ```dart
/// ResponsiveFieldRow(children: [
///   ResponsiveField(minWidth: 300, child: street),
///   ResponsiveField(minWidth: 140, keepWithNext: true, child: city),
///   ResponsiveField(minWidth: 140, child: postal),
/// ])
/// ```
///
/// — is all three in a row when wide, and `street` alone above
/// `city | postal` when the street's 300 no longer leaves room.
class ResponsiveFieldRow extends StatelessWidget {
  const ResponsiveFieldRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<ResponsiveField> children;

  /// Horizontal gap between fields sharing a row.
  final double spacing;

  /// Vertical gap between wrapped rows.
  final double runSpacing;

  /// Merge `keepWithNext` runs into indivisible units.
  List<List<ResponsiveField>> _units() {
    final units = <List<ResponsiveField>>[];
    var i = 0;
    while (i < children.length) {
      final unit = <ResponsiveField>[children[i]];
      while (children[i].keepWithNext && i + 1 < children.length) {
        i++;
        unit.add(children[i]);
      }
      units.add(unit);
      i++;
    }
    return units;
  }

  double _unitMin(List<ResponsiveField> u) =>
      u.fold(0.0, (a, f) => a + f.minWidth) + spacing * (u.length - 1);

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final units = _units();

        // Unbounded width (rare — horizontal scroll): everything one row.
        final rows = <List<List<ResponsiveField>>>[];
        if (!maxWidth.isFinite) {
          rows.add(units);
        } else {
          var current = <List<ResponsiveField>>[];
          var currentWidth = 0.0;
          for (final u in units) {
            final add = _unitMin(u);
            final projected = current.isEmpty
                ? add
                : currentWidth + spacing + add;
            if (current.isNotEmpty && projected > maxWidth) {
              rows.add(current);
              current = [u];
              currentWidth = add;
            } else {
              current.add(u);
              currentWidth = projected;
            }
          }
          if (current.isNotEmpty) rows.add(current);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: runSpacing),
              _buildRow(rows[r]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRow(List<List<ResponsiveField>> rowUnits) {
    // Flatten the row's units back to individual fields for layout; the
    // units only governed WRAPPING, not the in-row arrangement.
    final fields = [for (final u in rowUnits) ...u];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var j = 0; j < fields.length; j++) ...[
          if (j > 0) SizedBox(width: spacing),
          Expanded(
            flex:
                fields[j].flex ??
                (fields[j].minWidth.round().clamp(1, 1 << 20)),
            child: fields[j].child,
          ),
        ],
      ],
    );
  }
}
