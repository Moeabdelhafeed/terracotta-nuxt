import 'package:flutter/foundation.dart';

/// The floor for every device service.
///
/// These were loose top-level `const`s in `device_constants.dart` and
/// three MUTABLE public statics on `NetworkQualityUtils` — which is a
/// setting an app changes by assigning to another class's field at
/// some unspecified point in its life, and there is no way to read
/// back what it was.
abstract final class DeviceDefaults {
  /// How long a VOLATILE reading stays fresh — battery level,
  /// connectivity type. Long enough that a page polling it does not
  /// hammer the platform channel, short enough to still be true.
  static const valueTtl = Duration(seconds: 30);

  /// How long a STABLE fact stays fresh — model, OS version, bundle
  /// id, the app's own version. These change when the app is replaced,
  /// which it is not while it is running.
  static const infoTtl = Duration(hours: 1);

  /// Below this percentage the battery counts as low.
  static const batteryLowThreshold = 20;

  /// Whether a capability that has failed its probe stops being
  /// probed.
  ///
  /// On by default: a simulator has no battery API and no torch, and
  /// re-asking the platform on every rebuild is a channel round-trip
  /// per frame for an answer that cannot change without a relaunch.
  static const latchUnavailable = true;

  /// Whether an EXPECTED unavailability says so in the log — once per
  /// capability, at debug level.
  ///
  /// The failure itself is not news: nobody needs telling that the
  /// simulator has no flashlight. The first line is worth having
  /// because a real device that reports no torch means something very
  /// different, and there would otherwise be nothing to see.
  static const logUnavailable = kDebugMode;

  /// Where [NetworkQualityUtils] opens a socket to measure latency.
  ///
  /// A latency probe REACHES A THIRD PARTY, which is a decision a
  /// template must not quietly make for the apps forked from it: the
  /// default is Cloudflare's resolver rather than a Google host
  /// because it is the one with a published no-logging policy, and an
  /// adopter with their own backend should point this at it.
  static const pingHost = 'one.one.one.one';
  static const pingPort = 443;
  static const pingTimeout = Duration(seconds: 3);

  /// Latency ceilings, in milliseconds, for each quality band.
  static const excellentBelowMs = 200;
  static const goodBelowMs = 500;
  static const fairBelowMs = 1500;

  /// URL schemes [LauncherUtils] will hand to the platform.
  ///
  /// An allow-list rather than a deny-list, because the failure is
  /// asymmetric: a scheme missing from here is a link that does not
  /// open, and a scheme that should not be here is `javascript:` in a
  /// remote-config string being executed, or `file:` reading a path
  /// off the device. Everything an app actually links to is here;
  /// anything else is a deliberate addition by the app that wants it.
  static const urlSchemes = <String>{
    'http',
    'https',
    'mailto',
    'tel',
    'sms',
    'geo',
    'maps',
  };

  /// Answers used when the real value cannot be read.
  static const brightness = 0.5;
  static const volume = 0.5;
}

/// How the device services behave. The bag.
///
/// Every field is nullable: unanswered means "ask the floor". It
/// carries no COLOURS and no sizes — nothing here paints. What a house
/// sets once is the POLICY: how long a reading is trusted, whether a
/// dead capability keeps being asked, who gets pinged, which schemes
/// may be launched.
@immutable
class DevicePolicy {
  const DevicePolicy({
    this.valueTtl,
    this.infoTtl,
    this.batteryLowThreshold,
    this.latchUnavailable,
    this.logUnavailable,
    this.pingHost,
    this.pingPort,
    this.pingTimeout,
    this.excellentBelowMs,
    this.goodBelowMs,
    this.fairBelowMs,
    this.urlSchemes,
    this.brightness,
    this.volume,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = DevicePolicy(
    valueTtl: DeviceDefaults.valueTtl,
    infoTtl: DeviceDefaults.infoTtl,
    batteryLowThreshold: DeviceDefaults.batteryLowThreshold,
    latchUnavailable: DeviceDefaults.latchUnavailable,
    logUnavailable: DeviceDefaults.logUnavailable,
    pingHost: DeviceDefaults.pingHost,
    pingPort: DeviceDefaults.pingPort,
    pingTimeout: DeviceDefaults.pingTimeout,
    excellentBelowMs: DeviceDefaults.excellentBelowMs,
    goodBelowMs: DeviceDefaults.goodBelowMs,
    fairBelowMs: DeviceDefaults.fairBelowMs,
    urlSchemes: DeviceDefaults.urlSchemes,
    brightness: DeviceDefaults.brightness,
    volume: DeviceDefaults.volume,
  );

  /// A dashboard that is ABOUT the device: nothing is cached, because
  /// a battery readout that is thirty seconds stale is a bug on a
  /// screen whose whole purpose is to show the battery. `/device-showcase`
  /// runs on this.
  static const live = DevicePolicy(
    valueTtl: Duration.zero,
    infoTtl: Duration(minutes: 1),
    latchUnavailable: false,
  );

  /// A background worker: read once, trust it for a long time, and
  /// never talk to a third party.
  static const frugal = DevicePolicy(
    valueTtl: Duration(minutes: 5),
    infoTtl: Duration(hours: 12),
    pingHost: '',
  );

  final Duration? valueTtl;
  final Duration? infoTtl;
  final int? batteryLowThreshold;
  final bool? latchUnavailable;
  final bool? logUnavailable;

  /// Empty disables the latency probe — [NetworkQualityUtils.measure]
  /// then answers from the connection TYPE alone and opens no socket.
  final String? pingHost;
  final int? pingPort;
  final Duration? pingTimeout;

  final int? excellentBelowMs;
  final int? goodBelowMs;
  final int? fairBelowMs;

  final Set<String>? urlSchemes;
  final double? brightness;
  final double? volume;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  DevicePolicy mergedWith(DevicePolicy? other) {
    if (other == null) return this;
    return DevicePolicy(
      valueTtl: other.valueTtl ?? valueTtl,
      infoTtl: other.infoTtl ?? infoTtl,
      batteryLowThreshold: other.batteryLowThreshold ?? batteryLowThreshold,
      latchUnavailable: other.latchUnavailable ?? latchUnavailable,
      logUnavailable: other.logUnavailable ?? logUnavailable,
      pingHost: other.pingHost ?? pingHost,
      pingPort: other.pingPort ?? pingPort,
      pingTimeout: other.pingTimeout ?? pingTimeout,
      excellentBelowMs: other.excellentBelowMs ?? excellentBelowMs,
      goodBelowMs: other.goodBelowMs ?? goodBelowMs,
      fairBelowMs: other.fairBelowMs ?? fairBelowMs,
      urlSchemes: other.urlSchemes ?? urlSchemes,
      brightness: other.brightness ?? brightness,
      volume: other.volume ?? volume,
    );
  }

  DevicePolicy copyWith({
    Duration? valueTtl,
    Duration? infoTtl,
    int? batteryLowThreshold,
    bool? latchUnavailable,
    bool? logUnavailable,
    String? pingHost,
    int? pingPort,
    Duration? pingTimeout,
    int? excellentBelowMs,
    int? goodBelowMs,
    int? fairBelowMs,
    Set<String>? urlSchemes,
    double? brightness,
    double? volume,
  }) => DevicePolicy(
    valueTtl: valueTtl ?? this.valueTtl,
    infoTtl: infoTtl ?? this.infoTtl,
    batteryLowThreshold: batteryLowThreshold ?? this.batteryLowThreshold,
    latchUnavailable: latchUnavailable ?? this.latchUnavailable,
    logUnavailable: logUnavailable ?? this.logUnavailable,
    pingHost: pingHost ?? this.pingHost,
    pingPort: pingPort ?? this.pingPort,
    pingTimeout: pingTimeout ?? this.pingTimeout,
    excellentBelowMs: excellentBelowMs ?? this.excellentBelowMs,
    goodBelowMs: goodBelowMs ?? this.goodBelowMs,
    fairBelowMs: fairBelowMs ?? this.fairBelowMs,
    urlSchemes: urlSchemes ?? this.urlSchemes,
    brightness: brightness ?? this.brightness,
    volume: volume ?? this.volume,
  );

  /// Fold this bag onto the floor. There is no middle layer — see the
  /// module's `CLAUDE.md` on why a `ThemeExtension` cannot serve here.
  ResolvedDevicePolicy resolve() {
    final m = DevicePolicy.defaults.mergedWith(this);
    return ResolvedDevicePolicy(
      valueTtl: m.valueTtl!,
      infoTtl: m.infoTtl!,
      batteryLowThreshold: m.batteryLowThreshold!,
      latchUnavailable: m.latchUnavailable!,
      logUnavailable: m.logUnavailable!,
      pingHost: m.pingHost!,
      pingPort: m.pingPort!,
      pingTimeout: m.pingTimeout!,
      excellentBelowMs: m.excellentBelowMs!,
      goodBelowMs: m.goodBelowMs!,
      fairBelowMs: m.fairBelowMs!,
      urlSchemes: m.urlSchemes!,
      brightness: m.brightness!,
      volume: m.volume!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DevicePolicy &&
      other.valueTtl == valueTtl &&
      other.infoTtl == infoTtl &&
      other.batteryLowThreshold == batteryLowThreshold &&
      other.latchUnavailable == latchUnavailable &&
      other.logUnavailable == logUnavailable &&
      other.pingHost == pingHost &&
      other.pingPort == pingPort &&
      other.pingTimeout == pingTimeout &&
      other.excellentBelowMs == excellentBelowMs &&
      other.goodBelowMs == goodBelowMs &&
      other.fairBelowMs == fairBelowMs &&
      setEquals(other.urlSchemes, urlSchemes) &&
      other.brightness == brightness &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(
    valueTtl,
    infoTtl,
    batteryLowThreshold,
    latchUnavailable,
    logUnavailable,
    pingHost,
    pingPort,
    pingTimeout,
    excellentBelowMs,
    goodBelowMs,
    fairBelowMs,
    urlSchemes == null ? null : Object.hashAllUnordered(urlSchemes!),
    brightness,
    volume,
  );
}

/// A [DevicePolicy] with every question answered.
@immutable
class ResolvedDevicePolicy {
  const ResolvedDevicePolicy({
    required this.valueTtl,
    required this.infoTtl,
    required this.batteryLowThreshold,
    required this.latchUnavailable,
    required this.logUnavailable,
    required this.pingHost,
    required this.pingPort,
    required this.pingTimeout,
    required this.excellentBelowMs,
    required this.goodBelowMs,
    required this.fairBelowMs,
    required this.urlSchemes,
    required this.brightness,
    required this.volume,
  });

  final Duration valueTtl;
  final Duration infoTtl;
  final int batteryLowThreshold;
  final bool latchUnavailable;
  final bool logUnavailable;
  final String pingHost;
  final int pingPort;
  final Duration pingTimeout;
  final int excellentBelowMs;
  final int goodBelowMs;
  final int fairBelowMs;
  final Set<String> urlSchemes;
  final double brightness;
  final double volume;

  /// Whether the latency probe runs at all.
  bool get pingsHost => pingHost.isNotEmpty;

  /// Whether [scheme] may be handed to the platform launcher.
  /// Case-insensitive — `HTTPS:` is a URL a server can send.
  bool allowsScheme(String scheme) => urlSchemes.contains(scheme.toLowerCase());
}
