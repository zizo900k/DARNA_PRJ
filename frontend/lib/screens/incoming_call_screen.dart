import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/call_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

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
    
    if (callData == null) {
      return const SizedBox.shrink();
    }

    // Extract caller info from payload.
    // Assuming backend or pusher sends basic user info, or at least we have recipientId.
    // Ideally the caller info should be part of signalData or we just display "Incoming Call"
    // Let's rely on 'otherUser' if we passed it (only works if we already had standard chat context)
    // Wait, if it comes from the background, we only have senderId. For V1 we just say "Incoming Call".
    final senderId = callData['senderId'];
    final signalData = callData['signalData'] ?? {};
    final senderInfo = signalData['sender'] ?? {};
    final senderName = senderInfo['name'] ?? 'User $senderId';
    final senderAvatar = senderInfo['avatar'];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const Icon(Icons.phone_in_talk, size: 40, color: Colors.white54),
                const SizedBox(height: 20),
                Text(
                  'Incoming Voice Call',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            // Animation / Avatar placeholder
            if (senderAvatar != null && senderAvatar.toString().isNotEmpty)
              ClipOval(
                child: CachedNetworkImage(
                   imageUrl: senderAvatar.toString().contains('/storage/') 
                      ? senderAvatar.toString().replaceFirst('/storage/', '/proxy/storage/')
                      : (senderAvatar.toString().startsWith('http') ? senderAvatar.toString() : '${ApiService.baseUrl.replaceAll('/api', '')}/proxy/storage/${senderAvatar.toString().replaceFirst('/', '')}'),
                   width: 120, height: 120, fit: BoxFit.cover,
                   errorWidget: (context, url, error) => _buildInitialsAvatar(senderName, 120),
                )
              )
            else
              _buildInitialsAvatar(senderName, 120),
            
            // Accept / Reject Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => callProvider.rejectCall(context),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 8),
                        const Text('Decline', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      callProvider.acceptCall(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 8),
                        const Text('Accept', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
