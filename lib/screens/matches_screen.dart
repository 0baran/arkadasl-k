import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/database_service.dart';
import '../models/match.dart';
import '../models/user.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return StreamBuilder<List<Match>>(
      stream: _databaseService.getUserMatchesStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Eşleşmeler yüklenirken hata oluştu'));
        }

        final _matches = snapshot.data ?? [];

        if (_matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz eşleşme yok',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keşfet ekranında yeni kişilerle tanışın!',
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
            final otherUserId = match.userId1 == userId ? match.userId2 : match.userId1;

            return FutureBuilder<User?>(
              future: _databaseService.getUser(otherUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();
                return _buildMatchCard(match, userSnapshot.data!);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMatchCard(Match match, User user) {
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
        trailing: const Icon(Icons.chevron_right),
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
