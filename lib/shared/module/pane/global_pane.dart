import 'package:flutter/material.dart';

import '../../../core/navigation/transitions/route_transition.dart';
import '../../../core/responsive/extensions.dart';
import '../../../core/responsive/window_size_class.dart';
import '../divider/global_divider.dart';

/// List + detail layout that flips between two modes based on the
/// active [WindowSizeClass]:
///
/// * **Compact** — only the list is visible. Tapping a list item pushes
///   a full-screen route showing the detail.
/// * **Split** (medium+) — list on the leading edge, detail on the
///   trailing edge, separated by a vertical divider.
///
/// Selection is parent-owned: pass [selected] in and react to
/// [onSelect] to update it.
class GlobalPane<T extends Object> extends StatelessWidget {
  const GlobalPane({
    super.key,
    required this.items,
    required this.listBuilder,
    required this.detailBuilder,
    this.selected,
    this.onSelect,
    this.emptyBuilder,
    this.compactRouteBuilder,
    this.minListWidth = 280,
    this.maxListWidth = 420,
    this.listFraction = 0.35,
    this.splitFromBucket = WindowSizeClass.medium,
    this.dividerColor,
  });

  final List<T> items;
  final T? selected;
  final ValueChanged<T>? onSelect;

  final Widget Function(
    BuildContext context,
    List<T> items,
    T? selected,
    ValueChanged<T> onTap,
  )
  listBuilder;

  final Widget Function(BuildContext context, T item) detailBuilder;

  final WidgetBuilder? emptyBuilder;

  final Route<dynamic> Function(BuildContext context, T item)?
  compactRouteBuilder;

  final double minListWidth;
  final double maxListWidth;
  final double listFraction;

  final WindowSizeClass splitFromBucket;

  final Color? dividerColor;

  bool _isSplit(BuildContext context) =>
      context.windowSize.isAtLeast(splitFromBucket);

  @override
  Widget build(BuildContext context) {
    if (!_isSplit(context)) {
      return listBuilder(context, items, null, (item) {
        onSelect?.call(item);
        Navigator.of(context).push(
          compactRouteBuilder?.call(context, item) ??
              // The APP's transition, not Material's — so the detail
              // page arrives the way every other page does, mirrors in
              // Arabic and obeys reduced motion.
              RouteTransition.route<void>(
                context: context,
                name: 'pane-detail',
                child: _CompactDetailScaffold(
                  child: detailBuilder(context, item),
                ),
              ),
        );
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final listWidth = (constraints.maxWidth * listFraction).clamp(
          minListWidth,
          maxListWidth,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: listWidth,
              child: listBuilder(context, items, selected, (item) {
                onSelect?.call(item);
              }),
            ),
            GlobalDivider.vertical(style: DividerStyle(color: dividerColor)),
            Expanded(
              child: selected != null
                  ? detailBuilder(context, selected as T)
                  : (emptyBuilder?.call(context) ?? const SizedBox.shrink()),
            ),
          ],
        );
      },
    );
  }
}

class _CompactDetailScaffold extends StatelessWidget {
  const _CompactDetailScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: child,
    );
  }
}

/// Optional [ChangeNotifier] for [GlobalPane] selection state — use
/// when several widgets need to read or mutate the selection.
class PaneController<T extends Object> extends ChangeNotifier {
  PaneController({T? initial}) : _selected = initial;

  T? _selected;

  T? get selected => _selected;

  void select(T? item) {
    if (identical(_selected, item) || _selected == item) return;
    _selected = item;
    notifyListeners();
  }

  void clear() => select(null);
}
