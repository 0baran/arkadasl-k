import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_provider.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../models/user.dart';
import '../core/theme.dart';
import '../core/utils.dart';

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
    final isMatch = await _databaseService.handleLike(authProvider.currentUser!.id, user.id, true);
    
    if (mounted) {
      if (isMatch) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 EŞLEŞTİNİZ! 🎉', textAlign: TextAlign.center),
            content: Text('${user.name} ile eşleştin. Hemen mesaj atmak ister misin?', textAlign: TextAlign.center),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
            ],
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
    await _databaseService.handleLike(authProvider.currentUser!.id, user.id, false);
    
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
    final isMatch = await _databaseService.handleLike(authProvider.currentUser!.id, user.id, true);
    
    if (mounted) {
      if (isMatch) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 SÜPER EŞLEŞME! 🎉', textAlign: TextAlign.center),
            content: Text('${user.name} ile süper eşleştin!', textAlign: TextAlign.center),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
            ],
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
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.outfit(color: AppTheme.errorColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNearbyUsers,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyUsers.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_dissatisfied,
                  size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Yakında kimse yok',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ayarlarınızı değiştirip tekrar deneyin',
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
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
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                // Premium Discover Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Keşfet',
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
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ]
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune),
                          color: AppTheme.primaryColor,
                          onPressed: () {},
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
                      return _buildUserProfileCard(_nearbyUsers[index]);
                    },
                    onIndexChanged: (index) {
                      // Handle card swipe
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(User user) {
    return Card(
      elevation: 12,
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Profile Image
          user.photoUrls.isNotEmpty
              ? Image.network(
                  user.photoUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                      child: const Icon(Icons.person, size: 100, color: Colors.white),
                    );
                  },
                )
              : Container(
                  decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                  child: const Icon(Icons.person, size: 100, color: Colors.white),
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
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.9),
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
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.8),
                      ]
                    )
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                          const SizedBox(width: 8),
                          Text(
                            AppUtils.formatAge(user.birthDate),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.9),
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
                          ]
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (user.bio.isNotEmpty)
                        Text(
                          user.bio,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.8),
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
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
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
            color: color.withOpacity(0.3),
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
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
      ),
    );
  }
}
