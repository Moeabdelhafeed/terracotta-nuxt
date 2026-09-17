import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// What a toggle group does when its buttons do not fit.
enum ToggleGroupOverflow {
  /// Keep the buttons that fit and move the rest behind a "+N" button
  /// that opens them stacked vertically.
  collapse,

  /// Let it overflow, which is what it did before this existed — a
  /// striped `RenderFlex overflowed by 22 pixels` bar and buttons the
  /// reader cannot reach.
  none,
}

/// Coordinates collapsing across every toggle group under it.
///
/// Two groups on one card that collapse at different moments look
/// broken rather than responsive: one of them is showing four buttons
/// while its neighbour shows two, and nothing on screen explains why.
/// The scope takes the SMALLEST number any of its groups can fit and
/// gives it to all of them, so they narrow together.
///
/// A group opts out with `coordinateOverflow: false` — a set of two
/// arrows has no business shrinking because a set of seven weekdays
/// next to it ran out of room.
class ToggleGroupOverflowScope extends StatefulWidget {
  const ToggleGroupOverflowScope({super.key, required this.child});

  final Widget child;

  static _ToggleGroupOverflowScopeState? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_OverflowScopeMarker>()?.state;

  @override
  State<ToggleGroupOverflowScope> createState() =>
      _ToggleGroupOverflowScopeState();
}

class _ToggleGroupOverflowScopeState extends State<ToggleGroupOverflowScope> {
  /// How many buttons each member can fit, by member.
  final _fits = <Object, int>{};

  /// The smallest of them, or null while nobody has reported.
  int? _cap;

  /// What every member may show.
  int? get cap => _cap;

  void report(Object id, int fits) {
    if (_fits[id] == fits) return;
    _fits[id] = fits;
    _recompute();
  }

  void forget(Object id) {
    if (_fits.remove(id) == null) return;
    _recompute();
  }

  void _recompute() {
    final next = _fits.isEmpty
        ? null
        : _fits.values.reduce((a, b) => a < b ? a : b);
    if (next == _cap) return;
    // Reports arrive from LAYOUT, so the rebuild has to wait for the
    // frame to finish — marking a widget dirty mid-layout throws.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _cap == next) return;
      setState(() => _cap = next);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _OverflowScopeMarker(state: this, cap: _cap, child: widget.child);
}

class _OverflowScopeMarker extends InheritedWidget {
  const _OverflowScopeMarker({
    required this.state,
    required this.cap,
    required super.child,
  });

  final _ToggleGroupOverflowScopeState state;
  final int? cap;

  @override
  bool updateShouldNotify(_OverflowScopeMarker old) => old.cap != cap;
}

/// A member's handle on the scope above it, if there is one.
///
/// Resolved in `didChangeDependencies` and KEPT: a group has to
/// deregister on the way out, and an ancestor lookup from `dispose` is
/// unsafe — the element tree is already coming apart by then.
class ToggleGroupOverflowRegistration {
  ToggleGroupOverflowRegistration._(this._scope);

  /// A registration attached to nothing — what a group gets when no
  /// scope is above it.
  const ToggleGroupOverflowRegistration.none() : _scope = null;

  final _ToggleGroupOverflowScopeState? _scope;

  /// The number every member of the scope is held to.
  int? get cap => _scope?.cap;

  void report(Object id, int fits) => _scope?.report(id, fits);

  void forget(Object id) => _scope?.forget(id);
}

/// Finds the scope above [context], or a registration that does
/// nothing.
ToggleGroupOverflowRegistration toggleGroupOverflowRegistration(
  BuildContext context,
) => ToggleGroupOverflowRegistration._(
  ToggleGroupOverflowScope._maybeOf(context),
);

// ---------------------------------------------------------------------------
// The layout
// ---------------------------------------------------------------------------

/// Lays a row of slots out at their natural width, keeps the ones that
/// fit, and hands the rest to the LAST child — the overflow button.
///
/// A `Wrap` was the obvious alternative and is wrong here: a toggle
/// group is one bordered strip, and a second line of it is two strips
/// with one border drawn round both. A horizontal scroller is wrong
/// for a different reason — nothing on screen says there is more, and
/// a selected item scrolled out of view reads as unselected.
class ToggleOverflowRow extends MultiChildRenderObjectWidget {
  ToggleOverflowRow({
    super.key,
    required List<Widget> slots,
    required Widget overflow,
    required this.onFits,
    required this.textDirection,
    this.maxVisible,
  }) : super(children: [...slots, overflow]);

  /// Which way the buttons run.
  ///
  /// A custom `RenderBox` lays out from x = 0 whatever the locale, so
  /// an Arabic group came out in English order with the "+N" on the
  /// wrong end. A `Row` would have mirrored for free; this has to be
  /// told.
  final TextDirection textDirection;

  /// Called with how many slots FIT, after every layout.
  final void Function(int fits) onFits;

  /// A cap from the scope. The row shows the smaller of this and what
  /// it can fit.
  final int? maxVisible;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderToggleOverflowRow(
        onFits: onFits,
        maxVisible: maxVisible,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderToggleOverflowRow renderObject,
  ) {
    renderObject
      ..onFits = onFits
      ..maxVisible = maxVisible
      ..textDirection = textDirection;
  }
}

class ToggleOverflowParentData extends ContainerBoxParentData<RenderBox> {
  /// Painted and hit-tested only while this is true.
  bool visible = true;
}

class RenderToggleOverflowRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ToggleOverflowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ToggleOverflowParentData> {
  RenderToggleOverflowRow({
    required this.onFits,
    required TextDirection textDirection,
    int? maxVisible,
  }) : _maxVisible = maxVisible,
       _textDirection = textDirection;

  /// Called with how many slots FIT, whenever that number changes.
  void Function(int fits) onFits;

  int? _maxVisible;
  int? get maxVisible => _maxVisible;
  set maxVisible(int? value) {
    if (_maxVisible == value) return;
    _maxVisible = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// The last count reported, so the callback fires on CHANGE only.
  int? _reported;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToggleOverflowParentData) {
      child.parentData = ToggleOverflowParentData();
    }
  }

  List<RenderBox> get _children {
    final out = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      out.add(child);
      child = (child.parentData! as ToggleOverflowParentData).nextSibling;
    }
    return out;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    var height = 0.0;
    for (final child in _children) {
      height = math.max(height, child.getMaxIntrinsicHeight(double.infinity));
    }
    return height;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    // The narrowest it can be and still say something: one slot, plus
    // the overflow button.
    final kids = _children;
    if (kids.length < 2) return 0;
    return kids.first.getMaxIntrinsicWidth(height) +
        kids.last.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var width = 0.0;
    // Everything EXCEPT the overflow button: at its widest nothing is
    // hidden, so there is nothing for the button to hold.
    final kids = _children;
    for (var i = 0; i < kids.length - 1; i++) {
      width += kids[i].getMaxIntrinsicWidth(height);
    }
    return width;
  }

  @override
  void performLayout() {
    final kids = _children;
    if (kids.isEmpty) {
      size = constraints.smallest;
      return;
    }

    final slots = kids.sublist(0, kids.length - 1);
    final overflow = kids.last;
    final loose = BoxConstraints(maxHeight: constraints.maxHeight);

    // Natural widths first — nothing is decided until everything has
    // been measured.
    final widths = <double>[];
    for (final slot in slots) {
      slot.layout(loose, parentUsesSize: true);
      widths.add(slot.size.width);
    }
    overflow.layout(loose, parentUsesSize: true);

    final maxWidth = constraints.maxWidth;
    final total = widths.fold<double>(0, (a, b) => a + b);

    // How many fit. When EVERYTHING fits there is no button to make
    // room for, which is why this is not one loop.
    var fits = slots.length;
    if (total > maxWidth && maxWidth.isFinite) {
      final budget = maxWidth - overflow.size.width;
      var used = 0.0;
      fits = 0;
      for (final w in widths) {
        if (used + w > budget) break;
        used += w;
        fits++;
      }
    }

    // The scope may hold it below what it can fit, so the groups on a
    // card narrow together — but never by more than ONE button.
    //
    // Holding every group to the strict minimum threw away room that
    // was already there: a set of four beside a set of two collapsed
    // to two and left a whole button's worth of space empty. Within
    // one of each other they still read as a pair.
    var visible = fits;
    final cap = _maxVisible;
    if (cap != null && cap + 1 < visible) visible = cap + 1;
    final showOverflow = visible < slots.length;

    var used = 0.0;
    var height = 0.0;
    for (var i = 0; i < slots.length; i++) {
      final data = slots[i].parentData! as ToggleOverflowParentData;
      data.visible = i < visible;
      if (!data.visible) continue;
      used += widths[i];
      height = math.max(height, slots[i].size.height);
    }
    final overflowData = overflow.parentData! as ToggleOverflowParentData;
    overflowData.visible = showOverflow;
    if (showOverflow) {
      used += overflow.size.width;
      height = math.max(height, overflow.size.height);
    }

    size = constraints.constrain(Size(used, height));

    // Placed only once the total is known, because in Arabic the FIRST
    // button is the one against the right edge.
    final rtl = _textDirection == TextDirection.rtl;
    var x = rtl ? size.width : 0.0;
    for (var i = 0; i < slots.length; i++) {
      final data = slots[i].parentData! as ToggleOverflowParentData;
      if (!data.visible) continue;
      if (rtl) x -= widths[i];
      data.offset = Offset(x, 0);
      if (!rtl) x += widths[i];
    }
    if (showOverflow) {
      if (rtl) x -= overflow.size.width;
      overflowData.offset = Offset(x, 0);
    }

    if (_reported != fits) {
      _reported = fits;
      // Out of the layout phase: the scope rebuilds its dependants,
      // and marking anything dirty from inside layout throws.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (attached) onFits(fits);
      });
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _children) {
      final data = child.parentData! as ToggleOverflowParentData;
      if (!data.visible) continue;
      context.paintChild(child, data.offset + offset);
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    // A collapsed button is still in the tree — it has to be, or there
    // would be nothing to measure — but it is not on the screen. A
    // reader offered it here would be offered it AGAIN inside the
    // panel, and the one out here does not answer to a tap.
    for (final child in _children) {
      final data = child.parentData! as ToggleOverflowParentData;
      if (data.visible) visitor(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Backwards, so the topmost is asked first — and skipping the
    // hidden ones is what stops a collapsed button eating taps meant
    // for the one drawn over it.
    for (final child in _children.reversed) {
      final data = child.parentData! as ToggleOverflowParentData;
      if (!data.visible) continue;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
