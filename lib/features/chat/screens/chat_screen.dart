import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../services/database_service.dart';
import '../../../models/user.dart';
import '../../../models/message.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';

class ChatScreen extends StatefulWidget {
  final User otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Ekran açılınca gelen mesajları okundu olarak işaretle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;
      if (currentUserId != null) {
        _databaseService.markMessagesAsRead(currentUserId, widget.otherUser.id);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUser.id,
      receiverId: widget.otherUser.id,
      content: text,
      timestamp: DateTime.now(),
    );

    try {
      await _databaseService.sendMessage(message);
      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<User?>(
          stream: _databaseService.getUserStream(widget.otherUser.id),
          builder: (context, snapshot) {
            final user = snapshot.data ?? widget.otherUser;
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user.photoUrls.isNotEmpty
                      ? NetworkImage(user.photoUrls.first)
                      : null,
                  child: user.photoUrls.isEmpty
                      ? Text(user.name.substring(0, 1).toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (user.isOnline)
                      const Text(
                        'Çevrimiçi',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      )
                    else if (user.lastSeen != null)
                      Text(
                        'Son Görülme: ${AppUtils.formatTime(user.lastSeen!)}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            );
          }
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
              if (currentUser == null) return;
              final currentUserId = currentUser.id;
              final navigator = Navigator.of(context); // context'i async öncesi kaydet
              if (value == 'block') {
                await _databaseService.blockUser(currentUserId, widget.otherUser.id);
                navigator.pop();
              } else if (value == 'report') {
                await _databaseService.reportUser(currentUserId, widget.otherUser.id, 'Rahatsız Edici / Spam');
                navigator.pop();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'report',
                child: Text('Şikayet Et'),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text('Engelle', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(builder: (context) {
              final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
              if (currentUserId == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<List<Message>>(
                stream: _databaseService.getMessagesStream(currentUserId, widget.otherUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Mesajlar yüklenemedi'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk mesajı siz gönderin!',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Messages stream comes orderBy descending
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            );
          },
        ),
      ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    // listen: false — mesaj balonları her değişimde yeniden inşa edilmesin
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isFromMe = message.senderId == authProvider.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isFromMe 
              ? AppTheme.primaryColor 
              : (isDark ? const Color(0xFF2A2A35) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isFromMe 
                    ? Colors.white 
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppUtils.formatTime(message.timestamp),
              style: TextStyle(
                color: isFromMe 
                    ? Colors.white70 
                    : (isDark ? Colors.white54 : Colors.black54),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            color: isDark ? Colors.white70 : Colors.black54,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Resim gönderme yakında')),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Mesaj yazın...',
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: AppTheme.primaryColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
