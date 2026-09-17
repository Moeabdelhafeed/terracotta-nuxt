import 'dart:async';

import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';
import '../types/result.dart';

/// Lifecycle states emitted by [RealtimeService.connectionState].
///
/// Adapters advance through these in the obvious order:
/// `disconnected → connecting → connected → (reconnecting ↔ connected) → disconnected`.
/// A terminal [failed] is emitted when reconnection attempts exhaust.
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// A single message received on a channel. Adapters normalize whatever
/// the wire delivers into this shape.
///
/// - [data] is always a JSON-decoded `Map<String, dynamic>`. Most
///   backends speak JSON; adapters for others (MQTT, binary WS) put
///   the decoded payload here if they can, else leave it empty.
/// - [raw] is the unparsed bytes — escape hatch for binary protocols
///   or when consumers want to skip JSON decoding.
@immutable
class RealtimeEvent {
  const RealtimeEvent({
    required this.channel,
    required this.name,
    this.data = const {},
    this.raw,
    required this.timestamp,
  });

  final String channel;
  final String name;
  final Map<String, dynamic> data;
  final Uint8List? raw;
  final DateTime timestamp;

  @override
  String toString() => 'RealtimeEvent($channel::$name, data: $data)';
}

/// Member of a presence-enabled channel. Backends without presence
/// (raw WS, Pusher public channels) never emit these.
@immutable
class PresenceMember {
  const PresenceMember({required this.id, this.info = const {}});
  final String id;
  final Map<String, dynamic> info;
}

/// Resolves per-channel auth payloads. Pusher private channels need a
/// signed token from your backend; Ably uses token-request flows; raw
/// WebSocket protocols vary. Pass one to [RealtimeService.subscribe]
/// for channels that require auth.
///
/// The returned map is handed to the adapter as-is — shape depends on
/// the backend's auth contract.
///
/// ```dart
/// Future<Map<String, String>> myAuth(String channel) async {
///   final r = await api.post('/broadcasting/auth', body: {'channel': channel});
///   return r.data.cast<String, String>();
/// }
///
/// Realtime.subscribe('private-orders', auth: myAuth);
/// ```
typedef AuthResolver = Future<Map<String, String>> Function(String channelName);

/// Handle to a subscribed channel. Listen on [events] (or the
/// filtered [on]) and call [unsubscribe] when done — the adapter
/// releases the underlying resources.
abstract class Channel {
  String get name;

  /// Every event on this channel, any name. Broadcast stream — safe
  /// to attach multiple listeners.
  Stream<RealtimeEvent> get events;

  /// Sub-stream of [events] filtered to a single [eventName].
  Stream<RealtimeEvent> on(String eventName);

  /// Presence roster updates. Adapters without presence emit an empty
  /// list once and never again.
  Stream<List<PresenceMember>> get presence;

  /// Release this subscription. Safe to call multiple times.
  Future<void> unsubscribe();
}

/// App-wide realtime abstraction — every backend (raw WS, Pusher,
/// Ably, Socket.IO) implements this single surface so feature code
/// stays vendor-agnostic.
///
/// Use [Realtime] for app-wide access; only touch this class directly
/// when writing a new adapter.
///
/// ## Connection model
///
/// One service instance owns one backend connection. Subscribing to
/// N channels on the same service does not open N sockets — the
/// adapter multiplexes internally. If you need multiple independent
/// connections (rare), instantiate multiple services.
///
/// ## Error handling
///
/// [connect], [subscribe], and [publish] all return
/// `Result<T, AppException>`. Transient disconnects are reflected
/// in [connectionState] — they don't produce a `Result.failure`
/// unless reconnection ultimately fails.
///
/// ## Threading / zones
///
/// All streams are broadcast and safe to subscribe to from anywhere
/// in the app. Adapters should schedule callbacks on the root zone so
/// `runZonedGuarded` in consumer code catches errors correctly.
abstract class RealtimeService {
  /// Current connection state, reactive. Safe to listen multiple times.
  Stream<ConnectionState> get connectionState;

  /// Snapshot of the current state — use for synchronous branching.
  ConnectionState get currentState;

  bool get isConnected => currentState == ConnectionState.connected;

  /// Bring the backend connection up. Idempotent — calling while
  /// already connected is a no-op that resolves with success.
  ///
  /// Failure cases:
  /// - Invalid URL / credentials → [NetworkException] or
  ///   [AuthException] wrapped in a `Result.failure`.
  /// - Adapter misconfiguration → [UnknownException].
  Future<Result<void, AppException>> connect();

  /// Tear down the connection and unsubscribe from all channels.
  /// Idempotent.
  Future<void> disconnect();

  /// Subscribe to [name]. Returns a [Channel] you can listen to.
  ///
  /// Behavior:
  /// - If not yet connected, the adapter queues the subscription and
  ///   executes it once the connection comes up.
  /// - Re-subscribing to the same [name] returns the same underlying
  ///   [Channel] (ref-counted). Calling `unsubscribe` N times releases
  ///   it (last reference wins).
  /// - Pass [auth] for private/encrypted channels.
  Future<Result<Channel, AppException>> subscribe(
    String name, {
    AuthResolver? auth,
  });

  /// Send an event from the client. Not all backends support
  /// client-originated publishes (Pusher free tier is server-only);
  /// adapters that can't return `Result.failure` with
  /// [UnknownException] (or a more specific subtype).
  Future<Result<void, AppException>> publish(
    String channel,
    String event,
    Map<String, dynamic> data,
  );

  /// Close all resources. Safe to call multiple times.
  void dispose();
}

/// Default backend — a no-op. Used when [Realtime] hasn't been
/// initialized or when realtime is explicitly disabled. Every method
/// resolves successfully and every stream stays empty.
///
/// Safe to use at startup before wiring a real adapter — app code can
/// call `Realtime.subscribe(...)` without crashing, just no events
/// flow until you `Realtime.register(real adapter)`.
class NoOpRealtimeService extends RealtimeService {
  final _stateCtrl = StreamController<ConnectionState>.broadcast();

  @override
  Stream<ConnectionState> get connectionState => _stateCtrl.stream;

  @override
  ConnectionState get currentState => ConnectionState.disconnected;

  @override
  Future<Result<void, AppException>> connect() async => const Success(null);

  @override
  Future<void> disconnect() async {}

  @override
  Future<Result<Channel, AppException>> subscribe(
    String name, {
    AuthResolver? auth,
  }) async {
    return Success(_NoOpChannel(name));
  }

  @override
  Future<Result<void, AppException>> publish(
    String channel,
    String event,
    Map<String, dynamic> data,
  ) async {
    return const Success(null);
  }

  @override
  void dispose() {
    _stateCtrl.close();
  }
}

class _NoOpChannel extends Channel {
  _NoOpChannel(this.name);

  @override
  final String name;

  @override
  Stream<RealtimeEvent> get events => const Stream.empty();

  @override
  Stream<RealtimeEvent> on(String eventName) => const Stream.empty();

  @override
  Stream<List<PresenceMember>> get presence => const Stream.empty();

  @override
  Future<void> unsubscribe() async {}
}
