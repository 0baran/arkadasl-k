import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/auth_provider.dart';
import '../../../services/database_service.dart';
import '../../../services/location_service.dart';
import '../../../models/user.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../profile/screens/settings_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();

  List<User> _nearbyUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  Future<void> _loadNearbyUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        // Get current user location
        final position = await _locationService.getCurrentPosition();

        // Update current user's stored location so others can find them
        final updatedUser = currentUser.copyWith(
          location: GeoLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
        await _databaseService.updateUser(updatedUser);
        authProvider.updateProfile(updatedUser);

        // Get nearby users
        final users = await _databaseService.getNearbyUsers(
          currentUser.id,
          position.latitude,
          position.longitude,
          currentUser.settings.maxDistance,
          currentUser.settings.minAge,
          currentUser.settings.maxAge,
          currentUser.settings.preferredGender,
          currentUser.blockedUsers,
        );

        setState(() {
          _nearbyUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLike(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    if (currentUserId == null) return;
    final isMatch = await _databaseService.handleLike(currentUserId, user.id, true);
    
    if (mounted) {
      if (isMatch) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉 EŞLEŞTİNİZ!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.photoUrls.isNotEmpty ? CachedNetworkImageProvider(user.photoUrls.first) : null,
                    child: user.photoUrls.isEmpty ? Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 40)) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Artik mesajlasabilirsiniz!', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Mesaj Gonder', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} beğenildi'), backgroundColor: AppTheme.successColor, duration: const Duration(seconds: 1)),
        );
      }
    }
    setState(() {
      _nearbyUsers.remove(user);
    });
  }

  Future<void> _handleDislike(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    if (currentUserId == null) return;
    await _databaseService.handleLike(currentUserId, user.id, false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} geçildi'), backgroundColor: AppTheme.errorColor, duration: const Duration(seconds: 1)),
      );
    }
    setState(() {
      _nearbyUsers.remove(user);
    });
  }

  Future<void> _handleSuperLike(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    if (currentUserId == null) return;
    final isMatch = await _databaseService.handleLike(currentUserId, user.id, true);
    
    if (mounted) {
      if (isMatch) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌟 SUPER ESLESME!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.photoUrls.isNotEmpty ? CachedNetworkImageProvider(user.photoUrls.first) : null,
                    child: user.photoUrls.isEmpty ? Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 40)) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Super bir eslesme!', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Mesaj Gonder', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} SÜPER BEĞENİLDİ! 🌟'), backgroundColor: AppTheme.accentColor, duration: const Duration(seconds: 1)),
        );
      }
    }
    setState(() {
      _nearbyUsers.remove(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      final isPermissionError = _errorMessage!.contains('izni');
      final isServiceError = _errorMessage!.contains('kapalı');

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermissionError || isServiceError ? Icons.location_off : Icons.error_outline, 
                  size: 64, 
                  color: AppTheme.errorColor
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.outfit(color: AppTheme.errorColor, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isPermissionError)
                  ElevatedButton(
                    onPressed: () async {
                      await _locationService.openAppSettings();
                    },
                    child: const Text('Ayarlara Git'),
                  ),
                if (isServiceError)
                  ElevatedButton(
                    onPressed: () async {
                      await _locationService.openLocationSettings();
                    },
                    child: const Text('Konumu Aç'),
                  ),
                if (isPermissionError || isServiceError)
                  const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loadNearbyUsers,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_nearbyUsers.isEmpty) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadNearbyUsers,
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Yakında kimse yok',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mesafe veya yas filtreni genisletip tekrar dene',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _loadNearbyUsers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Yenile'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          icon: const Icon(Icons.tune),
                          label: const Text('Filtreler'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNearbyUsers,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kesfet',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ]
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Swiper(
                  itemCount: _nearbyUsers.length,
                  layout: SwiperLayout.TINDER,
                  itemWidth: MediaQuery.of(context).size.width * 0.9,
                  itemHeight: MediaQuery.of(context).size.height * 0.65,
                  itemBuilder: (context, index) {
                    return _UserProfileCard(user: _nearbyUsers[index]);
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close,
            color: const Color(0xFFFF5252),
            size: 60,
            iconSize: 30,
            onPressed: () {
              if (_nearbyUsers.isNotEmpty) _handleDislike(_nearbyUsers.first);
            },
          ),
          _buildActionButton(
            icon: Icons.star_rounded,
            color: const Color(0xFFFFBE0B),
            size: 50,
            iconSize: 28,
            onPressed: () {
              if (_nearbyUsers.isNotEmpty) _handleSuperLike(_nearbyUsers.first);
            },
          ),
          _buildActionButton(
            icon: Icons.favorite,
            color: const Color(0xFF00E676),
            size: 60,
            iconSize: 30,
            onPressed: () {
              if (_nearbyUsers.isNotEmpty) _handleLike(_nearbyUsers.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        iconSize: iconSize,
        onPressed: onPressed,
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
      ),
    );
  }
}

class _UserProfileCard extends StatefulWidget {
  final User user;

  const _UserProfileCard({required this.user});

  @override
  State<_UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<_UserProfileCard> {
  int _currentPhotoIndex = 0;

  void _handleTap(TapUpDetails details, double width) {
    if (widget.user.photoUrls.isEmpty) return;
    
    final dx = details.localPosition.dx;
    if (dx < width / 3) {
      // Tap left
      if (_currentPhotoIndex > 0) {
        setState(() => _currentPhotoIndex--);
      }
    } else {
      // Tap right
      if (_currentPhotoIndex < widget.user.photoUrls.length - 1) {
        setState(() => _currentPhotoIndex++);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    
    return Card(
      elevation: 12,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapUp: (details) => _handleTap(details, constraints.maxWidth),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Profile Image
                user.photoUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.photoUrls[_currentPhotoIndex],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                          child: const Icon(Icons.person, size: 100, color: Colors.white),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                        child: const Icon(Icons.person, size: 100, color: Colors.white),
                      ),
                      
                // Photo Progress Bars
                if (user.photoUrls.length > 1)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: List.generate(user.photoUrls.length, (index) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 4,
                            decoration: BoxDecoration(
                              color: _currentPhotoIndex == index 
                                  ? Colors.white 
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                // Rich Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.0, 0.5, 0.8, 1.0],
                    ),
                  ),
                ),

                // User Info (Glassmorphic)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
                            ]
                          )
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user.relationshipGoal.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFFF416C).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                                  ]
                                ),
                                child: Text(
                                  '🎯 ${user.relationshipGoal}',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(right: 8, bottom: 10),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: user.isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                                          boxShadow: user.isOnline ? [
                                            BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.5), blurRadius: 6)
                                          ] : null,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          user.name,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppUtils.formatAge(user.birthDate),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                if (user.isVerified) ...[
                                  const SizedBox(width: 8),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6.0),
                                    child: Icon(Icons.verified, color: Colors.blue, size: 24),
                                  ),
                                ],
                              ],
                            ),
                            if (user.isOnline)
                              const Text('Online', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
                            if (user.jobTitle.isNotEmpty || user.school.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                child: Row(
                                  children: [
                                    if (user.jobTitle.isNotEmpty)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.work_outline, color: Colors.white70, size: 16),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(user.jobTitle, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      ),
                                    if (user.school.isNotEmpty)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.school_outlined, color: Colors.white70, size: 16),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(user.school, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (user.bio.isNotEmpty)
                              Text(
                                user.bio,
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 16),
                            if (user.interests.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.interests.take(3).map((interest) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      interest,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
