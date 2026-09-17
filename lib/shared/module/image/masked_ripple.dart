import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// ---------------------------------------------------------------------------
// Alpha-Masked InkWell (transparency-aware ripple)
// ---------------------------------------------------------------------------

class AlphaMaskedInkWell extends StatelessWidget {
  const AlphaMaskedInkWell({
    super.key,
    required this.onTap,
    required this.borderRadius,
    required this.maskImage,
  });

  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget maskImage;

  @override
  Widget build(BuildContext context) {
    return _MaskedRippleCompositor(
      mask: IgnorePointer(child: maskImage),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compositor render object
// ---------------------------------------------------------------------------

class _MaskedRippleCompositor extends MultiChildRenderObjectWidget {
  _MaskedRippleCompositor({required Widget mask, required Widget child})
    : super(children: [mask, child]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMaskedRipple();
}

class _MaskedRippleParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderMaskedRipple extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MaskedRippleParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MaskedRippleParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MaskedRippleParentData) {
      child.parentData = _MaskedRippleParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    var child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints.tight(size));
      final childParentData = child.parentData as _MaskedRippleParentData;
      childParentData.offset = Offset.zero;
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final rippleChild = lastChild;
    if (rippleChild != null) {
      final childParentData = rippleChild.parentData as _MaskedRippleParentData;
      return result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) =>
            rippleChild.hitTest(result, position: transformed),
      );
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final maskChild = firstChild;
    final rippleChild = lastChild;
    if (maskChild == null || rippleChild == null) return;

    final rect = offset & size;
    context.canvas.saveLayer(rect, Paint());
    context.paintChild(rippleChild, offset);
    final maskPaint = Paint()..blendMode = BlendMode.dstIn;
    context.canvas.saveLayer(rect, maskPaint);
    context.paintChild(maskChild, offset);
    context.canvas.restore();
    context.canvas.restore();
  }
}
