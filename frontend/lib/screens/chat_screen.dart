import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../theme/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/call_provider.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/audio_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final Map<String, dynamic>? otherUser;
  final Map<String, dynamic>? property;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherUser,
    this.property,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isOtherTyping = false;
  bool _isOtherRecording = false;
  Timer? _typingTimer;
  Timer? _presenceTimer;
  bool _isOtherOnline = false;
  String? _lastSeenAt;

  // Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _localAudioPath;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    WebSocketService().subscribe('private-conversation.${widget.conversationId}', _onMessageEvent);
    _fetchPresence();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchPresence());
  }

  Future<void> _fetchPresence() async {
    final otherId = widget.otherUser?['id'];
    if (otherId == null) return;
    try {
      final status = await ChatService.getUserStatus(otherId);
      if (mounted) {
        setState(() {
          _isOtherOnline = status['is_online'] == true;
          _lastSeenAt = status['last_seen_at'];
        });
      }
    } catch (_) {}
  }

  void _onMessageEvent(dynamic event) {
    if (event.eventName == 'message.sent' || event.eventName == r'App\Events\MessageSent') {
      try {
        final data = json.decode(event.data);
        final message = data['message'] ?? data;
        
        final authProvider = context.read<AuthProvider>();
        if (message['sender_id'].toString() == authProvider.user?['id'].toString()) return;

        if (mounted) {
          setState(() {
            _messages.add(message);
            _isOtherTyping = false;
          });
          _typingTimer?.cancel();
          _scrollToBottom();
          // We received a message while in the chat screen, it is immediately read
          ChatService.markAsRead(widget.conversationId).then((_) {
             if (mounted) context.read<ChatProvider>().fetchUnreadCount();
          });
        }
      } catch(e) {
        debugPrint('Error parsing realtime message: $e');
      }
    } else if (event.eventName == 'message.status_updated' || event.eventName == r'App\Events\MessageStatusUpdated') {
      _reloadMessagesSilent();
    } else if (event.eventName == 'client-typing') {
      if (mounted) {
        setState(() {
          _isOtherTyping = true;
          _isOtherRecording = false; // Typing overrides recording
        });
        _scrollToBottom();
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isOtherTyping = false);
        });
      }
    } else if (event.eventName == 'client-recording') {
      if (mounted) {
        setState(() {
          _isOtherRecording = true;
          _isOtherTyping = false; // Recording overrides typing
        });
        _scrollToBottom();
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isOtherRecording = false);
        });
      }
    } else if (event.eventName == 'message.deleted' || event.eventName == r'App\Events\MessageDeleted') {
      try {
        final data = json.decode(event.data);
        final msgId = data['message_id'] ?? data['id'];
        final deletedForEveryone = data['deleted_for_everyone'] == true;
        if (mounted && deletedForEveryone && msgId != null) {
          setState(() {
            final idx = _messages.indexWhere((m) => m['id'] == msgId);
            if (idx != -1) {
              // Copy to mutable map — JSON-decoded maps are unmodifiable
              final mutable = Map<String, dynamic>.from(_messages[idx]);
              mutable['deleted_for_everyone_at'] = DateTime.now().toIso8601String();
              _messages[idx] = mutable;
            }
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _reloadMessagesSilent() async {
    try {
      final data = await ChatService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = data;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _presenceTimer?.cancel();
    WebSocketService().unsubscribe('private-conversation.${widget.conversationId}');
    _recordTimer?.cancel();
    _recorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Recording methods
  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        String? path;
        
        if (!kIsWeb) {
          final dir = await getTemporaryDirectory();
          path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        
        await _recorder.start(const RecordConfig(), path: path ?? '');
        
        // Signal the other user that we are recording
        WebSocketService().triggerEvent(
          'private-conversation.${widget.conversationId}', 
          'client-recording', 
          {}
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _localAudioPath = path;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      // Fix: ensure UI resets on error
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
    });
    
    // Send a "stop recording" (typing pulse) to clear the recording status for the other user
    WebSocketService().triggerEvent(
      'private-conversation.${widget.conversationId}', 
      'client-typing', 
      {}
    );
    
    if (path != null) {
      _sendAudioMessage(path);
    }
  }

  void _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    
    if (!kIsWeb && _localAudioPath != null) {
      try {
        final file = io.File(_localAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
      _localAudioPath = null;
    });

    // Notify the other user that we stopped recording
    WebSocketService().triggerEvent(
      'private-conversation.${widget.conversationId}', 
      'client-typing', 
      {}
    );
  }

  Future<void> _sendAudioMessage(String path) async {
    setState(() => _isSending = true);
    try {
      final msg = await ChatService.sendAudioMessage(
        conversationId: widget.conversationId,
        audioPath: path,
        durationMs: _recordDuration * 1000,
      );
      if (mounted) {
        setState(() {
          _messages.add(msg);
          _isSending = false;
          _recordDuration = 0;
          _localAudioPath = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')} $e')),
        );
      }
    }
  }


  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    await _loadAuthToken();
    try {
      final data = await ChatService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = data;
          _isLoading = false;
        });
        _scrollToBottom();
        // Mark as read
        await ChatService.markAsRead(widget.conversationId);
        if (mounted) {
          context.read<ChatProvider>().fetchUnreadCount();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final msg = await ChatService.sendMessage(widget.conversationId, text);
      if (mounted) {
        setState(() {
          _messages.add(msg);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')} $e')),
        );
      }
    }
  }

  Future<void> _loadAuthToken() async {
    final token = await ApiService.getToken();
    if (mounted) {
      setState(() => _authToken = token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?['id'];

    final otherName = widget.otherUser?['name'] ?? 'User';
    String? otherAvatarUrl = widget.otherUser?['full_avatar_url'] ?? widget.otherUser?['avatar'];
    if (otherAvatarUrl != null && otherAvatarUrl.isNotEmpty && !otherAvatarUrl.startsWith('http')) {
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      // Use proxy/storage prefix for relative paths
      otherAvatarUrl = '$baseUrl/proxy/storage/' + otherAvatarUrl.replaceFirst('/', '');
    }
    final propertyTitle = widget.property?['title'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: isDark ? DarkColors.background : LightColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.bodyLarge?.color, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (_isOtherOnline)
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: otherAvatarUrl != null && otherAvatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: otherAvatarUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _buildInitialsAvatar(otherName, 40),
                            )
                          : _buildInitialsAvatar(otherName, 40),
                    ),
                  ),
                  if (_isOtherOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    _buildSubtitleText(context, theme, propertyTitle),
                  ],
                ),
              ),
            ],
          ),
          actions: [
             IconButton(
               icon: Icon(Icons.call, color: theme.textTheme.bodyMedium?.color),
               onPressed: () {
                 final callProvider = context.read<CallProvider>();
                 callProvider.startCall(context, widget.conversationId, widget.otherUser);
               },
             ),
             IconButton(
               icon: Icon(Icons.info_outline_rounded, color: theme.textTheme.bodyMedium?.color),
               onPressed: () {},
             ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: isDark ? DarkColors.divider : LightColors.divider,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : (_messages.isEmpty && !_isOtherTyping && !_isOtherRecording)
                    ? Center(
                        child: Text(
                          context.tr('no_messages'),
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length + ((_isOtherTyping || _isOtherRecording) ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          // Typing / Recording bubble as last item
                          if (i == _messages.length && (_isOtherTyping || _isOtherRecording)) {
                            return _buildTypingBubble(theme, isDark, isRecording: _isOtherRecording);
                          }
                          final msg = _messages[i];
                          final isMine = msg['sender_id'].toString() == currentUserId.toString();
                          return _buildBubble(msg, isMine, theme, isDark, currentUserId);
                        },
                      ),
          ),
          // Input bar
          _buildInputBar(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMine, ThemeData theme, bool isDark, dynamic currentUserId) {
    final time = _formatMsgTime(msg['created_at']?.toString());
    final isRead = msg['read_at'] != null || msg['status'] == 'read';
    final isDelivered = msg['delivered_at'] != null;
    final isDeletedForEveryone = msg['deleted_for_everyone_at'] != null;

    final otherAvatar = widget.otherUser?['full_avatar_url'] ?? widget.otherUser?['avatar'];
    final otherName = widget.otherUser?['name'] ?? 'User';
    final authProvider = context.read<AuthProvider>();
    final myAvatar = authProvider.user?['full_avatar_url'] ?? authProvider.user?['avatar'];
    final myName = authProvider.user?['name'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _buildSmallAvatar(otherAvatar?.toString(), otherName, 26),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isDeletedForEveryone ? null : () => _showDeleteMenu(msg, isMine),
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: (isMine && !isDeletedForEveryone) 
                ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight) 
                : null,
            color: isDeletedForEveryone
                ? (isDark ? DarkColors.backgroundSecondary.withValues(alpha: 0.5) : Colors.grey.shade100)
                : !isMine
                    ? (isDark ? DarkColors.card : Colors.white)
                    : null,
            border: (!isMine && !isDeletedForEveryone) ? Border.all(color: isDark ? DarkColors.divider : LightColors.divider, width: 1) : null,
            boxShadow: [
               if (!isDeletedForEveryone)
                  BoxShadow(
                    color: (isMine ? AppColors.primary : Colors.black).withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
            ],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMine ? const Radius.circular(20) : const Radius.circular(6),
              bottomRight: isMine ? const Radius.circular(6) : const Radius.circular(20),
            ),
          ),
                child: Column(
                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (isDeletedForEveryone)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('message_deleted'),
                            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          ),
                        ],
                      )
                    else if (msg['type'] == 'audio')
                      AudioMessageBubble(
                        audioUrl: _buildFullAudioUrl(msg['audio_url']?.toString()),
                        durationMs: msg['audio_duration'] is int 
                            ? msg['audio_duration'] 
                            : int.tryParse(msg['audio_duration']?.toString() ?? ''),
                        isMine: isMine,
                        createdAt: DateTime.tryParse(msg['created_at']?.toString() ?? ''),
                      )
                    else if (msg['type'] == 'system')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.perm_phone_msg, size: 16, color: isMine ? Colors.white70 : Colors.grey),
                           const SizedBox(width: 6),
                           Text(
                             msg['message']?.toString() ?? '',
                             style: TextStyle(
                               fontSize: 15, 
                               fontStyle: FontStyle.italic,
                               color: isMine ? Colors.white : theme.textTheme.bodyLarge?.color, 
                             ),
                           ),
                        ],
                      )
                    else
                      Text(
                        msg['message']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 15, 
                          color: isMine ? Colors.white : theme.textTheme.bodyLarge?.color, 
                          height: 1.4,
                          letterSpacing: -0.2
                        ),
                      ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDeletedForEveryone
                                ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)
                                : isMine ? Colors.white.withValues(alpha: 0.7) : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                  if (isMine && !isDeletedForEveryone) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all_rounded : (isDelivered ? Icons.done_all_rounded : Icons.check_rounded),
                      size: 14,
                      color: isRead ? const Color(0xFF34B7F1).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ), // <-- Closes Flexible
    if (isMine) ...[
      const SizedBox(width: 8),
      _buildSmallAvatar(myAvatar, myName, 26),
    ],
  ],
),
);
  }

  void _showDeleteMenu(Map<String, dynamic> msg, bool isMine) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
                title: Text(context.tr('delete_for_me')),
                onTap: () { Navigator.pop(ctx); _deleteForMe(msg['id'] is int ? msg['id'] as int : int.parse(msg['id'].toString())); },
              ),
              if (isMine && msg['deleted_for_everyone_at'] == null)
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                  title: Text(context.tr('delete_for_everyone')),
                  onTap: () { Navigator.pop(ctx); _deleteForEveryone(msg['id'] is int ? msg['id'] as int : int.parse(msg['id'].toString())); },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAvatar(String? url, String name, double size) {
    String? fullUrl = url;
    if (fullUrl != null && fullUrl.isNotEmpty) {
      if (!fullUrl.startsWith('http')) {
        final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
        // Ensure relative paths go through proxy
        fullUrl = '$baseUrl/proxy/storage/' + fullUrl.replaceFirst('/', '');
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildInitialsAvatar(name, size),
        ),
      );
    }
    return _buildInitialsAvatar(name, size);
  }

  Future<void> _deleteForMe(int messageId) async {
    try {
      await ChatService.deleteMessageForMe(widget.conversationId, messageId);
      if (mounted) setState(() => _messages.removeWhere((m) => m['id'].toString() == messageId.toString()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('error')} $e')));
    }
  }

  Future<void> _deleteForEveryone(int messageId) async {
    debugPrint('🗑️ deleteForEveryone called: msgId=$messageId, convId=${widget.conversationId}');
    try {
      await ChatService.deleteMessageForEveryone(widget.conversationId, messageId);
      debugPrint('✅ API call succeeded');
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'].toString() == messageId.toString());
          debugPrint('🔍 Found message at idx=$idx');
          if (idx != -1) {
            // Copy to mutable map — JSON-decoded maps are unmodifiable
            final mutable = Map<String, dynamic>.from(_messages[idx]);
            mutable['deleted_for_everyone_at'] = DateTime.now().toIso8601String();
            _messages[idx] = mutable;
            debugPrint('🔄 State updated: deleted_for_everyone_at set');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ deleteForEveryone error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('error')} $e')));
    }
  }

  Widget _buildTypingBubble(ThemeData theme, bool isDark, {bool isRecording = false}) {
    final otherAvatar = widget.otherUser?['full_avatar_url'] ?? widget.otherUser?['avatar'];
    final otherName = widget.otherUser?['name'] ?? 'User';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSmallAvatar(otherAvatar?.toString(), otherName, 26),
          const SizedBox(width: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: (_isOtherTyping || _isOtherRecording) ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? DarkColors.card : Colors.white,
                border: Border.all(color: isDark ? DarkColors.divider : LightColors.divider, width: 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: isRecording 
                  ? TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.5, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, double val, child) {
                        return Transform.scale(
                          scale: val,
                          child: child,
                        );
                      },
                      child: Icon(Icons.mic, color: AppColors.primary, size: 20),
                      onEnd: () {
                         // Loop logic would require a stateful widget, but flutter's TweenAnimationBuilder
                         // doesn't loop easily without keys. Let's just use a simple static icon or subtle fade for now
                         // A static icon with a primary color matches whatsapp style
                      },
                    )
                  : const _TypingDotsAnimation(),
            ),
          ),
        ],
      ),
    );
  }

  String _buildFullAudioUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    
    // Use the secure streaming endpoint to handle CORS and auth
    final filename = url.split('/').last;
    var fullUrl = '${ApiService.baseUrl}/conversations/${widget.conversationId}/audio-stream/$filename';
    
    // Add token for Web/Playback compatibility if we have it
    if (_authToken != null) {
      fullUrl += '?token=$_authToken';
    }
    return fullUrl;
  }

  Widget _buildInputBar(ThemeData theme, bool isDark) {
    if (_isRecording) {
      return _buildRecordingBar(theme, isDark);
    }
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.background : LightColors.background,
        border: Border(top: BorderSide(color: isDark ? DarkColors.divider : LightColors.divider, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? DarkColors.divider : LightColors.divider, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onChanged: (val) {
                  setState(() {});
                  WebSocketService().triggerEvent(
                    'private-conversation.${widget.conversationId}', 
                    'client-typing', 
                    {}
                  );
                },
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: context.tr('type_message'),
                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (_messageController.text.trim().isEmpty)
            GestureDetector(
              onTap: _startRecording,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? DarkColors.card : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? DarkColors.divider : LightColors.divider, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 24),
              ),
            )
          else
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                  ]
                ),
                alignment: Alignment.center,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar(ThemeData theme, bool isDark) {
    final minutes = (_recordDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDuration % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.background : LightColors.background,
        border: Border(top: BorderSide(color: isDark ? DarkColors.divider : LightColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: _cancelRecording,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "$minutes:$seconds",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('recording') ?? 'Recording...',
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatMsgTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  Widget _buildSubtitleText(BuildContext context, ThemeData theme, String? propertyTitle) {
    // Priority: typing (now shown as bubble) > online > last seen > property
    if (_isOtherTyping) {
      return Text(
        context.tr('typing'),
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: AppColors.primary,
        ),
      );
    }

    if (_isOtherRecording) {
      return Text(
        context.tr('recording') + ' audio...',
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: AppColors.primary,
        ),
      );
    }

    if (_isOtherOnline) {
      return Text(
        context.tr('online'),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4CAF50),
        ),
      );
    }

    if (_lastSeenAt != null) {
      return Text(
        _formatLastSeen(_lastSeenAt!),
        style: TextStyle(
          fontSize: 12,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        ),
      );
    }

    if (propertyTitle != null) {
      return Text(
        propertyTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary.withValues(alpha: 0.8),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatLastSeen(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 2) return 'just now';
      if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return 'last seen ${date.day}/${date.month} at $h:$m';
    } catch (_) {
      return '';
    }
  }
}

/// Animated 3-dot typing indicator widget
class _TypingDotsAnimation extends StatefulWidget {
  const _TypingDotsAnimation();

  @override
  State<_TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<_TypingDotsAnimation> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) =>
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers.map((c) =>
      Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      ),
    ).toList();

    // Stagger the animations
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) =>
        AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _animations[i].value),
            child: Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
