import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arkadaslik_uygulamasi/services/auth_provider.dart';
import 'package:arkadaslik_uygulamasi/services/database_service.dart';
import 'package:arkadaslik_uygulamasi/models/match.dart';
import 'package:arkadaslik_uygulamasi/models/user.dart';
import 'package:arkadaslik_uygulamasi/core/theme.dart';
import 'package:arkadaslik_uygulamasi/core/utils.dart';
import 'package:arkadaslik_uygulamasi/features/chat/screens/chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Match> _matches = [];
  final Map<String, User> _users = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        final matches = await _databaseService.getUserMatches(userId);
        for (var match in matches) {
          final otherUserId = match.userId1 == userId ? match.userId2 : match.userId1;
          final user = await _databaseService.getUser(otherUserId);
          if (user != null) _users[otherUserId] = user;
        }
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('Henuz mesaj yok', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text('Eslesmelerinizle mesajlasmaya baslayin!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    final filteredMatches = _matches.where((match) {
      final otherUserId = match.userId1 == currentUserId ? match.userId2 : match.userId1;
      final user = _users[otherUserId];
      if (user == null) return false;
      return user.name.toLowerCase().contains(_searchQuery);
    }).toList();

    return SafeArea(
      child: Column(
        children: [
        _buildSearchBar(),
        Expanded(
          child: filteredMatches.isEmpty
              ? Center(
                  child: Text(
                    'Sonuç bulunamadı',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMatches.length,
                  itemBuilder: (context, index) {
                    final match = filteredMatches[index];
                    final otherUserId = match.userId1 == currentUserId ? match.userId2 : match.userId1;
                    final user = _users[otherUserId]!;
                    return _buildMessageCard(match, user);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Mesajlarda ara...',
            hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(Match match, User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: user.photoUrls.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(user.photoUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user.photoUrls.isEmpty
                      ? Center(
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // İsim ve Son Mesaj
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        match.lastMessage ?? 'Şimdi sohbet etmeye başlayın!',
                        style: TextStyle(
                          fontSize: 14,
                          color: match.lastMessage != null ? AppTheme.textSecondary : AppTheme.primaryColor.withValues(alpha: 0.8),
                          fontStyle: match.lastMessage != null ? FontStyle.normal : FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Sağ taraf: Saat / Ok
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (match.lastMessageAt != null)
                      Text(
                        AppUtils.formatTime(match.lastMessageAt!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
