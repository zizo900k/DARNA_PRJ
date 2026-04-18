import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../theme/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().addListener(_onChatProviderChange);
    });
  }

  void _onChatProviderChange() {
    if (mounted) {
      _loadConversations(skipRefreshCount: true);
    }
  }

  @override
  void dispose() {
    context.read<ChatProvider>().removeListener(_onChatProviderChange);
    super.dispose();
  }

  Future<void> _loadConversations({bool skipRefreshCount = false}) async {
    setState(() => _isLoading = true);
    try {
      final data = await ChatService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
      if (mounted && !skipRefreshCount) {
        context.read<ChatProvider>().fetchUnreadCount();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme, isDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryLight.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(context.tr('require_login'),
                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/signin'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: Text(context.tr('signin')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, isDark),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _conversations.isEmpty
              ? _buildEmpty(theme)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, i) {
                      final isLast = i == _conversations.length - 1;
                      return _buildConversationTile(_conversations[i], theme, isDark, isLast);
                    },
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            context.tr('messages'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyLarge?.color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? DarkColors.divider : LightColors.divider,
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primaryLight.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('no_conversations'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Text(
              context.tr('no_conversations_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
      Map<String, dynamic> conv, ThemeData theme, bool isDark, bool isLast) {
    final otherUser = conv['other_user'] as Map<String, dynamic>?;
    final property = conv['property'] as Map<String, dynamic>?;
    final unreadCount = conv['unread_count'] ?? 0;
    final hasUnread = unreadCount > 0;
    final lastMessage = conv['last_message']?.toString() ?? '';
    final time = _formatTime(conv['last_message_at']?.toString());
    final name = otherUser?['name'] ?? 'User';
    String? avatar = otherUser?['full_avatar_url'] ?? otherUser?['avatar'];
    if (avatar != null && avatar.isNotEmpty && !avatar.startsWith('http')) {
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      avatar = '$baseUrl/proxy/storage/' + avatar.replaceFirst('/', '');
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/chat/${conv['id']}', extra: {
            'conversationId': conv['id'],
            'otherUser': otherUser,
            'property': property,
          });
        },
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(
                    bottom: BorderSide(
                      color: isDark ? DarkColors.divider : const Color(0xFFF0F0F0),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Avatar with online-ready stack
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: hasUnread ? 0.25 : 0.0),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: avatar != null && avatar.toString().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: avatar,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _defaultAvatar(name),
                              errorWidget: (_, __, ___) => _defaultAvatar(name),
                            )
                          : _defaultAvatar(name),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? AppColors.primary : theme.textTheme.bodyMedium?.color,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (property != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.home_outlined, size: 11, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  property['title'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    Text(
                      lastMessage.isEmpty ? '...' : lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread
                            ? theme.textTheme.bodyLarge?.color
                            : theme.textTheme.bodyMedium?.color,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
