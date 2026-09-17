import 'package:flutter/material.dart';

import '../../../../data/api/api_service.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../buttons/global_icon_button.dart';
import '../debug_overlay_models.dart';

/// Mock-mode switch + a live inventory of every registered mock so you
/// can see what's covered BEFORE flipping. Persisted across sessions;
/// the banner + home-strip badge remind the dev while it's on.
class DebugMockToggleView extends StatefulWidget {
  const DebugMockToggleView({super.key});

  @override
  State<DebugMockToggleView> createState() => _DebugMockToggleViewState();
}

class _DebugMockToggleViewState extends State<DebugMockToggleView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DebugOverlayPrefs.mockMode,
      builder: (_, on, _) {
        final inventory = ApiService.mockInventory;
        final keys = inventory.keys.toList()..sort();
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            if (on) const _ActiveBanner(),
            // Hero switch tile.
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: DebugOverlayTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: on
                      ? const Color(0xFFE57373).withValues(alpha: 0.5)
                      : DebugOverlayTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          (on
                                  ? const Color(0xFFE57373)
                                  : DebugOverlayTheme.textDimmer)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 16,
                      color: on
                          ? const Color(0xFFE57373)
                          : DebugOverlayTheme.textDim,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use mocks',
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ApiService.useMock — every request returns its '
                          'registered mock instead of hitting the network.',
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 10.5,
                            color: DebugOverlayTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: on,
                    onChanged: DebugOverlayPrefs.setMockMode,
                    activeThumbColor: DebugOverlayTheme.accent,
                    activeTrackColor: DebugOverlayTheme.accent.withValues(
                      alpha: 0.4,
                    ),
                    inactiveThumbColor: DebugOverlayTheme.textDim,
                    inactiveTrackColor: DebugOverlayTheme.surfaceHigh,
                    trackOutlineColor: const WidgetStatePropertyAll(
                      DebugOverlayTheme.border,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Coverage inventory.
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_rounded,
                  size: 13,
                  color: DebugOverlayTheme.textDim,
                ),
                const SizedBox(width: 6),
                Text(
                  'REGISTERED MOCKS',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DebugOverlayTheme.textDim,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${keys.length}',
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 10,
                    color: DebugOverlayTheme.textDimmer,
                  ),
                ),
                const Spacer(),
                GlobalIconButton(
                  tooltip: 'Refresh',
                  enforceMinTouchTarget: false,
                  iconData: Icons.refresh_rounded,
                  onPressed: () => setState(() {}),
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
            if (keys.isEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                decoration: BoxDecoration(
                  color: DebugOverlayTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DebugOverlayTheme.border),
                ),
                child: Text(
                  'No mocks registered. Each *Apis class installs its own '
                  'via installMocks() → ApiService.registerMock(...). '
                  'Unmocked endpoints return an empty success response '
                  'while mock mode is on.',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 11,
                    color: DebugOverlayTheme.textDim,
                    height: 1.4,
                  ),
                ),
              )
            else ...[
              Container(
                decoration: BoxDecoration(
                  color: DebugOverlayTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DebugOverlayTheme.border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < keys.length; i++) ...[
                      if (i > 0)
                        Container(
                          height: 1,
                          color: DebugOverlayTheme.border.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      _MockRow(mockKey: keys[i], info: inventory[keys[i]]!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Endpoints without a registered mock return an empty '
                'SUCCESS response while mock mode is on — silent gaps, '
                'not errors.',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MockRow extends StatelessWidget {
  const _MockRow({required this.mockKey, required this.info});

  final String mockKey;
  final ({int statusCode, bool success}) info;

  static Color _methodColor(String method) => switch (method) {
    'GET' => const Color(0xFF66BB6A),
    'POST' => const Color(0xFF64B5F6),
    'PUT' || 'PATCH' => const Color(0xFFFFA726),
    'DELETE' => const Color(0xFFEF5350),
    _ => DebugOverlayTheme.textDim, // '*' any-method
  };

  @override
  Widget build(BuildContext context) {
    final sep = mockKey.indexOf(':');
    final method = sep < 0 ? '*' : mockKey.substring(0, sep);
    final endpoint = sep < 0 ? mockKey : mockKey.substring(sep + 1);
    final mColor = _methodColor(method);
    final failure = !info.success;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method == '*' ? 'ANY' : method,
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: mColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              endpoint,
              overflow: TextOverflow.ellipsis,
              style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${info.statusCode}${failure ? ' · FAIL' : ''}',
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: failure
                  ? const Color(0xFFEF5350)
                  : DebugOverlayTheme.textDimmer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE57373);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mock mode active — network is bypassed',
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
