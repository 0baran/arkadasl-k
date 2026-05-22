// ignore_for_file: prefer_final_fields
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/database_service.dart';
import '../models/match.dart';
import '../models/user.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final DatabaseService _databaseService = DatabaseService();

  List<Match> _matches = [];
  Map<String, User> _users = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId != null) {
        final matches = await _databaseService.getUserMatches(userId);

        // Load matched users
        for (var match in matches) {
          final otherUserId =
              match.userId1 == userId ? match.userId2 : match.userId1;
          final user = await _databaseService.getUser(otherUserId);
          if (user != null) {
            _users[otherUserId] = user;
          }
        }

        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matches.isEmpty) {
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
              'Eşleşmelerinizle mesajlaşmaya başlayın!',
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
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final otherUserId =
            match.userId1 == authProvider.currentUser?.id
                ? match.userId2
                : match.userId1;
        final user = _users[otherUserId];

        if (user == null) return const SizedBox();

        return _buildMessageCard(match, user);
      },
    );
  }

  Widget _buildMessageCard(Match match, User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoUrls.isNotEmpty
              ? NetworkImage(user.photoUrls.first)
              : null,
          child: user.photoUrls.isEmpty
              ? Text(user.name.substring(0, 1).toUpperCase())
              : null,
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppUtils.formatAge(user.birthDate),
              style: const TextStyle(fontSize: 12),
            ),
            if (match.lastMessage != null)
              Text(
                match.lastMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: match.lastMessageAt != null
            ? Text(
                AppUtils.formatTime(match.lastMessageAt!),
                style: const TextStyle(fontSize: 10),
              )
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(otherUser: user),
            ),
          );
        },
      ),
    );
  }
}
