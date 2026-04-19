import 'package:flutter/material.dart';
import '../services/webrtc_service.dart';
import '../navigation/app_router.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

// Import UI screens that we'll build next
import '../screens/incoming_call_screen.dart';
import '../screens/active_call_screen.dart';

class CallProvider with ChangeNotifier {
  static final CallProvider instance = CallProvider._internal();
  CallProvider._internal();
  factory CallProvider() => instance;

  bool _isCalling = false;
  bool _isReceivingCall = false;
  Map<String, dynamic>? _currentCallData;
  WebRTCService? _webrtcService;

  bool get isCalling => _isCalling;
  bool get isReceivingCall => _isReceivingCall;
  Map<String, dynamic>? get currentCallData => _currentCallData;
  WebRTCService? get webrtcService => _webrtcService;

  List<Map<String, dynamic>> _queuedSignals = [];

  void handleSignal(Map<String, dynamic> payload) {
    final signal = payload['signalData'];
    if (signal == null) return;
    
    final type = signal['type'];

    if (type == 'offer') {
      if (_isCalling || _isReceivingCall) {
        // Can't accept another call. Reject it automatically.
        _rejectIncomingSilently(payload);
        return;
      }

      _currentCallData = payload;
      _isReceivingCall = true;
      _queuedSignals.clear();
      notifyListeners();

      // Show global incoming call screen/dialog
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context != null) {
         showDialog(
            context: context,
            barrierDismissible: false,
            useSafeArea: false,
            builder: (ctx) => const IncomingCallScreen(),
         );
      }
    } else if (type == 'answer' || type == 'candidate' || type == 'end_call') {
      if (_webrtcService != null) {
        _webrtcService!.handleSignaling(signal);
      } else {
        // If we get an end_call but no service (e.g. while in incoming call screen)
        if (type == 'end_call' && _isReceivingCall) {
           final context = AppRouter.rootNavigatorKey.currentContext;
           if (context != null && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
           }
           _cleanUp();
        } else if (type == 'candidate' || type == 'answer') {
           _queuedSignals.add(signal);
        }
      }
    }
  }

  Future<void> _rejectIncomingSilently(Map<String, dynamic> payload) async {
    final tempService = WebRTCService(conversationId: payload['conversationId']);
    await tempService.endCall(status: 'declined');
  }

  void startCall(BuildContext context, int conversationId, Map<String, dynamic>? otherUser) {
    _isCalling = true;
    _currentCallData = {
      'recipientId': otherUser?['id'], 
      'conversationId': conversationId,
      'otherUser': otherUser, // pass this explicitly for UI
    };
    _queuedSignals.clear();
    
    _initWebRTC(conversationId, isCaller: true).catchError((e) {
       debugPrint('WebRTC Call error: $e');
       endCall();
    });
    
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ActiveCallScreen(),
    ));
    
    notifyListeners();
  }

  Future<void> acceptCall(BuildContext context) async {
    if (_currentCallData == null) return;
    
    final convId = _currentCallData!['conversationId'];
    _isReceivingCall = false;
    _isCalling = true;
    notifyListeners();
    
    // Replace the incoming call dialog with the Active Call screen directly
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const ActiveCallScreen(),
    ));

    try {
      await _initWebRTC(convId, isCaller: false);
      await _webrtcService!.openUserMedia();
      final offerSdp = _currentCallData!['signalData']['sdp'];
      await _webrtcService!.handleSignaling({
         'type': 'offer',
         'sdp': offerSdp
      });
      await _webrtcService!.createAnswer();

      // Process queued signals (like early ICE candidates)
      for (var signal in _queuedSignals) {
         await _webrtcService!.handleSignaling(signal);
      }
      _queuedSignals.clear();
    } catch (e) {
      debugPrint('WebRTC Error on accept: $e');
      await endCall();
    }
  }

  Future<void> rejectCall(BuildContext context) async {
    if (_currentCallData != null) {
      final convId = _currentCallData!['conversationId'];
      final tempService = WebRTCService(conversationId: convId);
      await tempService.endCall(status: 'declined');
    }
    _cleanUp();
    if (Navigator.of(context).canPop()) {
       Navigator.of(context).pop(); // Close Incoming Call Screen
    }
  }

  Future<void> endCall() async {
    if (_webrtcService != null) {
      await _webrtcService!.endCall(status: 'ended');
    } else if (_currentCallData != null && _isCalling) {
      // Caller hung up before the callee accepted
      final convId = _currentCallData!['conversationId'];
      final tempService = WebRTCService(conversationId: convId);
      await tempService.endCall(status: 'canceled');
    }
    
    // Explicitly pop the call screen
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop()) {
       Navigator.of(context).pop();
    }
    _cleanUp();
  }

  Future<void> _initWebRTC(int conversationId, {required bool isCaller}) async {
    _webrtcService = WebRTCService(
      conversationId: conversationId,
      onCallEnded: () {
        // Find top context and pop if it has the call screen
        final context = AppRouter.rootNavigatorKey.currentContext;
        if (context != null && Navigator.of(context).canPop()) {
           Navigator.of(context).pop();
        }
        _cleanUp();
      },
      onRemoteStream: (stream) {
         notifyListeners(); // Refresh UI to attach the renderer
      }
    );

    await _webrtcService!.initConnection();

    if (isCaller) {
      await _webrtcService!.openUserMedia();
      await _webrtcService!.createOffer();
    }
  }

  void _cleanUp() {
    _isCalling = false;
    _isReceivingCall = false;
    _currentCallData = null;
    _webrtcService?.dispose();
    _webrtcService = null;
    notifyListeners();
  }
}
