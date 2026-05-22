// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _maxDistance = 50.0;
  int _minAge = 18;
  int _maxAge = 50;
  String _preferredGender = 'all';
  bool _notificationsEnabled = true;
  bool _showDistance = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settings = authProvider.currentUser?.settings;

    if (settings != null) {
      setState(() {
        _maxDistance = settings.maxDistance;
        _minAge = settings.minAge;
        _maxAge = settings.maxAge;
        _preferredGender = settings.preferredGender;
        _notificationsEnabled = settings.notificationsEnabled;
        _showDistance = settings.showDistance;
      });
    }
  }

  Future<void> _saveSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        settings: currentUser.settings.copyWith(
          maxDistance: _maxDistance,
          minAge: _minAge,
          maxAge: _maxAge,
          preferredGender: _preferredGender,
          notificationsEnabled: _notificationsEnabled,
          showDistance: _showDistance,
        ),
      );

      await authProvider.updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar kaydedildi!')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Discovery Settings
            _buildSectionTitle('Keşfet Ayarları'),

            // Max Distance
            _buildSettingCard(
              icon: Icons.location_on,
              title: 'Max Mesafe',
              subtitle: '${_maxDistance.toStringAsFixed(0)} km',
              child: Slider(
                value: _maxDistance,
                min: AppConstants.minDistance,
                max: AppConstants.maxDistance,
                divisions: 99,
                label: '${_maxDistance.toStringAsFixed(0)} km',
                onChanged: (value) {
                  setState(() {
                    _maxDistance = value;
                  });
                },
              ),
            ),

            // Age Range
            _buildSettingCard(
              icon: Icons.calendar_today,
              title: 'Yaş Aralığı',
              subtitle: '$_minAge - $_maxAge',
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Min:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _minAge.toDouble(),
                          min: AppConstants.minAge.toDouble(),
                          max: _maxAge.toDouble(),
                          divisions: (_maxAge - AppConstants.minAge),
                          label: _minAge.toString(),
                          onChanged: (value) {
                            setState(() {
                              _minAge = value.toInt();
                            });
                          },
                        ),
                      ),
                      Text(_minAge.toString()),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Max:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _maxAge.toDouble(),
                          min: _minAge.toDouble(),
                          max: AppConstants.maxAge.toDouble(),
                          divisions: (AppConstants.maxAge - _minAge),
                          label: _maxAge.toString(),
                          onChanged: (value) {
                            setState(() {
                              _maxAge = value.toInt();
                            });
                          },
                        ),
                      ),
                      Text(_maxAge.toString()),
                    ],
                  ),
                ],
              ),
            ),

            // Preferred Gender
            _buildSettingCard(
              icon: Icons.people,
              title: 'Cinsiyet Tercihi',
              subtitle: _getGenderText(_preferredGender),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Hepsi'),
                    value: 'all',
                    groupValue: _preferredGender,
                    onChanged: (value) {
                      setState(() {
                        _preferredGender = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    title: const Text('Erkek'),
                    value: 'male',
                    groupValue: _preferredGender,
                    onChanged: (value) {
                      setState(() {
                        _preferredGender = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    title: const Text('Kadın'),
                    value: 'female',
                    groupValue: _preferredGender,
                    onChanged: (value) {
                      setState(() {
                        _preferredGender = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Settings
            _buildSectionTitle('Bildirim Ayarları'),

            _buildSettingCard(
              icon: Icons.notifications,
              title: 'Bildirimler',
              subtitle: 'Match ve mesaj bildirimleri',
              child: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Settings
            _buildSectionTitle('Gizlilik'),

            _buildSettingCard(
              icon: Icons.visibility,
              title: 'Mesafeyi Göster',
              subtitle: 'Diğer kullanıcılara mesafemi göster',
              child: Switch(
                value: _showDistance,
                onChanged: (value) {
                  setState(() {
                    _showDistance = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Ayarları Kaydet'),
              ),
            ),
            
            const SizedBox(height: 32),

            // Account Actions
            _buildSectionTitle('Hesap Yönetimi'),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showDeleteAccountDialog,
                icon: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
                label: const Text('Hesabımı Sil', style: TextStyle(color: AppTheme.errorColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Sil', style: TextStyle(color: AppTheme.errorColor)),
        content: const Text('Hesabınızı kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm eşleşme, mesaj ve profil verileriniz silinir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.deleteAccount();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesabınız başarıyla silindi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hesap silinirken hata oluştu: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      default:
        return 'Hepsi';
    }
  }
}
