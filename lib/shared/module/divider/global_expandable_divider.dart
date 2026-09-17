import 'package:flutter/material.dart';

import 'global_divider.dart';

/// Marks the disclosure arrow. `RotationTransition` is not a usable
/// finder — the page around it mounts others.
const kDividerExpandArrowKey = ValueKey<String>('divider-expand-arrow');

/// A divider that can be tapped to expand/collapse content below it.
class GlobalExpandableDivider extends StatefulWidget {
  const GlobalExpandableDivider({
    super.key,
    required this.child,
    this.text,
    this.icon,
    this.style = const DividerStyle(),
    this.lineStyle = DividerLineStyle.solid,
    this.initiallyExpanded = false,
    this.animationDuration = DividerDefaults.expandAnimDuration,
    this.semanticLabel,
  });

  /// Content revealed when expanded.
  final Widget child;

  /// Label on the divider line.
  final String? text;

  /// Icon on the divider line (when no text).
  final IconData? icon;

  /// Themeable style bag, shared with [GlobalDivider].
  final DividerStyle style;

  /// How the two rules either side of the label are drawn.
  final DividerLineStyle lineStyle;

  final bool initiallyExpanded;
  final Duration animationDuration;

  /// Spoken instead of [text].
  final String? semanticLabel;

  @override
  State<GlobalExpandableDivider> createState() =>
      _GlobalExpandableDividerState();
}

class _GlobalExpandableDividerState extends State<GlobalExpandableDivider>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: DividerDefaults.expandableArrowRotation,
    ).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The same bag the rules either side of the label resolve, so the
    // label and the line cannot drift apart.
    final rs = widget.style.resolve(
      context,
      disableAnimations: MediaQuery.disableAnimationsOf(context),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _isExpanded,
          label: widget.semanticLabel ?? widget.text,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DividerDefaults.expandablePadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GlobalDivider(
                      style: widget.style,
                      lineStyle: widget.lineStyle,
                    ),
                  ),
                  Padding(
                    padding: rs.textPadding,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.text != null)
                          Text(widget.text!, style: rs.textStyle),
                        if (widget.icon != null && widget.text == null)
                          Icon(
                            widget.icon,
                            size: DividerDefaults.expandableIconSize,
                            color: rs.iconColor,
                          ),
                        const SizedBox(width: 4),
                        RotationTransition(
                          key: kDividerExpandArrowKey,
                          turns: _rotationAnimation,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: DividerDefaults.expandableArrowSize,
                            color: rs.iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GlobalDivider(
                      style: widget.style,
                      lineStyle: widget.lineStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          alignment: Alignment.topCenter,
          child: widget.child,
        ),
      ],
    );
  }
}
