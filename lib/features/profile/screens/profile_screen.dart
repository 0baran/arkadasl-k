import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../core/constants.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profilim',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 140),
        child: Column(
          children: [
            // Hero Avatar
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: user?.photoUrls.isNotEmpty == true
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(user!.photoUrls.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: user?.photoUrls.isEmpty == true
                        ? Center(
                            child: Text(
                              user?.name.substring(0, 1).toUpperCase() ?? 'A',
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          )
                        : null,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // İsim ve Email
            Text(
              user?.name ?? 'Kullanıcı',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Bilgi Kartı
            _buildPremiumCard(
              context: context,
              title: 'Hakkımda',
              icon: Icons.person_outline_rounded,
              children: [
                _buildInfoRow('Cinsiyet', user?.gender ?? '-', Icons.wc_rounded),
                _buildDivider(),
                _buildInfoRow('Doğum Tarihi', user?.birthDate != null ? AppUtils.formatDate(user!.birthDate) : '-', Icons.cake_rounded),
                _buildDivider(),
                _buildInfoRow('Yaş', user?.birthDate != null ? AppUtils.formatAge(user!.birthDate) : '-', Icons.hourglass_bottom_rounded),
                _buildDivider(),
                _buildInfoRow('Biyografi', user?.bio ?? '-', Icons.menu_book_rounded),
              ],
            ),

            const SizedBox(height: 24),

            // Ayarlar Özeti Kartı
            _buildPremiumCard(
              context: context,
              title: 'Tercihler',
              icon: Icons.tune_rounded,
              children: [
                _buildInfoRow('Max Mesafe', '${user?.settings.maxDistance ?? 50} km', Icons.location_on_rounded),
                _buildDivider(),
                _buildInfoRow('Yaş Aralığı', '${user?.settings.minAge ?? 18} - ${user?.settings.maxAge ?? 50}', Icons.people_alt_rounded),
                _buildDivider(),
                _buildInfoRow('Bildirimler', user?.settings.notificationsEnabled == true ? 'Açık' : 'Kapalı', Icons.notifications_active_rounded),
              ],
            ),

            const SizedBox(height: 40),
            Text(
              'Sürüm ${AppConstants.appVersion}',
              style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard({required BuildContext context, required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 8),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15));
  }
}
