import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../error/app_exception.dart';
import '../types/result.dart';
import '../utils/loggers/logger.dart';
import 'realtime_service.dart';

// ─── Protocol strategy ──────────────────────────────────────────────────

/// Wire-level encode/decode strategy used by [WebSocketRealtimeAdapter].
/// Different backends use different envelope shapes; swap this out
/// when your server speaks something other than the bundled default.
///
/// The default ([DefaultRealtimeProtocol]) uses a JSON envelope:
///
///   `{"action": "subscribe", "channel": "orders"}`
///   `{"action": "publish", "channel": "orders", "event": "new", "data": {...}}`
///   `{"channel": "orders", "event": "new", "data": {...}}`   // incoming
///
/// This is a common shape (Laravel Echo server, Django Channels with
/// `AsyncJsonWebsocketConsumer`, simple Node.js handlers). If your
/// server uses STOMP / MQTT / a custom framing, subclass and override.
abstract class RealtimeProtocol {
  const RealtimeProtocol();

  String encodeSubscribe(String channel, Map<String, String>? auth);
  String encodeUnsubscribe(String channel);
  String encodePublish(String channel, String event, Map<String, dynamic> data);
  String encodePing();

  /// Parse an incoming wire message into a [RealtimeEvent], or null
  /// if the message is a non-event frame (pong, system message, …).
  RealtimeEvent? decode(String raw);
}

class DefaultRealtimeProtocol extends RealtimeProtocol {
  const DefaultRealtimeProtocol();

  @override
  String encodeSubscribe(String channel, Map<String, String>? auth) =>
      jsonEncode({
        'action': 'subscribe',
        'channel': channel,
        if (auth != null) 'auth': auth,
      });

  @override
  String encodeUnsubscribe(String channel) => jsonEncode({
    'action': 'unsubscribe',
    'channel': channel,
  });

  @override
  String encodePublish(
    String channel,
    String event,
    Map<String, dynamic> data,
  ) => jsonEncode({
    'action': 'publish',
    'channel': channel,
    'event': event,
    'data': data,
  });

  @override
  String encodePing() => jsonEncode({'action': 'ping'});

  @override
  RealtimeEvent? decode(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final channel = decoded['channel'] as String?;
      final event = decoded['event'] as String?;
      if (channel == null || event == null) return null;
      return RealtimeEvent(
        channel: channel,
        name: event,
        data: (decoded['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ─── Working adapter: raw WebSocket ─────────────────────────────────────

/// Raw WebSocket realtime adapter — ships working. Uses
/// [`web_socket_channel`](https://pub.dev/packages/web_socket_channel)
/// under the hood and the configurable [RealtimeProtocol] strategy for
/// wire framing.
///
/// ## Features
///  - **Auto-reconnect** with exponential backoff (1s → 2s → 4s → …
///    capped at [maxReconnectDelay]). Configurable attempt limit via
///    [maxReconnectAttempts].
///  - **Subscription replay** — on reconnect, every active channel
///    re-subscribes automatically. Consumers don't need to care about
///    the connection cycle.
///  - **Ref-counted channels** — `subscribe('orders')` twice returns
///    the same [Channel]; each `unsubscribe` decrements. The actual
///    wire-level unsubscribe fires when the last ref drops.
///  - **Optional ping** — sends a protocol-level ping every
///    [pingInterval] to keep NAT / proxies from idling the
///    connection. Pass `Duration.zero` to disable.
///
/// ## Limitations
///  - No presence out of the box (raw WS doesn't have the concept);
///    `channel.presence` always emits an empty list.
///  - Client-originated publish requires your server to accept the
///    default protocol's `publish` action. Servers that are read-only
///    will reject; handle that in consumer code.
///
/// ```dart
/// Realtime.register(WebSocketRealtimeAdapter(
///   url: 'wss://ws.example.com/app',
///   pingInterval: Duration(seconds: 30),
/// ));
/// await Realtime.connect();
/// ```
class WebSocketRealtimeAdapter extends RealtimeService {
  WebSocketRealtimeAdapter({
    required this.url,
    this.protocol = const DefaultRealtimeProtocol(),
    this.pingInterval = const Duration(seconds: 30),
    this.maxReconnectAttempts = 5,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 32),
    this.protocols,
  });

  final String url;
  final RealtimeProtocol protocol;
  final Duration pingInterval;
  final int maxReconnectAttempts;
  final Duration initialReconnectDelay;
  final Duration maxReconnectDelay;

  /// Optional WebSocket sub-protocols (e.g. `['graphql-transport-ws']`).
  final List<String>? protocols;

  WebSocketChannel? _ws;
  final _stateCtrl = StreamController<ConnectionState>.broadcast();
  ConnectionState _state = ConnectionState.disconnected;

  final _incoming = StreamController<RealtimeEvent>.broadcast();

  final Map<String, _WsChannel> _channels = {};
  final Map<String, int> _refCounts = {};
  final Map<String, AuthResolver?> _pendingAuth = {};

  StreamSubscription<dynamic>? _wsSub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;

  @override
  Stream<ConnectionState> get connectionState => _stateCtrl.stream;

  @override
  ConnectionState get currentState => _state;

  void _setState(ConnectionState s) {
    if (_state == s) return;
    _state = s;
    _stateCtrl.add(s);
  }

  @override
  Future<Result<void, AppException>> connect() async {
    if (_state == ConnectionState.connected ||
        _state == ConnectionState.connecting) {
      return const Success(null);
    }
    _manualDisconnect = false;
    _setState(ConnectionState.connecting);
    try {
      _ws = WebSocketChannel.connect(Uri.parse(url), protocols: protocols);
      await _ws!.ready;
      _wsSub = _ws!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      _reconnectAttempts = 0;
      _setState(ConnectionState.connected);
      _startPing();

      // Replay existing subscriptions.
      for (final entry in _pendingAuth.entries) {
        await _sendSubscribe(entry.key, entry.value);
      }
      return const Success(null);
    } catch (e, st) {
      Logger.m.w('[Realtime] connect failed: $e');
      _setState(ConnectionState.failed);
      return Result.failure(AppException.fromError(e, st));
    }
  }

  void _onMessage(dynamic message) {
    final raw = message is String ? message : message.toString();
    final event = protocol.decode(raw);
    if (event != null) _incoming.add(event);
  }

  void _onError(Object error) {
    Logger.m.w('[Realtime] ws stream error: $error');
    // onDone fires next and drives the reconnect loop.
  }

  void _onDone() {
    _wsSub?.cancel();
    _wsSub = null;
    _ws = null;
    _stopPing();
    if (_manualDisconnect) {
      _setState(ConnectionState.disconnected);
      return;
    }
    if (_reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      Logger.m.e('[Realtime] reconnect attempts exhausted');
      _setState(ConnectionState.failed);
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = _computeBackoff();
    _setState(ConnectionState.reconnecting);
    Logger.m.i(
      '[Realtime] reconnecting in ${delay.inMilliseconds}ms (attempt $_reconnectAttempts/$maxReconnectAttempts)',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      // Fire-and-forget; state is observed via _stateCtrl.
      connect();
    });
  }

  Duration _computeBackoff() {
    final exp = math.pow(2, _reconnectAttempts - 1).toInt();
    final ms = initialReconnectDelay.inMilliseconds * exp;
    return Duration(
      milliseconds: ms.clamp(
        initialReconnectDelay.inMilliseconds,
        maxReconnectDelay.inMilliseconds,
      ),
    );
  }

  void _startPing() {
    _stopPing();
    if (pingInterval == Duration.zero) return;
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (_state != ConnectionState.connected) return;
      try {
        _ws?.sink.add(protocol.encodePing());
      } catch (_) {
        // Sink closed between state check and send — no-op; onDone
        // will drive the reconnect.
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  @override
  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _stopPing();
    await _wsSub?.cancel();
    _wsSub = null;
    await _ws?.sink.close(status.normalClosure);
    _ws = null;
    _setState(ConnectionState.disconnected);
  }

  @override
  Future<Result<Channel, AppException>> subscribe(
    String name, {
    AuthResolver? auth,
  }) async {
    _refCounts[name] = (_refCounts[name] ?? 0) + 1;
    _pendingAuth[name] = auth;

    final existing = _channels[name];
    if (existing != null) return Success(existing);

    final channel = _WsChannel(
      name: name,
      source: _incoming.stream,
      onUnsubscribe: () => _unsubscribeChannel(name),
    );
    _channels[name] = channel;

    if (_state == ConnectionState.connected) {
      await _sendSubscribe(name, auth);
    }
    return Success(channel);
  }

  Future<void> _sendSubscribe(String name, AuthResolver? auth) async {
    try {
      final authPayload = auth != null ? await auth(name) : null;
      _ws?.sink.add(protocol.encodeSubscribe(name, authPayload));
    } catch (e) {
      Logger.m.w('[Realtime] subscribe("$name") failed: $e');
    }
  }

  Future<void> _unsubscribeChannel(String name) async {
    final next = (_refCounts[name] ?? 1) - 1;
    if (next > 0) {
      _refCounts[name] = next;
      return;
    }
    _refCounts.remove(name);
    _pendingAuth.remove(name);
    _channels.remove(name);
    if (_state == ConnectionState.connected) {
      try {
        _ws?.sink.add(protocol.encodeUnsubscribe(name));
      } catch (_) {
        // sink already closed — harmless.
      }
    }
  }

  @override
  Future<Result<void, AppException>> publish(
    String channel,
    String event,
    Map<String, dynamic> data,
  ) async {
    if (_state != ConnectionState.connected) {
      return const Result.failure(
        NetworkException(message: 'Realtime not connected'),
      );
    }
    try {
      _ws?.sink.add(protocol.encodePublish(channel, event, data));
      return const Success(null);
    } catch (e, st) {
      return Result.failure(AppException.fromError(e, st));
    }
  }

  @override
  void dispose() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _stopPing();
    _wsSub?.cancel();
    _ws?.sink.close();
    _incoming.close();
    _stateCtrl.close();
  }
}

class _WsChannel extends Channel {
  _WsChannel({
    required this.name,
    required Stream<RealtimeEvent> source,
    required this.onUnsubscribe,
  }) : _source = source;

  @override
  final String name;
  final Stream<RealtimeEvent> _source;
  final Future<void> Function() onUnsubscribe;
  bool _unsubscribed = false;

  @override
  Stream<RealtimeEvent> get events => _source.where((e) => e.channel == name);

  @override
  Stream<RealtimeEvent> on(String eventName) =>
      _source.where((e) => e.channel == name && e.name == eventName);

  @override
  Stream<List<PresenceMember>> get presence => const Stream.empty();

  @override
  Future<void> unsubscribe() async {
    if (_unsubscribed) return;
    _unsubscribed = true;
    await onUnsubscribe();
  }
}

// ─── Stub adapters for the major SaaS backends ──────────────────────────
//
// Same pattern as `analytics_adapters.dart`: method bodies are no-ops,
// the dartdoc spells out the pubspec dep + exact SDK calls. Pick one,
// install the package, replace the bodies, ship.

/// Adapter for [`pusher_channels_flutter`](https://pub.dev/packages/pusher_channels_flutter).
///
/// Required dependency:
/// ```yaml
/// pusher_channels_flutter: ^x.y.z
/// ```
///
/// Wire-up — replace the no-op bodies with:
///
/// ```dart
/// late final PusherChannelsFlutter _pusher;
///
/// @override
/// Future<Result<void, AppException>> connect() async {
///   _pusher = PusherChannelsFlutter.getInstance();
///   await _pusher.init(
///     apiKey: apiKey,
///     cluster: cluster,
///     onConnectionStateChange: (current, prev) =>
///         _setState(_mapPusherState(current)),
///     onEvent: (pEvent) {
///       _incoming.add(RealtimeEvent(
///         channel: pEvent.channelName,
///         name: pEvent.eventName,
///         data: jsonDecode(pEvent.data) as Map<String, dynamic>,
///         timestamp: DateTime.now(),
///       ));
///     },
///   );
///   await _pusher.connect();
///   return const Success(null);
/// }
///
/// @override
/// Future<Result<Channel, AppException>> subscribe(String name, {AuthResolver? auth}) async {
///   await _pusher.subscribe(channelName: name);
///   return Success(_PusherChannelHandle(name, _incoming.stream));
/// }
/// ```
///
/// Pusher **presence channels** (`presence-*`) emit member events
/// via the same `onEvent` callback — route `pusher:subscription_succeeded`
/// and `pusher:member_added/removed` into a per-channel
/// `StreamController<List<PresenceMember>>`.
class PusherRealtimeAdapter extends RealtimeService {
  PusherRealtimeAdapter({
    required this.apiKey,
    required this.cluster,
    this.authEndpoint,
  });

  final String apiKey;
  final String cluster;

  /// Backend endpoint that signs private / presence channel auth
  /// requests. Required for `private-*` and `presence-*` channels.
  final String? authEndpoint;

  final _stateCtrl = StreamController<ConnectionState>.broadcast();
  // Stays `disconnected` until the adapter is wired — flip to
  // non-final when you implement connect().
  final ConnectionState _state = ConnectionState.disconnected;

  @override
  Stream<ConnectionState> get connectionState => _stateCtrl.stream;

  @override
  ConnectionState get currentState => _state;

  @override
  Future<Result<void, AppException>> connect() async {
    // TODO(template): PusherChannelsFlutter.getInstance().init(...) + connect()
    return const Success(null);
  }

  @override
  Future<void> disconnect() async {
    // TODO(template): _pusher.disconnect()
  }

  @override
  Future<Result<Channel, AppException>> subscribe(
    String name, {
    AuthResolver? auth,
  }) async {
    // TODO(template): _pusher.subscribe(channelName: name)
    return const Result.failure(
      UnknownException(message: 'PusherRealtimeAdapter not implemented'),
    );
  }

  @override
  Future<Result<void, AppException>> publish(
    String channel,
    String event,
    Map<String, dynamic> data,
  ) async {
    // TODO(template): _pusher.trigger(PusherEvent(channelName: channel, eventName: event, data: jsonEncode(data)))
    return const Result.failure(
      UnknownException(message: 'PusherRealtimeAdapter not implemented'),
    );
  }

  @override
  void dispose() {
    _stateCtrl.close();
  }
}

/// Adapter for [`ably_flutter`](https://pub.dev/packages/ably_flutter).
///
/// Required dependency:
/// ```yaml
/// ably_flutter: ^x.y.z
/// ```
///
/// Wire-up:
///
/// ```dart
/// late final ably.Realtime _ably;
///
/// @override
/// Future<Result<void, AppException>> connect() async {
///   _ably = ably.Realtime(options: ably.ClientOptions(key: apiKey));
///   _ably.connection.on().listen((change) =>
///       _setState(_mapAblyState(change.current)));
///   await _ably.connection.once(ably.ConnectionState.connected);
///   return const Success(null);
/// }
///
/// @override
/// Future<Result<Channel, AppException>> subscribe(String name, {AuthResolver? auth}) async {
///   final channel = _ably.channels.get(name);
///   channel.subscribe().listen((message) => _incoming.add(...));
///   return Success(_AblyChannelHandle(channel, ...));
/// }
/// ```
///
/// Ably's `presence` API (`channel.presence.subscribe()`) maps
/// naturally onto [Channel.presence] — wire a
/// `StreamController<List<PresenceMember>>` per channel and `.add(...)`
/// on each presence update.
class AblyRealtimeAdapter extends RealtimeService {
  AblyRealtimeAdapter({required this.apiKey});

  final String apiKey;

  final _stateCtrl = StreamController<ConnectionState>.broadcast();
  // Stays `disconnected` until the adapter is wired — flip to
  // non-final when you implement connect().
  final ConnectionState _state = ConnectionState.disconnected;

  @override
  Stream<ConnectionState> get connectionState => _stateCtrl.stream;
  @override
  ConnectionState get currentState => _state;

  @override
  Future<Result<void, AppException>> connect() async {
    // TODO(template): _ably = Realtime(ClientOptions(key: apiKey)); await connected.
    return const Success(null);
  }

  @override
  Future<void> disconnect() async {
    // TODO(template): _ably.close()
  }

  @override
  Future<Result<Channel, AppException>> subscribe(
    String name, {
    AuthResolver? auth,
  }) async {
    return const Result.failure(
      UnknownException(message: 'AblyRealtimeAdapter not implemented'),
    );
  }

  @override
  Future<Result<void, AppException>> publish(
    String channel,
    String event,
    Map<String, dynamic> data,
  ) async {
    return const Result.failure(
      UnknownException(message: 'AblyRealtimeAdapter not implemented'),
    );
  }

  @override
  void dispose() {
    _stateCtrl.close();
  }
}

/// Adapter for [`socket_io_client`](https://pub.dev/packages/socket_io_client).
///
/// Required dependency:
/// ```yaml
/// socket_io_client: ^x.y.z
/// ```
///
/// Socket.IO models channels as **rooms** on the server + **namespaces**
/// on the client. This adapter maps one [subscribe] to joining a room
/// (via a custom event) and routes room-tagged incoming events.
///
/// ```dart
/// late final io.Socket _socket;
///
/// @override
/// Future<Result<void, AppException>> connect() async {
///   _socket = io.io(url, io.OptionBuilder().setTransports(['websocket']).build());
///   _socket.onConnect((_) => _setState(ConnectionState.connected));
///   _socket.onDisconnect((_) => _setState(ConnectionState.disconnected));
///   _socket.onAny((event, data) => _incoming.add(RealtimeEvent(...)));
///   _socket.connect();
///   return const Success(null);
/// }
///
/// @override
/// Future<Result<Channel, AppException>> subscribe(String name, {AuthResolver? auth}) async {
///   _socket.emit('join', {'room': name});
///   return Success(_SocketIoChannelHandle(name, _incoming.stream));
/// }
/// ```
class SocketIoRealtimeAdapter extends RealtimeService {
  SocketIoRealtimeAdapter({required this.url, this.options});

  final String url;

  /// Socket.IO options map — transports, path, reconnection settings.
  /// Consumed by `io.io(url, options)` when implemented.
  final Map<String, dynamic>? options;

  final _stateCtrl = StreamController<ConnectionState>.broadcast();
  // Stays `disconnected` until the adapter is wired — flip to
  // non-final when you implement connect().
  final ConnectionState _state = ConnectionState.disconnected;

  @override
  Stream<ConnectionState> get connectionState => _stateCtrl.stream;
  @override
  ConnectionState get currentState => _state;

  @override
  Future<Result<void, AppException>> connect() async {
    // TODO(template): io.io(url, options) + connect()
    return const Success(null);
  }

  @override
  Future<void> disconnect() async {
    // TODO(template): _socket.disconnect()
  }

  @override
  Future<Result<Channel, AppException>> subscribe(
    String name, {
    AuthResolver? auth,
  }) async {
    return const Result.failure(
      UnknownException(message: 'SocketIoRealtimeAdapter not implemented'),
    );
  }

  @override
  Future<Result<void, AppException>> publish(
    String channel,
    String event,
    Map<String, dynamic> data,
  ) async {
    return const Result.failure(
      UnknownException(message: 'SocketIoRealtimeAdapter not implemented'),
    );
  }

  @override
  void dispose() {
    _stateCtrl.close();
  }
}
