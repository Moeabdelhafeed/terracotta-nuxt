import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/location_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/device/hardware/location_utils.dart';
import '../../../module/buttons/global_icon_button.dart';
import '../../../module/text_field/global_text_field.dart';
import '../generic/simple_text_field.dart';
import 'joined_pair_radii.dart';
import 'location_picker_sheet.dart';

/// A geographic point the [LocationField] emits — decimal degrees plus a
/// range-validity snapshot.
@immutable
class LocationValue {
  const LocationValue({
    required this.latitude,
    required this.longitude,
    required this.isValid,
  });

  final double latitude;
  final double longitude;
  final bool isValid;

  /// google_maps `LatLng` for map SDKs / geo math.
  LatLng get latLng => LatLng(latitude, longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationValue &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(latitude, longitude, isValid);

  @override
  String toString() => 'LocationValue($latitude, $longitude, valid: $isValid)';
}

/// Exact-location input — a latitude + longitude pair with a "use my
/// current location" (GPS) button and a "pick on map" button. Pairs with
/// [AddressForm]'s postal address for precise delivery.
///
///  * Lat/long typed as decimal degrees (`31.9539`, `-35.9106`),
///    range-validated (±90 / ±180); the two inputs share a row and stack
///    when narrow ([ResponsiveFieldRow]).
///  * GPS button → [LocationUtils.currentPosition] (permission + service
///    handled; a spinner while it resolves; a warning row on failure).
///  * Map button → [LocationPickerSheet] (draggable map, centre pin).
///
/// Emits [LocationValue] via [onLocationChanged] — null while either
/// coordinate is missing / out of range.
///
/// ```dart
/// LocationField(
///   latController: lat,
///   lngController: lng,
///   onLocationChanged: (loc) => cubit.setPoint(loc?.latLng),
/// )
/// ```
class LocationField extends StatefulWidget {
  const LocationField({
    super.key,
    this.latController,
    this.lngController,
    this.initial,
    this.onLocationChanged,
    this.onPointPicked,
    this.identifier,
    this.enabled = true,
    this.validationMode = ValidationMode.onInteraction,
    this.showCurrentLocationButton = true,
    this.showMapButton = true,
    this.style,
    // Testing seam: override the GPS fetch (defaults to real geolocator).
    this.fetchCurrentLocation,
  });

  final TextEditingController? latController;
  final TextEditingController? lngController;

  /// Seed the map picker + inputs.
  final LatLng? initial;

  /// Parsed point on every change — null while incomplete / out of range.
  final ValueChanged<LocationValue?>? onLocationChanged;

  /// Fires ONLY when a point lands via the GPS or map buttons — never
  /// while typing. The hook for reverse-geocode-driven form filling.
  final ValueChanged<LatLng>? onPointPicked;

  /// Null → localized "Exact location".
  final String? identifier;

  final bool enabled;
  final ValidationMode validationMode;

  final bool showCurrentLocationButton;
  final bool showMapButton;

  final TextFieldStyle? style;

  /// Overrides the GPS source (tests / custom providers). Returns the
  /// device point, or null when unavailable.
  final Future<LatLng?> Function()? fetchCurrentLocation;

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  TextEditingController? _ownedLat, _ownedLng;
  final _lngFocus = FocusNode();
  bool _locating = false;
  bool _failed = false;

  static final _coord = RegExp(r'[^0-9.\-]');

  TextEditingController get _lat =>
      widget.latController ?? (_ownedLat ??= TextEditingController());
  TextEditingController get _lng =>
      widget.lngController ?? (_ownedLng ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    final seed = widget.initial;
    if (seed != null) {
      _lat.text = _render(seed.latitude);
      _lng.text = _render(seed.longitude);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emit();
      });
    }
  }

  @override
  void dispose() {
    _ownedLat?.dispose();
    _ownedLng?.dispose();
    _lngFocus.dispose();
    super.dispose();
  }

  String _render(double v) => v
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');

  double? _parse(String s) => double.tryParse(s.trim());

  bool _inRange(double? v, double bound) =>
      v != null && v >= -bound && v <= bound;

  void _emit() {
    final cb = widget.onLocationChanged;
    if (cb == null) return;
    final lat = _parse(_lat.text);
    final lng = _parse(_lng.text);
    if (lat == null || lng == null) {
      cb(null);
      return;
    }
    cb(
      LocationValue(
        latitude: lat,
        longitude: lng,
        isValid: _inRange(lat, 90) && _inRange(lng, 180),
      ),
    );
  }

  void _setPoint(LatLng p) {
    _lat.text = _render(p.latitude);
    _lng.text = _render(p.longitude);
    setState(() => _failed = false);
    _emit();
    widget.onPointPicked?.call(p);
  }

  LatLng? _currentPoint() {
    final lat = _parse(_lat.text);
    final lng = _parse(_lng.text);
    return (lat != null && lng != null) ? LatLng(lat, lng) : null;
  }

  Future<void> _useCurrent() async {
    setState(() {
      _locating = true;
      _failed = false;
    });
    final fetch = widget.fetchCurrentLocation ?? _defaultFetch;
    final point = await fetch();
    if (!mounted) return;
    setState(() => _locating = false);
    if (point == null) {
      setState(() => _failed = true);
      return;
    }
    _setPoint(point);
  }

  Future<LatLng?> _defaultFetch() async {
    final pos = await LocationUtils.currentPosition();
    return pos == null ? null : LatLng(pos.latitude, pos.longitude);
  }

  Future<void> _pickOnMap() async {
    final picked = await LocationPickerSheet.show(
      context,
      initial: _currentPoint() ?? widget.initial,
    );
    if (!mounted || picked == null) return;
    _setPoint(picked);
  }

  /// GPS convention: 6 decimal places (~11cm) is the useful ceiling.
  static const _maxDecimals = 6;

  /// Clean + HARD-BLOCK: one leading `-`, one `.`, at most 6 decimals,
  /// and a magnitude that can never exceed [bound] — typing `95` into
  /// latitude rejects the second digit instead of flagging it later.
  List<TextInputFormatter> _coordFormatters(double bound) => [
    TextInputFormatter.withFunction((oldV, newV) {
      final cleaned = newV.text.replaceAll(_coord, '');
      // At most one leading '-' and one '.'.
      final sign = cleaned.startsWith('-') ? '-' : '';
      final body = cleaned.replaceAll('-', '');
      final dot = body.indexOf('.');
      final normBody = dot < 0
          ? body
          : '${body.substring(0, dot + 1)}${body.substring(dot + 1).replaceAll('.', '')}';
      final text = '$sign$normBody';
      // Decimal-precision cap.
      final dotAt = text.indexOf('.');
      if (dotAt >= 0 && text.length - dotAt - 1 > _maxDecimals) {
        return oldV;
      }
      // Magnitude cap — partial values like '-', '.', '-.' parse null and
      // pass through (they're on the way to something legal).
      final value = double.tryParse(text);
      if (value != null && value.abs() > bound) return oldV;
      if (text == newV.text) return newV;
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: text.length.clamp(0, text.length),
        ),
      );
    }),
  ];

  /// Range check for prefilled / pasted values the block can't cover —
  /// empty stays lenient (a location is optional by nature).
  String? _coordValidator(String? v, double bound, String message) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final parsed = double.tryParse(t);
    if (parsed == null || parsed.abs() > bound) return message;
    return null;
  }

  /// One segment of the joined lat|lng control. [radii] squares the seam
  /// corner; [suffix] carries the action buttons on the longitude half.
  /// [bound] drives both the keystroke block and the range validator.
  Widget _coordSegment(
    TextEditingController c,
    String label, {
    required BorderRadius radii,
    required double bound,
    required String rangeMessage,
    TextFieldSuffix? suffix,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    final base = widget.style ?? const TextFieldStyle();
    return SimpleTextField(
      controller: c,
      focusNode: focusNode,
      identifier: label,
      hint: '0.000000',
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: _coordFormatters(bound),
      validator: (v) => _coordValidator(v, bound, rangeMessage),
      validationMode: widget.validationMode,
      sizing: const TextFieldSizing(height: kJoinedPairBoxHeight),
      style: base.copyWith(borderRadius: radii),
      suffix: suffix,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: (_) => _emit(),
    );
  }

  /// GPS + map buttons living as the longitude segment's trailing widget.
  /// [GlobalIconButton.isLoading] carries the locating spinner; the 36px
  /// box mirrors the module's compact suffix-button footprint.
  Widget _actionCluster() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.showCurrentLocationButton)
        GlobalIconButton(
          iconData: Icons.my_location,
          iconSize: 20,
          tooltip: LocationFieldStrings.useCurrent,
          isLoading: _locating,
          enabled: widget.enabled,
          enforceMinTouchTarget: false,
          style: const ButtonStateStyle(width: 36, height: 36),
          onPressed: _useCurrent,
        ),
      if (widget.showMapButton)
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: GlobalIconButton(
            iconData: Icons.map_outlined,
            iconSize: 20,
            tooltip: LocationFieldStrings.pickMap,
            enabled: widget.enabled,
            enforceMinTouchTarget: false,
            style: const ButtonStateStyle(width: 36, height: 36),
            onPressed: _pickOnMap,
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final radii = joinedPairRadii(context);
    final hasActions = widget.showCurrentLocationButton || widget.showMapButton;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header only when the caller names the field — the per-segment
        // "Latitude"/"Longitude" labels already identify it.
        if (widget.identifier != null)
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: Text(
              widget.identifier!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        // Joined lat|lng — facing corners squared, no gap (one control);
        // the action buttons ride as the longitude half's trailing slot.
        // Longitude gets extra flex so its value isn't crushed by the
        // trailing buttons (equal flex left the coordinate truncated).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _coordSegment(
                _lat,
                LocationFieldStrings.latitude,
                radii: radii.start,
                bound: 90,
                rangeMessage: LocationFieldStrings.latRange,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _lngFocus.requestFocus(),
              ),
            ),
            Expanded(
              flex: hasActions ? 3 : 2,
              child: _coordSegment(
                _lng,
                LocationFieldStrings.longitude,
                radii: radii.end,
                bound: 180,
                rangeMessage: LocationFieldStrings.lngRange,
                focusNode: _lngFocus,
                textInputAction: TextInputAction.done,
                suffix: hasActions
                    ? TextFieldSuffix.widget(_actionCluster())
                    : null,
              ),
            ),
          ],
        ),
        if (_failed)
          Padding(
            padding: EdgeInsets.only(top: context.spacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: context.statusColors.error,
                ),
                SizedBox(width: context.spacing.xs),
                Expanded(
                  child: Text(
                    LocationFieldStrings.unavailable,
                    style: TextStyle(
                      color: context.statusColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
