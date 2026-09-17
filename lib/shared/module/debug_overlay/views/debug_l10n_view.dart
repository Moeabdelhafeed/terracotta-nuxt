import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/remote_translations.dart';
import '../../../../core/localization/tr.dart';
import '../../../../generated/l10n.dart';
import '../../drop_down/global_drop_down.dart';
import '../../text_field/text_field.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';
import '../widgets/debug_switch.dart';
import '../widgets/debug_text_field.dart';

/// Localization inspector. Loads every bundled ARB file (declared in
/// pubspec under `lib/l10n/`) and shows a per-locale key/value table —
/// keys grouped by the `strings/` namespace class that owns their
/// prefix (unclaimed prefixes land in UNCATEGORIZED, i.e. "not yet
/// namespaced"). Plus pseudo-loc toggle + missing-key ARB export.
class DebugL10nView extends StatefulWidget {
  const DebugL10nView({super.key});

  @override
  State<DebugL10nView> createState() => _DebugL10nViewState();
}

/// Key-prefix → owning namespace class in
/// `lib/core/localization/strings/`. Longest-prefix wins; keys matching
/// nothing are shown as UNCATEGORIZED so un-namespaced groups stay
/// visible (the point — they're future sub-group candidates).
const _kNamespaceGroups = <String, String>{
  'address_field_': 'AddressFieldStrings',
  'amount_field_': 'AmountFieldStrings',
  'animation_': 'AnimationStrings',
  'api_status_': 'ApiStatusStrings',
  'auth_': 'AuthStrings',
  'badge_': 'BadgeStrings',
  'bank_field_': 'BankFieldStrings',
  'button_': 'ButtonStrings',
  'card_field_': 'CardFieldStrings',
  'cart_': 'CartStrings',
  'change_password_': 'ChangePasswordStrings',
  'checkbox_': 'CheckboxStrings',
  'color_field_': 'ColorFieldStrings',
  'coming_soon_': 'ComingSoonStrings',
  'common_': 'CommonStrings',
  'connectivity_': 'ConnectivityStrings',
  'contact_form_': 'ContactFormStrings',
  'country_': 'CountryStrings',
  'crypto_field_': 'CryptoFieldStrings',
  'date_field_': 'DateFieldStrings',
  'date_range_': 'DateRangeStrings',
  'datetime_field_': 'DatetimeFieldStrings',
  'dialog_': 'DialogStrings',
  'drawer_': 'DrawerStrings',
  'drop_down_': 'DropDownStrings',
  'duration_field_': 'DurationFieldStrings',
  'error_': 'ErrorStrings',
  'faq_': 'FaqStrings',
  'feedback_': 'FeedbackStrings',
  'field_': 'FieldStrings',
  'gender_': 'GenderStrings',
  'ip_field_': 'IpFieldStrings',
  'legal_': 'LegalStrings',
  'list_': 'ListStrings',
  'location_field_': 'LocationFieldStrings',
  'login_field_': 'LoginFieldStrings',
  'maintenance_': 'MaintenanceStrings',
  'measurement_field_': 'MeasurementFieldStrings',
  'media_': 'MediaStrings',
  'national_id_': 'NationalIdStrings',
  'nav_': 'NavStrings',
  'notifications_': 'NotificationChannelStrings',
  'onboarding_': 'OnboardingStrings',
  'otp_field_': 'OtpFieldStrings',
  'otp_form_': 'OtpFormStrings',
  'pdf_': 'PdfStrings',
  'percent_field_': 'PercentFieldStrings',
  'phone_field_': 'PhoneFieldStrings',
  'plate_field_': 'PlateFieldStrings',
  'popup_': 'PopupStrings',
  'preferences_': 'PreferencesStrings',
  'promo_field_': 'PromoFieldStrings',
  'scanner_': 'ScannerStrings',
  'segmented_control_': 'SegmentedControlStrings',
  'social_button_': 'SocialButtonStrings',
  'stepper_': 'StepperStrings',
  'swift_field_': 'SwiftFieldStrings',
  'tags_field_': 'TagsFieldStrings',
  'text_': 'TextStrings',
  'text_field_': 'TextFieldStrings',
  'theme_mode_': 'ThemeModeStrings',
  'time_field_': 'TimeFieldStrings',
  'time_range_': 'TimeRangeStrings',
  'toggle_group_': 'ToggleGroupStrings',
  'update_': 'UpdateStrings',
  'url_field_': 'UrlFieldStrings',
  'validator_': 'ValidatorStrings',
  'vin_field_': 'VinFieldStrings',
  'wizard_': 'WizardStrings',
};

const _kUncategorized = 'Uncategorized';

String _groupOf(String key) {
  String? best;
  for (final prefix in _kNamespaceGroups.keys) {
    if (key.startsWith(prefix) &&
        (best == null || prefix.length > best.length)) {
      best = prefix;
    }
  }
  return best == null ? _kUncategorized : _kNamespaceGroups[best]!;
}

class _DebugL10nViewState extends State<DebugL10nView> {
  Map<String, Map<String, String>> _arbs = {};
  bool _loading = true;
  String _query = '';
  String? _selectedLocale;
  final Set<String> _collapsed = {};
  final _filterCtrl = TextEditingController();

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = <String, Map<String, String>>{};
    for (final locale in S.delegate.supportedLocales) {
      try {
        final raw = await rootBundle.loadString(
          'lib/l10n/intl_${locale.languageCode}.arb',
        );
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        result[locale.languageCode] = {
          for (final e in decoded.entries)
            if (!e.key.startsWith('@') && e.value is String)
              e.key: e.value as String,
        };
      } catch (_) {
        result[locale.languageCode] = {};
      }
    }
    if (!mounted) return;
    setState(() {
      _arbs = result;
      _selectedLocale ??= result.keys.firstOrNull;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DebugOverlayTheme.accent,
          ),
        ),
      );
    }

    final mq = Localizations.localeOf(context);
    final locales = _arbs.keys.toList();
    if (locales.isEmpty) {
      return Center(
        child: Text(
          'No bundled ARB files found in lib/l10n/.',
          style: DebugOverlayTheme.ui.copyWith(
            color: DebugOverlayTheme.textDim,
          ),
        ),
      );
    }
    final selected = _selectedLocale ?? locales.first;
    final selectedMap = _arbs[selected] ?? const {};
    final unionKeys = <String>{for (final m in _arbs.values) ...m.keys}.toList()
      ..sort();
    final missingKeys = unionKeys
        .where((k) => !selectedMap.containsKey(k))
        .toList(growable: false);

    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;
    final shownKeys = unionKeys
        .where((k) {
          if (!searching) return true;
          final v = selectedMap[k] ?? '';
          return k.toLowerCase().contains(q) || v.toLowerCase().contains(q);
        })
        .toList(growable: false);

    // Group in namespace order, UNCATEGORIZED last.
    final grouped = <String, List<String>>{};
    for (final k in shownKeys) {
      grouped.putIfAbsent(_groupOf(k), () => []).add(k);
    }
    final groupOrder = [
      ..._kNamespaceGroups.values.where(grouped.containsKey),
      if (grouped.containsKey(_kUncategorized)) _kUncategorized,
    ];

    return Column(
      children: [
        _Header(
          currentMQ: mq,
          locales: locales,
          selected: selected,
          onPick: (l) => setState(() => _selectedLocale = l),
        ),
        const _QaBand(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: DebugSearchField(
            controller: _filterCtrl,
            hintText: 'Filter keys / values',
            resultCount: searching ? shownKeys.length : null,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        if (missingKeys.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '${missingKeys.length} missing key${missingKeys.length == 1 ? '' : 's'} '
                'vs other locales',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF5350),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            itemCount: groupOrder.length,
            itemBuilder: (_, gi) {
              final group = groupOrder[gi];
              final keys = grouped[group]!;
              final isCollapsed = !searching && _collapsed.contains(group);
              return Padding(
                padding: EdgeInsets.only(top: gi == 0 ? 0 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GroupHeader(
                      label: group,
                      count: keys.length,
                      collapsed: isCollapsed,
                      collapsible: !searching,
                      uncategorized: group == _kUncategorized,
                      onTap: () => setState(() {
                        if (!_collapsed.remove(group)) _collapsed.add(group);
                      }),
                    ),
                    if (!isCollapsed)
                      for (final k in keys)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _KeyRow(
                            arbKey: k,
                            value: selectedMap[k],
                            localeCode: selected,
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.count,
    required this.collapsed,
    required this.collapsible,
    required this.uncategorized,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool collapsed;
  final bool collapsible;
  final bool uncategorized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = uncategorized
        ? const Color(0xFFFFA726)
        : DebugOverlayTheme.accent;
    return InkWell(
      onTap: collapsible ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: DebugOverlayTheme.ui.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: DebugOverlayTheme.textDim,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 10,
                color: DebugOverlayTheme.textDimmer,
              ),
            ),
            if (uncategorized) ...[
              const SizedBox(width: 6),
              Text(
                'no strings/ namespace yet',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 9.5,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
            const Spacer(),
            if (collapsible)
              AnimatedRotation(
                turns: collapsed ? -0.25 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.arbKey,
    required this.value,
    required this.localeCode,
  });

  final String arbKey;
  final String? value;
  final String localeCode;

  void _copy(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    GlobalToast.success('$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final missing = value == null;
    return InkWell(
      onTap: value == null ? null : () => _copy('Value', value!),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: DebugOverlayTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: missing
                ? const Color(0xFFEF5350).withValues(alpha: 0.5)
                : DebugOverlayTheme.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arbKey,
                    style: DebugOverlayTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? '<missing in $localeCode>',
                    style: DebugOverlayTheme.mono.copyWith(
                      fontSize: 11,
                      color: missing
                          ? const Color(0xFFEF5350)
                          : DebugOverlayTheme.textDim,
                    ),
                  ),
                ],
              ),
            ),
            _CopyKeyButton(onTap: () => _copy('Key', arbKey)),
          ],
        ),
      ),
    );
  }
}

/// Lean copy-icon button, sized to sit flush beside a two-line key row
/// without growing it — a Material `IconButton` ignores tight
/// `constraints` (its default min-tap-target machinery wins) and was
/// stretching the tile taller.
class _CopyKeyButton extends StatelessWidget {
  const _CopyKeyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copy key',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.copy_rounded,
              size: 13,
              color: DebugOverlayTheme.textDimmer,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.currentMQ,
    required this.locales,
    required this.selected,
    required this.onPick,
  });

  final Locale currentMQ;
  final List<String> locales;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
      decoration: const BoxDecoration(
        color: DebugOverlayTheme.surface,
        border: Border(bottom: BorderSide(color: DebugOverlayTheme.border)),
      ),
      child: Row(
        children: [
          Text(
            'app locale: ${currentMQ.toLanguageTag()}',
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 10.5,
              color: DebugOverlayTheme.textDim,
            ),
          ),
          const Spacer(),
          Text(
            'inspect',
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 10,
              color: DebugOverlayTheme.textDimmer,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 84,
            child: DebugConsoleTheme(
              fontSize: 11,
              child: GlobalDropdown<String>(
                items: [
                  for (final l in locales)
                    DropdownItem(value: l, label: l.toUpperCase()),
                ],
                selectedValue: selected,
                onChanged: (l) {
                  if (l != null) onPick(l);
                },
                behavior: const DropdownBehavior(denseTrigger: true),
                style: debugTextFieldStyle(
                  radius: 6,
                  fontSize: 11,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                dropdownStyle: DropdownStyle(
                  accentColor: DebugOverlayTheme.accent,
                  itemTextStyle: DebugOverlayTheme.mono.copyWith(
                    fontSize: 11,
                    color: DebugOverlayTheme.text,
                  ),
                ),
                sizing: const TextFieldSizing(height: 30),
                popupOptions: GlobalPopupOptions(
                  surfaceStyle: GlobalPopupSurfaceStyle(
                    color: DebugOverlayTheme.surfaceHigh,
                    borderColor: DebugOverlayTheme.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// QA band — pseudo-localization toggle + missing-keys-as-ARB copy.
class _QaBand extends StatelessWidget {
  const _QaBand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: DebugOverlayTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DebugOverlayTheme.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 14,
              color: DebugOverlayTheme.textDim,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pseudo-localization',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _CopyMissingButton(),
            const SizedBox(width: 4),
            ValueListenableBuilder<bool>(
              valueListenable: Tr.pseudoNotifier,
              builder: (_, on, _) => DebugSwitch(
                value: on,
                onChanged: (v) {
                  Tr.setPseudo(v);
                  // Strings resolve during build all over the tree —
                  // reassemble is the debug-only hammer that repaints
                  // every one of them (same path as hot reload).
                  // Deferred a frame: calling it synchronously inside
                  // this Switch's onChanged re-enters GestureBinding
                  // while it's still flushing the tap that triggered
                  // us, tripping the '!locked' assertion.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    WidgetsBinding.instance.reassembleApplication();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Copies every missing key discovered this session as a ready-to-paste
/// ARB fragment — the local sink for setups without a translations
/// backend.
class _CopyMissingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rt = getIt.isRegistered<RemoteTranslations>()
        ? getIt<RemoteTranslations>()
        : null;
    final count = rt?.missingCount ?? 0;
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 28),
        foregroundColor: count == 0
            ? DebugOverlayTheme.textDimmer
            : DebugOverlayTheme.accent,
      ),
      onPressed: count == 0 || rt == null
          ? null
          : () => Clipboard.setData(ClipboardData(text: rt.missingAsArbJson())),
      icon: const Icon(Icons.copy_rounded, size: 12),
      label: Text(
        'missing ($count)',
        style: DebugOverlayTheme.mono.copyWith(fontSize: 10.5),
      ),
    );
  }
}
