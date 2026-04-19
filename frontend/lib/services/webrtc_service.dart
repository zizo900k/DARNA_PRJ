import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class WebRTCService {
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  final int conversationId;
  final Function(MediaStream stream)? onRemoteStream;
  final Function(RTCSessionDescription offer)? onOfferReceived;
  final Function(RTCSessionDescription answer)? onAnswerReceived;
  final Function()? onCallEnded;

  bool isCaller = false;

  RTCVideoRenderer _audioRenderer = RTCVideoRenderer();
  RTCVideoRenderer get audioRenderer => _audioRenderer;

  WebRTCService({
    required this.conversationId,
    this.onRemoteStream,
    this.onOfferReceived,
    this.onAnswerReceived,
    this.onCallEnded,
  });

  Future<void> initConnection() async {
    await _audioRenderer.initialize();
    
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    peerConnection = await createPeerConnection(configuration);

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _sendSignal({
          'type': 'candidate',
          'candidate': {
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
            'candidate': candidate.candidate,
          }
        });
      }
    };

    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams.first;
        _audioRenderer.srcObject = remoteStream;
        onRemoteStream?.call(remoteStream!);
      }
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('WebRTC State: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        onCallEnded?.call();
      }
    };
  }

  Future<void> openUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    try {
      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      if (localStream != null && peerConnection != null) {
        localStream!.getTracks().forEach((track) {
          peerConnection!.addTrack(track, localStream!);
        });
      }
    } catch (e) {
      debugPrint("Failed to get user media (ignoring to allow receive-only): $e");
    }
  }

  Future<void> createOffer() async {
    if (peerConnection == null) return;
    
    isCaller = true;
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    _sendSignal({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  Future<void> createAnswer() async {
    if (peerConnection == null) return;

    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    _sendSignal({
      'type': 'answer',
      'sdp': answer.sdp,
    });
  }

  /// Normalize SDP line endings for WebRTC parser compatibility.
  /// Chrome's WebRTC parser is strict about \r\n line endings.
  String _fixSdp(String sdp) {
    // Normalize all line endings to \r\n
    String fixed = sdp.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll('\n', '\r\n');
    // Ensure trailing \r\n
    if (!fixed.endsWith('\r\n')) {
      fixed = '$fixed\r\n';
    }
    return fixed;
  }

  Future<void> handleSignaling(Map<String, dynamic> signal) async {
    final type = signal['type'];

    if (type == 'offer') {
      final sdp = signal['sdp'];
      if (sdp != null) {
        if (peerConnection == null) await initConnection();
        final fixedSdp = _fixSdp(sdp.toString());
        await peerConnection?.setRemoteDescription(
            RTCSessionDescription(fixedSdp, type));
        onOfferReceived?.call(RTCSessionDescription(fixedSdp, type));
      }
    } else if (type == 'answer') {
      final sdp = signal['sdp'];
      if (sdp != null) {
        final fixedSdp = _fixSdp(sdp.toString());
        await peerConnection?.setRemoteDescription(
            RTCSessionDescription(fixedSdp, type));
        onAnswerReceived?.call(RTCSessionDescription(fixedSdp, type));
      }
    } else if (type == 'candidate') {
      final candidateObj = signal['candidate'];
      if (candidateObj != null) {
        final candidate = RTCIceCandidate(
          candidateObj['candidate'],
          candidateObj['sdpMid'],
          candidateObj['sdpMLineIndex'],
        );
        await peerConnection?.addCandidate(candidate);
      }
    } else if (type == 'end_call') {
      dispose();
      onCallEnded?.call();
    }
  }

  Future<void> _sendSignal(Map<String, dynamic> data) async {
    try {
      final token = await ApiService.getToken();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/conversations/$conversationId/call/signal'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error sending signaling metadata: $e');
    }
  }

  Future<void> endCall({String? status}) async {
    await _sendSignal({
      'type': 'end_call',
      'status': status,
    });
    dispose();
    onCallEnded?.call();
  }

  void toggleMute() {
    if (localStream != null) {
      final audioTracks = localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        audioTracks.first.enabled = !audioTracks.first.enabled;
      }
    }
  }
  
  bool isMuted() {
    if (localStream != null) {
      final audioTracks = localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        return !audioTracks.first.enabled;
      }
    }
    return false;
  }

  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    
    try {
      _audioRenderer.srcObject = null;
      _audioRenderer.dispose();
    } catch (_) {}
    
    localStream?.getTracks().forEach((track) {
      try { track.stop(); } catch (_) {}
    });
    try { localStream?.dispose(); } catch (_) {}
    try { remoteStream?.dispose(); } catch (_) {}
    try { peerConnection?.close(); } catch (_) {}
    try { peerConnection?.dispose(); } catch (_) {}
    
    localStream = null;
    remoteStream = null;
    peerConnection = null;
  }
}
