import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'dart:io' show Platform;
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

  String get _wsHost {
    if (kIsWeb) {
      final uri = Uri.parse(ApiService.baseUrl);
      return uri.host; 
    }
    if (Platform.isAndroid) return '10.0.2.2';
    if (Platform.isIOS) return '127.0.0.1';
    return '192.168.1.100'; 
  }
  
  String get _authEndpoint {
    return '${ApiService.baseUrl}/broadcasting/auth';
  }

  Future<void> init() async {
    if (isInitialized) return;

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
           // Reverb data payload might be decoded automatically or sent as string,
           // dart_pusher_channels usually returns String if it's string payload or dynamic Map
           data: event.data is String ? event.data : jsonEncode(event.data),
         );
         onEvent(fakeEvent);
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

  Future<void> unsubscribe(String channelName) async {
    if (!isInitialized) return;
    try {
      subscriptions[channelName]?.unsubscribe();
      subscriptions.remove(channelName);
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
      subscriptions.clear();
      debugPrint("Pusher Disconnected");
    } catch (e) {
      debugPrint("Disconnect error: $e");
    }
  }
}

