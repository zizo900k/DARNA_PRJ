import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'api_service.dart';

class PusherEvent {
  final String eventName;
  final String? channelName;
  final dynamic data;

  PusherEvent({required this.eventName, this.channelName, this.data});
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  PusherChannelsClient? pusher;
  bool isInitialized = false;
  Map<String, PrivateChannel> subscriptions = {};
  final Map<String, List<Function(dynamic)>> _listeners = {};

  String get _wsHost {
    if (kIsWeb) {
      final uri = Uri.parse(ApiService.baseUrl);
      return uri.host; 
    }
    final uri = Uri.parse(ApiService.baseUrl);
    return uri.host;
  }
  
  String get _authEndpoint {
    return '${ApiService.baseUrl}/broadcasting/auth';
  }

  Future<void>? _initFuture;

  Future<void> init() {
    if (isInitialized) return Future.value();
    _initFuture ??= _doInit().whenComplete(() => _initFuture = null);
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return; 

      final options = PusherChannelsOptions.fromHost(
        scheme: 'ws',
        host: _wsHost,
        port: 8080,
        key: "mvkjflgkjdfkgjdfk",
        shouldSupplyMetadataQueries: true,
        metadata: PusherChannelsOptionsMetadata.byDefault(),
      );

      pusher = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (exception, trace, refresh) {
          debugPrint("Pusher connection error: $exception");
          refresh();
        },
      );

      pusher!.onConnectionEstablished.listen((_) {
        debugPrint("Pusher Connection Established to $_wsHost");
      });

      await pusher!.connect();
      isInitialized = true;
    } catch (e) {
      debugPrint("WebSocket INIT ERROR: $e");
    }
  }

  Future<void> subscribe(String channelName, Function(dynamic) onEvent) async {
    if (!isInitialized) await init();
    if (pusher == null) return;

    final token = await ApiService.getToken();
    if (token == null) return;

    if (_listeners.containsKey(channelName)) {
      if (!_listeners[channelName]!.contains(onEvent)) {
        _listeners[channelName]!.add(onEvent);
      }
      return;
    }
    
    _listeners[channelName] = [onEvent];

    try {
      final channel = pusher!.privateChannel(
        channelName,
        authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(_authEndpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      channel.bindToAll().listen((event) {
         final fakeEvent = PusherEvent(
           eventName: event.name,
           channelName: event.channelName,
           data: event.data is String ? event.data : jsonEncode(event.data),
         );
         final currentListeners = List<Function(dynamic)>.from(_listeners[channelName] ?? []);
         for (var listener in currentListeners) {
             try {
               listener(fakeEvent);
             } catch (e) {
               debugPrint("Listener error on $channelName: $e");
             }
         }
      });

      channel.subscribe();
      subscriptions[channelName] = channel;
      debugPrint("Subscribed to channel: $channelName");
    } catch (e) {
      debugPrint("Subscribe error on $channelName: $e");
    }
  }

  Future<void> triggerEvent(String channelName, String eventName, Map<String, dynamic> data) async {
    if (!isInitialized) return;
    try {
      final channel = subscriptions[channelName];
      if (channel != null) {
        channel.trigger(eventName: eventName, data: data);
      }
    } catch (e) {
      debugPrint("Trigger error on $channelName: $e");
    }
  }

  Future<void> unsubscribe(String channelName, [Function(dynamic)? onEvent]) async {
    if (!isInitialized) return;
    
    if (onEvent != null && _listeners.containsKey(channelName)) {
      _listeners[channelName]!.remove(onEvent);
      if (_listeners[channelName]!.isNotEmpty) {
        return; // Still have other listeners
      }
    }
    
    try {
      subscriptions[channelName]?.unsubscribe();
      subscriptions.remove(channelName);
      _listeners.remove(channelName);
      debugPrint("Unsubscribed from channel: $channelName");
    } catch (e) {
      debugPrint("Unsubscribe error on $channelName: $e");
    }
  }

  Future<void> disconnect() async {
    if (!isInitialized) return;
    try {
      pusher?.disconnect();
      isInitialized = false;
      _initFuture = null;
      subscriptions.clear();
      _listeners.clear();
      debugPrint("Pusher Disconnected");
    } catch (e) {
      debugPrint("Disconnect error: $e");
    }
  }
}

