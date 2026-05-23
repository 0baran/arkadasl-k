// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

class UpdateService {
  static const String githubRepo = "0baran/arkadasl-k"; 
  
  static String get _apiUrl => "https://raw.githubusercontent.com/$githubRepo/main/version.json";
  
  static bool _isChecked = false;

  static Future<void> checkForUpdates(BuildContext context) async {
    if (_isChecked) return;
    _isChecked = true;
    
    try {
      if (githubRepo == "Sahip/RepoAdi") {
        debugPrint("UpdateService: GitHub repo adı girilmediği için güncelleme kontrolü atlandı.");
        return; 
      }

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(_apiUrl));
      // Cache'i bypass etmek için query parametresi eklenebilir veya headers eklenebilir
      request.headers.set('Cache-Control', 'no-cache');
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        
        final latestVersion = data['version']?.toString() ?? '';
        final apkUrl = data['apk_url']?.toString();
        final releaseNotes = data['release_notes']?.toString() ?? '';

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

  // _extractApkUrl is no longer needed


  static void _showUpdateDialog(BuildContext context, String version, String apkUrl, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Yeni Güncelleme!', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sürüm $version yayınlandı. Hemen indirmek ister misiniz?', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                releaseNotes.isNotEmpty ? releaseNotes : "Hata düzeltmeleri ve performans iyileştirmeleri.", 
                maxLines: 4, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final uri = Uri.parse(apkUrl);
              bool launched = false;
              for (final mode in [LaunchMode.externalApplication, LaunchMode.platformDefault, LaunchMode.inAppWebView]) {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: mode);
                  launched = true;
                  break;
                }
              }
              if (!launched && context.mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Baglanti Acilamadi'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Asagidaki linki kopyalayip tarayicinizda acin:'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(apkUrl, style: const TextStyle(fontSize: 11)),
                        ),
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
            },
            child: const Text('Şimdi Güncelle'),
          ),
        ],
      ),
    );
  }
}
