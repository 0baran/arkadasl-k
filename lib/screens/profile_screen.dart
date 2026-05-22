import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Profile Header
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: authProvider.currentUser?.photoUrls.isNotEmpty ==
                      true
                  ? NetworkImage(authProvider.currentUser!.photoUrls.first)
                  : null,
              child: authProvider.currentUser?.photoUrls.isEmpty == true
                  ? Text(
                      authProvider.currentUser?.name.substring(0, 1).toUpperCase() ??
                          'A',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              authProvider.currentUser?.name ?? 'Kullanıcı',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Email
            Text(
              authProvider.currentUser?.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Profile Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profil Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      'Cinsiyet',
                      authProvider.currentUser?.gender ?? '-',
                    ),
                    _buildInfoRow(
                      'Doğum Tarihi',
                      authProvider.currentUser?.birthDate != null
                          ? AppUtils.formatDate(authProvider.currentUser!.birthDate)
                          : '-',
                    ),
                    _buildInfoRow(
                      'Yaş',
                      authProvider.currentUser?.birthDate != null
                          ? AppUtils.formatAge(authProvider.currentUser!.birthDate)
                          : '-',
                    ),
                    _buildInfoRow(
                      'Bio',
                      authProvider.currentUser?.bio ?? '-',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ayarlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      'Max Mesafe',
                      '${authProvider.currentUser?.settings.maxDistance ?? 50} km',
                    ),
                    _buildInfoRow(
                      'Yaş Aralığı',
                      '${authProvider.currentUser?.settings.minAge ?? 18} - ${authProvider.currentUser?.settings.maxAge ?? 50}',
                    ),
                    _buildInfoRow(
                      'Bildirimler',
                      authProvider.currentUser?.settings.notificationsEnabled == true
                          ? 'Açık'
                          : 'Kapalı',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
                child: const Text('Profili Düzenle'),
              ),
            ),
            const SizedBox(height: 32),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'Sürüm ${snapshot.data!.version}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
