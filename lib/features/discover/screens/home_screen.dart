import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription? _notificationSubscription;
  final Set<String> _shownNotificationIds = {}; // Tekrar eden bildirimleri önle

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
      _setupNotificationListener(); // context güvenli olduktan sonra başlat
    });
  }

  void _setupNotificationListener() {
    if (!mounted) return;
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    _notificationSubscription = DatabaseService()
        .getUnreadNotificationsStream(currentUser.id)
        .listen((QuerySnapshot snapshot) {
      for (var doc in snapshot.docs) {
        // Aynı bildirimi tekrar gösterme
        if (_shownNotificationIds.contains(doc.id)) continue;
        _shownNotificationIds.add(doc.id);

        final data = doc.data() as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'Bildirim';
        final body = data['body'] as String? ?? '';
        final type = data['type'] as String? ?? 'general';

        // Bildirim türüne göre uygun kanal
        if (type == 'match') {
          NotificationService().showMatchNotification(title: title, body: body);
        } else {
          NotificationService().showMessageNotification(title: title, body: body);
        }

        // Okundu işaretle
        DatabaseService().markNotificationAsRead(currentUser.id, doc.id);
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  final List<Widget> _screens = [
    const DiscoverScreen(),
    const MatchesScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: math.max(MediaQuery.paddingOf(context).bottom + 12, 24),
          left: 24,
          right: 24,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black.withValues(alpha: 0.5) 
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : inactiveColor,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
