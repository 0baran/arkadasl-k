import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class UpdateService {
  static const String githubRepo = "0baran/arkadasl-k"; 
  static const String _skippedKey = "update_skipped_version";
  
  static String get _apiUrl => "https://raw.githubusercontent.com/$githubRepo/main/version.json";

  static Future<String?> _getSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_skippedKey);
  }

  static Future<void> _setSkippedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedKey, version);
  }

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      if (githubRepo == "Sahip/RepoAdi") {
        debugPrint("UpdateService: GitHub repo adi girilmedigi icin guncelleme kontrolu atlandi.");
        return; 
      }

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(_apiUrl));
      request.headers.set('Cache-Control', 'no-cache');
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        
        final latestVersion = data['version']?.toString() ?? '';
        final apkUrl = data['apk_url']?.toString();
        final releaseNotes = data['release_notes']?.toString() ?? '';

        // Ayni surum icin daha once "Daha Sonra" dendiyse tekrar gosterme
        final skipped = await _getSkippedVersion();
        if (skipped == latestVersion) return;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isUpdateAvailable(currentVersion, latestVersion) && apkUrl != null) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, apkUrl, releaseNotes);
          }
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static bool _isUpdateAvailable(String current, String latest) {
    try {
      final v1 = current.split('.').map(int.parse).toList();
      final v2 = latest.split('.').map(int.parse).toList();
      
      for (var i = 0; i < 3; i++) {
        final num1 = i < v1.length ? v1[i] : 0;
        final num2 = i < v2.length ? v2[i] : 0;
        if (num2 > num1) return true;
        if (num2 < num1) return false;
      }
    } catch (_) {}
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String apkUrl, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Yeni Guncelleme!', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Surum $version yayinlandi.', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                releaseNotes.isNotEmpty ? releaseNotes : "Hata duzeltmeleri ve performans iyilestirmeleri.",
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _setSkippedVersion(version);
              Navigator.pop(ctx);
            },
            child: const Text('Daha Sonra', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showDownloadInstructions(context, version, apkUrl);
            },
            child: const Text('Nasil Indirilir?'),
          ),
        ],
      ),
    );
  }

  static void _showDownloadInstructions(BuildContext context, String version, String apkUrl) {
    final releaseUrl = "https://github.com/0baran/arkadasl-k/releases/tag/v$version";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Guncelleme Adimlari'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Asagidaki linki kopyalayin'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                releaseUrl,
                style: const TextStyle(fontSize: 11, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            const Text('2. Telefonunuzun tarayicisinda acin'),
            const SizedBox(height: 8),
            const Text('3. APK dosyasina tiklayip indirin'),
            const SizedBox(height: 8),
            const Text('4. Indirilen APKyi acip kurun'),
            const SizedBox(height: 8),
            const Text('Mevcut hesabiniz korunur, tekrar giris yapmaniz gerekmez.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
