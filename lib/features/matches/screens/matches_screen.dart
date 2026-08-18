// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../services/database_service.dart';
import '../../../models/match.dart';
import '../../../models/user.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../chat/screens/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  // Gereksiz Firestore okumalarını önlemek için kullanıcı önbelleği
  final Map<String, User> _userCache = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<User?> _getCachedUser(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    final user = await _databaseService.getUser(userId);
    if (user != null) _userCache[userId] = user;
    return user;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return SafeArea(
      child: Column(
        children: [
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<List<Match>>(
            stream: _databaseService.getUserMatchesStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Eşleşmeler yüklenirken hata oluştu'));
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
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
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final otherUserId = match.userId1 == userId ? match.userId2 : match.userId1;

            return FutureBuilder<User?>(
              future: _getCachedUser(otherUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  // Match alanı boş kalmasın — hafif placeholder göster
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 92, // Ortalama kart yüksekliği
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle)),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 120, height: 16, color: Colors.black12),
                              const SizedBox(height: 8),
                              Container(width: 80, height: 12, color: Colors.black12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!userSnapshot.data!.name.toLowerCase().contains(_searchQuery)) {
                  return const SizedBox.shrink();
                }

                return _buildMatchCard(match, userSnapshot.data!);
              },
            );
          },
        );
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
            hintText: 'Eşleşmelerde ara...',
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

  Widget _buildMatchCard(Match match, User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 2),
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
                              fontSize: 24,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // İsim ve Detaylar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cake_rounded, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${AppUtils.formatAge(user.birthDate)} yaşında',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (match.lastMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          match.lastMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
                // Sağ Ok (Action)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
