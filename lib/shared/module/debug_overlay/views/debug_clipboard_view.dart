import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_text_field.dart';

/// System-clipboard inspector — read what's on it, edit and set, or
/// clear. Handy when testing paste flows and deep-link handoffs.
class DebugClipboardView extends StatefulWidget {
  const DebugClipboardView({super.key});

  @override
  State<DebugClipboardView> createState() => _DebugClipboardViewState();
}

class _DebugClipboardViewState extends State<DebugClipboardView> {
  final _ctrl = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    setState(() {
      _ctrl.text = data?.text ?? '';
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        Row(
          children: [
            const Icon(
              Icons.content_paste_rounded,
              size: 13,
              color: DebugOverlayTheme.textDim,
            ),
            const SizedBox(width: 6),
            Text(
              'CLIPBOARD CONTENTS',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: DebugOverlayTheme.textDim,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _ctrl,
              builder: (_, v, _) => Text(
                '${v.text.length} chars',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ),
            ),
            const Spacer(),
            GlobalIconButton(
              tooltip: 'Re-read clipboard',
              enforceMinTouchTarget: false,
              iconData: Icons.refresh_rounded,
              onPressed: _refresh,
              iconSize: 14,
              style: const ButtonStateStyle(
                width: 28,
                height: 28,
                foregroundColor: DebugOverlayTheme.textDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DebugTextField(
          controller: _ctrl,
          hint: _loaded ? '<empty>' : 'Reading…',
          minLines: 5,
          maxLines: 10,
          enabled: _loaded,
          showBorder: false,
          fontSize: 11.5,
          contentPadding: const EdgeInsets.all(10),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Button(
                icon: Icons.save_rounded,
                label: 'Set clipboard',
                filled: true,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _ctrl.text));
                  GlobalToast.info('Clipboard updated');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Button(
                icon: Icons.backspace_outlined,
                label: 'Clear',
                filled: false,
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: ''));
                  _ctrl.clear();
                  GlobalToast.info('Clipboard cleared');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Note: iOS 14+ shows the system paste banner when the app '
          'reads the clipboard.',
          style: DebugOverlayTheme.ui.copyWith(
            fontSize: 10,
            color: DebugOverlayTheme.textDimmer,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.black87 : DebugOverlayTheme.textDim;
    return Material(
      color: filled ? DebugOverlayTheme.accent : DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: filled ? null : Border.all(color: DebugOverlayTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
