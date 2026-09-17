import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/url_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/loggers/logger.dart';
import '../../../../core/utils/url_security.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../core/utils/web_link.dart';
import '../../../../data/services/url_host_verifier.dart';
import '../../../module/buttons/global_icon_button.dart';
import '../../../module/chip/global_chip.dart';
import '../../../module/text_field/global_text_field.dart';

export '../../../../core/utils/url_security.dart' show HostRisk, UrlSecurity;
export '../../../../core/utils/web_link.dart' show WebLink, UrlNormalizer;

/// Well-known sites for the [UrlField.suggestDomains] ghost completion.
const kCommonWebDomains = [
  'github.com',
  'google.com',
  'youtube.com',
  'facebook.com',
  'instagram.com',
  'x.com',
  'twitter.com',
  'linkedin.com',
  'wikipedia.org',
  'tiktok.com',
];

/// URL input — link-icon prefix, URL keyboard, and:
///
/// * **Normalization** — scheme-less input auto-gains `https://` on focus
///   loss ([autoScheme]); [stripTracking] drops `utm_*` / `fbclid`-style
///   params. Validation always runs on the NORMALIZED text, so
///   `example.com` passes even before the rewrite lands.
/// * **[WebLink] value object** via [onLinkChanged] (raw / normalized / uri
///   parts / isSecure / isValid).
/// * **Domain ghost** ([suggestDomains]) — inline completion for
///   [suggestedDomains] (Tab / → accepts), the EmailField treatment.
/// * **Host verification** ([verifyHost]) — async DNS check via
///   [UrlHostVerifier] (suffix spinner, fail-open offline), gated behind the
///   sync validator; chains into a caller [asyncValidator].
/// * **Open action** ([showOpenButton]) — suffix ↗ launches the link
///   externally once valid.
/// * **Policy** — [requireHttps], [allowedSchemes], [allowedDomains] /
///   [blockedDomains] (subdomains count) with localized errors.
class UrlField extends StatefulWidget {
  const UrlField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onLinkChanged,
    this.label,
    this.identifier,
    this.hint = 'https://example.com',
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.asyncValidator,
    this.asyncDebounce,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onFocusLoss,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showPrefixIcon = true,
    this.autoScheme = true,
    this.stripTracking = false,
    this.suggestDomains = false,
    this.suggestedDomains = kCommonWebDomains,
    this.verifyHost = false,
    this.showOpenButton = false,
    this.showFavicon = false,
    this.warnOnLookalikeHost = true,
    this.suggestFromClipboard = false,
    this.requireHttps = false,
    this.allowedSchemes = const {'http', 'https'},
    this.allowedDomains,
    this.blockedDomains,
  });

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  /// Parsed link on every change — see [WebLink].
  final ValueChanged<WebLink>? onLinkChanged;

  final String? label;
  final String? identifier;
  final String hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → normalization + scheme/host + policy checks.
  final String? Function(String?)? validator;

  /// Extra async check, run AFTER [verifyHost] (when both are on).
  final Future<String?> Function(String value)? asyncValidator;

  /// Defaults to [TextFieldDefaults.asyncValidatorDebounce].
  final Duration? asyncDebounce;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  final bool showPrefixIcon;

  /// Rewrite scheme-less hosts to `https://…` on focus loss. The validator
  /// normalizes internally either way — this only fixes the visible text.
  final bool autoScheme;

  /// Also drop tracking params (`utm_*`, `fbclid`…) when normalizing.
  final bool stripTracking;

  /// Ghost-complete [suggestedDomains] while the host is being typed.
  final bool suggestDomains;

  /// Domains offered by the ghost. Defaults to [kCommonWebDomains].
  final List<String> suggestedDomains;

  /// DNS-verify the host resolves ([UrlHostVerifier] — async row below the
  /// field, fail-open offline).
  final bool verifyHost;

  /// Suffix ↗ button that opens the link externally once it's valid.
  final bool showOpenButton;

  /// Swap the generic link icon for the site's real favicon once the host is
  /// valid (Google s2 favicon endpoint — note this sends typed hosts to
  /// Google, hence opt-in). Falls back to the link icon on any error.
  final bool showFavicon;

  /// Warning row when the host looks like a phishing lookalike — mixed
  /// Latin+Cyrillic/Greek labels (`аpple.com`) or punycode (`xn--…`). Warns,
  /// never blocks.
  final bool warnOnLookalikeHost;

  /// When focused + empty and the clipboard holds a URL, offer a one-tap
  /// "paste link" chip below the field. Opt-in — reading the clipboard shows
  /// the iOS paste banner.
  final bool suggestFromClipboard;

  /// Reject plain `http://` links.
  final bool requireHttps;

  /// Accepted URI schemes (lowercase). Extend for deep links
  /// (`{'https', 'myapp'}`).
  final Set<String> allowedSchemes;

  /// When set, the host must be one of these domains (or a subdomain).
  final List<String>? allowedDomains;

  /// Hosts (or their subdomains) that are rejected.
  final List<String>? blockedDomains;

  @override
  State<UrlField> createState() => _UrlFieldState();
}

class _UrlFieldState extends State<UrlField> {
  FocusNode? _internalNode;

  /// Clipboard URL offered by the paste chip (null = none / dismissed).
  String? _clipboardCandidate;
  bool _clipboardDismissed = false;

  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _listensToText =>
      widget.showOpenButton ||
      widget.showFavicon ||
      widget.warnOnLookalikeHost ||
      widget.suggestFromClipboard;

  @override
  void initState() {
    super.initState();
    // Ours attaches before the field's internal listener, so the rewrite
    // lands before its focus-loss validation reads the text.
    _node.addListener(_onFocus);
    if (_listensToText) widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    widget.controller.removeListener(_onText);
    _internalNode?.dispose();
    super.dispose();
  }

  void _onText() {
    // Open button / favicon / warning row / chip track the live text.
    if (mounted) setState(() {});
  }

  // ── Clipboard smart-fill ──────────────────────────────────────────
  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted || text.isEmpty) return;
    final normalized = UrlNormalizer.normalize(text);
    if (Validators.isValidUrl(normalized) &&
        widget.controller.text.trim().isEmpty) {
      setState(() => _clipboardCandidate = normalized);
    }
  }

  void _acceptClipboard() {
    final url = _clipboardCandidate;
    if (url == null) return;
    widget.controller.value = TextEditingValue(
      text: url,
      selection: TextSelection.collapsed(offset: url.length),
    );
    setState(() => _clipboardCandidate = null);
    _emit();
  }

  String _normalize(String text) => UrlNormalizer.normalize(
    text,
    autoScheme: widget.autoScheme,
    stripTracking: widget.stripTracking,
  );

  /// Focus gain → offer the clipboard URL; focus loss → materialize the
  /// normalization into the visible text.
  void _onFocus() {
    if (_node.hasFocus) {
      if (widget.suggestFromClipboard && !_clipboardDismissed) {
        _checkClipboard();
      }
      return;
    }
    if (_clipboardCandidate != null) {
      setState(() => _clipboardCandidate = null);
    }
    final raw = widget.controller.text;
    final normalized = _normalize(raw);
    if (normalized != raw && Validators.isValidUrl(normalized)) {
      widget.controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
      _emit();
    }
  }

  // ── Validation (always on the normalized text) ────────────────────
  String? _defaultValidator(String? value) {
    final normalized = _normalize(value ?? '');
    if (normalized.isEmpty) return Validators.validateUrl(normalized);
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) {
      return Validators.validateUrl(normalized);
    }
    final scheme = uri.scheme.toLowerCase();
    if (widget.requireHttps && scheme != 'https') {
      return UrlFieldStrings.httpsRequired;
    }
    if (!widget.allowedSchemes.contains(scheme)) {
      return Validators.validateUrl(normalized) ??
          UrlFieldStrings.schemeNotAllowed(scheme);
    }
    final host = uri.host.toLowerCase();
    bool matches(String domain) {
      final d = domain.toLowerCase();
      return host == d || host.endsWith('.$d');
    }

    final allowed = widget.allowedDomains;
    if (allowed != null && allowed.isNotEmpty && !allowed.any(matches)) {
      return UrlFieldStrings.domainNotAllowed(allowed.join(', '));
    }
    if (widget.blockedDomains?.any(matches) ?? false) {
      return UrlFieldStrings.domainBlocked(host);
    }
    return null;
  }

  String? Function(String?) get _effectiveValidator =>
      widget.validator ?? _defaultValidator;

  /// [verifyHost] runs first; only when the host resolves does the caller's
  /// [UrlField.asyncValidator] get a say.
  Future<String?> _effectiveAsyncValidator(String value) async {
    if (widget.verifyHost) {
      final err = await UrlHostVerifier.instance.validateUrlHost(
        _normalize(value),
      );
      if (err != null) return err;
    }
    return widget.asyncValidator?.call(value);
  }

  // ── WebLink emit ──────────────────────────────────────────────────
  void _emit() {
    final cb = widget.onLinkChanged;
    if (cb == null) return;
    final raw = widget.controller.text;
    final normalized = _normalize(raw);
    cb(
      WebLink(
        raw: raw,
        normalized: normalized,
        uri: normalized.isEmpty ? null : Uri.tryParse(normalized),
        isValid: _effectiveValidator(raw) == null,
      ),
    );
  }

  // ── Ghost completion (EmailField treatment, host position) ────────
  String? _domainCompletion(String text) {
    var t = text.trim().toLowerCase();
    if (t.isEmpty) return null;
    // Skip past a typed scheme; ghost only while the HOST is being typed.
    final schemeEnd = t.indexOf('://');
    if (schemeEnd >= 0) t = t.substring(schemeEnd + 3);
    if (t.isEmpty || t.contains('/') || t.contains('?')) return null;
    for (final d in widget.suggestedDomains) {
      final dl = d.toLowerCase();
      if (dl == t) return null; // already complete
      if (dl.startsWith(t)) return d.substring(t.length);
    }
    return null;
  }

  // ── Open action ───────────────────────────────────────────────────
  bool get _openable =>
      widget.showOpenButton &&
      widget.controller.text.trim().isNotEmpty &&
      _effectiveValidator(widget.controller.text) == null;

  void _openLink() {
    final uri = Uri.tryParse(_normalize(widget.controller.text));
    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Favicon / warning / chip surfaces ─────────────────────────────
  String get _currentHost =>
      Uri.tryParse(_normalize(widget.controller.text))?.host ?? '';

  /// Host looks COMPLETE (ends in a ≥2-letter TLD) — mid-typing fragments
  /// (`google.`, `google.c`) must not hit the favicon endpoint: one 404 per
  /// keystroke.
  static final _completeHost = RegExp(r'^[a-z0-9][a-z0-9\-.]*\.[a-z]{2,}$');

  /// Real favicon once the host is complete; falls back to the link icon.
  /// Fetched by [_FaviconCache] (not `Image.network`) so a missing icon is a
  /// single quiet debug line, not a framework error report per keystroke.
  Widget _prefixIcon(BuildContext context) {
    final linkIcon = Icon(
      Icons.link_rounded,
      color: context.iconColors.primary,
    );
    final host = _currentHost;
    final child = (widget.showFavicon && _completeHost.hasMatch(host))
        ? _Favicon(host: host, fallback: linkIcon, size: context.iconSizes.md)
        : linkIcon;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      child: child,
    );
  }

  /// The host as TYPED — `Uri` percent-encodes Unicode hosts, which would
  /// hide the lookalike characters from [UrlSecurity]. Manual slice: drop the
  /// scheme, cut at the first `/ ? #`, drop a port.
  String get _rawTypedHost {
    var t = _normalize(widget.controller.text).toLowerCase();
    final schemeEnd = t.indexOf('://');
    if (schemeEnd >= 0) t = t.substring(schemeEnd + 3);
    final cut = t.indexOf(RegExp(r'[/?#]'));
    if (cut >= 0) t = t.substring(0, cut);
    final port = t.lastIndexOf(':');
    if (port >= 0) t = t.substring(0, port);
    return t;
  }

  /// Lookalike-host warning appended to the caller's messages.
  List<FieldMessage> get _messages {
    if (!widget.warnOnLookalikeHost) return widget.messages;
    final risk = UrlSecurity.riskOf(_rawTypedHost);
    if (risk == null) return widget.messages;
    final text = switch (risk) {
      HostRisk.mixedScript => UrlFieldStrings.lookalikeHost,
      HostRisk.punycode => UrlFieldStrings.punycodeHost,
    };
    return [...widget.messages, FieldMessage.warning(text)];
  }

  /// One-tap paste chip shown under the field while focused + empty.
  Widget _clipboardChip(BuildContext context) {
    final url = _clipboardCandidate!;
    final display = url.length > 40 ? '${url.substring(0, 40)}…' : url;
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: GlobalChip(
              label: display,
              avatar: const Icon(Icons.content_paste, size: 16),
              onSelected: (_) => _acceptClipboard(),
            ),
          ),
          GlobalIconButton(
            iconData: Icons.close,
            iconSize: 16,
            tooltip: UrlFieldStrings.dismissPaste,
            enforceMinTouchTarget: false,
            // Mirror the compact-density IconButton footprint it replaces.
            style: const ButtonStateStyle(width: 40, height: 40),
            onPressed: () => setState(() {
              _clipboardCandidate = null;
              _clipboardDismissed = true;
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      hint: widget.hint,
      focusNode: _node,
      messages: _messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.url,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: _effectiveValidator,
        asyncValidator: (widget.verifyHost || widget.asyncValidator != null)
            ? _effectiveAsyncValidator
            : null,
        asyncDebounce:
            widget.asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        revalidateKey: (
          widget.requireHttps,
          widget.allowedSchemes,
          widget.allowedDomains,
          widget.blockedDomains,
        ),
      ),
      features: widget.suggestDomains
          ? TextFieldFeatures(
              suggestions: SuggestionsConfig(
                showInlineCompletion: true,
                completion: _domainCompletion,
              ),
            )
          : const TextFieldFeatures(),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon ? _prefixIcon(context) : null,
        suffix: _openable
            ? TextFieldSuffix.icon(Icons.open_in_new, onTap: _openLink)
            : null,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _emit();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );

    if (_clipboardCandidate == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [field, _clipboardChip(context)],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Favicon — silent fetch + session cache
// ─────────────────────────────────────────────────────────────────────

/// Fetches favicons OURSELVES instead of `Image.network` so a host without
/// one fails silently (`Image.network` routes every 404 through the
/// framework's image-error reporting — a full boxed error per keystroke).
///
/// Sources, in order: Google s2 at 64px → s2 at 32px (s2 404s a size it
/// hasn't crawled) → DuckDuckGo's live-favicon proxy (fetches the site's real
/// `/favicon.ico`, so uncrawled subdomains still resolve). Results (including
/// misses) are cached per host for the session; a full miss logs ONE debug
/// line.
abstract final class _FaviconCache {
  static final Map<String, Uint8List?> _cache = {};
  static final http.Client _client = http.Client();

  static bool isCached(String host) => _cache.containsKey(host);

  static List<Uri> _sources(String host) => [
    Uri.https('www.google.com', '/s2/favicons', {'domain': host, 'sz': '64'}),
    Uri.https('www.google.com', '/s2/favicons', {'domain': host, 'sz': '32'}),
    Uri.https('icons.duckduckgo.com', '/ip3/$host.ico'),
  ];

  static Future<Uint8List?> get(String host) async {
    if (_cache.containsKey(host)) return _cache[host];
    var sawNetworkError = false;
    for (final uri in _sources(host)) {
      try {
        final res = await _client.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return _cache[host] = res.bodyBytes;
        }
      } catch (_) {
        sawNetworkError = true; // hiccup — try the next source
      }
    }
    if (sawNetworkError) return null; // offline? retry next time, no cache
    Logger.m.d('[UrlField] no favicon for $host');
    return _cache[host] = null; // genuine miss — ask once per session
  }
}

/// Debounced favicon: waits [_debounce] after the host last CHANGED before
/// fetching, so mid-typing hosts that merely look complete (`cms.vi` while
/// typing `cms.visitamman.jo`) never hit the network. Cached hosts render
/// instantly.
class _Favicon extends StatefulWidget {
  const _Favicon({
    required this.host,
    required this.fallback,
    required this.size,
  });

  final String host;
  final Widget fallback;
  final double size;

  @override
  State<_Favicon> createState() => _FaviconState();
}

class _FaviconState extends State<_Favicon> {
  static const _debounce = Duration(milliseconds: 600);
  Timer? _timer;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load(immediate: _FaviconCache.isCached(widget.host));
  }

  @override
  void didUpdateWidget(covariant _Favicon old) {
    super.didUpdateWidget(old);
    if (old.host != widget.host) {
      _bytes = null;
      _load(immediate: _FaviconCache.isCached(widget.host));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _load({required bool immediate}) {
    _timer?.cancel();
    if (immediate) {
      _fetch();
    } else {
      _timer = Timer(_debounce, _fetch);
    }
  }

  Future<void> _fetch() async {
    final host = widget.host;
    final bytes = await _FaviconCache.get(host);
    // Host may have changed while the fetch was in flight.
    if (mounted && widget.host == host && bytes != null) {
      setState(() => _bytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return widget.fallback;
    return Image.memory(bytes, width: widget.size, height: widget.size);
  }
}
