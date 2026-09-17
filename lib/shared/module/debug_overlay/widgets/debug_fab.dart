import 'package:flutter/material.dart';

import '../debug_overlay_models.dart';

/// Floating bug button that snaps to the nearest vertical edge after drag.
class DebugFab extends StatefulWidget {
  const DebugFab({super.key, required this.onTap, this.badgeColor});

  final VoidCallback onTap;

  /// Optional dot on the FAB — used to hint at the latest log level
  /// (e.g. red when errors are present).
  final Color? badgeColor;

  @override
  State<DebugFab> createState() => _DebugFabState();
}

class _DebugFabState extends State<DebugFab> {
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    const edgeInset = 8.0;
    final topInset = MediaQuery.of(context).padding.top + 40;
    final bottomInset = MediaQuery.of(context).padding.bottom + 40;
    final pos =
        _position ??
        Offset(
          screen.width - kDebugFabSize - edgeInset,
          screen.height * 0.4,
        );

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanUpdate: (d) {
          setState(() {
            _position = Offset(
              (pos.dx + d.delta.dx).clamp(
                edgeInset,
                screen.width - kDebugFabSize - edgeInset,
              ),
              (pos.dy + d.delta.dy).clamp(
                topInset,
                screen.height - kDebugFabSize - bottomInset,
              ),
            );
          });
        },
        onPanEnd: (_) {
          final snapRight = pos.dx + kDebugFabSize / 2 > screen.width / 2;
          setState(() {
            _position = Offset(
              snapRight ? screen.width - kDebugFabSize - edgeInset : edgeInset,
              pos.dy,
            );
          });
        },
        child: _buildFab(),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      width: kDebugFabSize,
      height: kDebugFabSize,
      decoration: BoxDecoration(
        color: DebugOverlayTheme.bg,
        shape: BoxShape.circle,
        border: Border.all(color: DebugOverlayTheme.accent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.bug_report_rounded,
              color: DebugOverlayTheme.accent,
              size: 22,
            ),
          ),
          if (widget.badgeColor != null)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: DebugOverlayTheme.bg, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
