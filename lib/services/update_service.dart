import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme.dart';

class UpdateService {
  static const String githubRepo = "0baran/arkadasl-k"; 
  
  static String get _apiUrl => "https://raw.githubusercontent.com/$githubRepo/main/version.json";
  
  static String? _skippedVersion;
  static bool _isDownloading = false;

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
        if (_skippedVersion == latestVersion) return;

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

  static Future<void> _downloadAndInstall(String apkUrl, BuildContext context) async {
    if (_isDownloading) return;
    _isDownloading = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('APK indiriliyor...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final response = await http.get(Uri.parse(apkUrl));
      if (response.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Indirme hatasi: HTTP ${response.statusCode}')),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/arkadaslik_update.apk');
      await file.writeAsBytes(response.bodyBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APK indirildi, kurulum baslatiliyor...')),
        );
      }

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kurulum baslatilamadi: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Indirme hatasi: $e')),
        );
      }
    } finally {
      _isDownloading = false;
    }
  }

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
            const Text('Yeni Guncelleme!', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Surum $version yayinlandi. Hemen indirmek ister misiniz?', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _skippedVersion = version;
              Navigator.pop(context);
            },
            child: const Text('Daha Sonra', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(apkUrl, context);
            },
            child: const Text('Simdi Guncelle'),
          ),
        ],
      ),
    );
  }
}
