import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/call_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({super.key});

  Widget _buildInitialsAvatar(String name, double size) {
    String initials = name.isNotEmpty ? name.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
           initials,
           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    final callData = callProvider.currentCallData;

    if (!callProvider.isCalling || callData == null) {
      return const Scaffold(body: Center(child: Text('Call ended')));
    }

    final otherUser = callData['otherUser'] ?? (callData['signalData'] != null ? callData['signalData']['sender'] : null);
    final name = otherUser != null ? (otherUser['name'] ?? 'User') : 'Calling...';
    final avatar = otherUser != null ? otherUser['avatar'] : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Hidden RTCVideoRenderer for Audio stream handling on Web/RTC 
            if (callProvider.webrtcService != null)
              SizedBox(
                 width: 1, 
                 height: 1,
                 child: RTCVideoView(callProvider.webrtcService!.audioRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              ),

            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      if (avatar != null && avatar.toString().isNotEmpty)
                        ClipOval(
                          child: CachedNetworkImage(
                             imageUrl: avatar.toString().contains('/storage/') 
                                ? avatar.toString().replaceFirst('/storage/', '/proxy/storage/')
                                : (avatar.toString().startsWith('http') ? avatar.toString() : '${ApiService.baseUrl.replaceAll('/api', '')}/proxy/storage/${avatar.toString().replaceFirst('/', '')}'),
                             width: 100, height: 100, fit: BoxFit.cover,
                             errorWidget: (context, url, error) => _buildInitialsAvatar(name, 100),
                          )
                        )
                      else
                        _buildInitialsAvatar(name, 100),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Just show "In Call" or "Ringing..."
                      Text(
                        callProvider.webrtcService?.remoteStream != null 
                           ? 'Connected' 
                           : 'Ringing...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                           callProvider.webrtcService?.toggleMute();
                           // force rebuild to update icon
                           // callProvider.notifyListeners() is preferred but we rely on simple state for V1
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                             Icons.mic_off, 
                             color: Colors.white,
                             size: 28,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => callProvider.endCall(),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
