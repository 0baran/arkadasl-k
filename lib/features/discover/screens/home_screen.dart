import 'dart:ui';
import 'package:flutter/material.dart';
import 'discover_screen.dart';
import '../../matches/screens/matches_screen.dart';
import '../../chat/screens/messages_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../services/update_service.dart';
import '../../../services/notification_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
    NotificationService().initialize();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    _notificationSubscription = DatabaseService()
        .getUnreadNotificationsStream(currentUser.id)
        .listen((QuerySnapshot snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final title = data['title'] ?? 'Bildirim';
        final body = data['body'] ?? '';
        
        // Bildirimi göster
        NotificationService().showMessageNotification(title: title, body: body);
        
        // Bildirimi okundu olarak işaretle ki bir daha çıkmasın
        DatabaseService().markNotificationAsRead(currentUser.id, doc.id);
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  final List<Widget> _screens = const [
    DiscoverScreen(),
    MatchesScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navBar = Theme.of(context).bottomNavigationBarTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          decoration: BoxDecoration(
            color: navBar.backgroundColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(0, Icons.explore_rounded, 'Keşfet', primary),
                    _buildNavItem(1, Icons.favorite_rounded, 'Eşleşmeler', primary),
                    _buildNavItem(2, Icons.chat_bubble_rounded, 'Mesajlar', primary),
                    _buildNavItem(3, Icons.person_rounded, 'Profil', primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color primaryColor) {
    final isSelected = _currentIndex == index;
    final inactiveColor = Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey;
    final selectedBg = primaryColor.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : inactiveColor,
              size: 26,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              child: SizedBox(
                width: isSelected ? null : 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
