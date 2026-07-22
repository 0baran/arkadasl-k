import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
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
      builder: (ctx) => _UpdateDialog(version: version, apkUrl: apkUrl, releaseNotes: releaseNotes, onSkip: () => _setSkippedVersion(version)),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String apkUrl;
  final String releaseNotes;
  final VoidCallback onSkip;

  const _UpdateDialog({required this.version, required this.apkUrl, required this.releaseNotes, required this.onSkip});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _status = '';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _status = 'İndiriliyor...';
    });

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/Arkadaslik_v${widget.version}.apk';
      
      final request = http.Request('GET', Uri.parse(widget.apkUrl));
      final response = await http.Client().send(request);
      
      final contentLength = response.contentLength ?? 1;
      int downloaded = 0;
      
      final file = File(savePath);
      final sink = file.openWrite();
      
      await response.stream.listen((List<int> chunk) {
        downloaded += chunk.length;
        setState(() {
          _progress = downloaded / contentLength;
        });
        sink.add(chunk);
      }).asFuture();
      
      await sink.close();
      
      setState(() {
        _status = 'Kurulum başlatılıyor...';
      });
      
      await OpenFilex.open(savePath);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _status = 'İndirme başarısız oldu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          Text('Sürüm ${widget.version} yayınlandı.', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (!_isDownloading)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.releaseNotes.isNotEmpty ? widget.releaseNotes : "Hata düzeltmeleri ve performans iyileştirmeleri.",
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          if (_isDownloading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: _progress, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                const SizedBox(height: 8),
                Text(_status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('%${(_progress * 100).toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () {
              widget.onSkip();
              Navigator.pop(context);
            },
            child: const Text('Daha Sonra', style: TextStyle(color: Colors.grey)),
          ),
        if (!_isDownloading)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _startDownload,
            child: const Text('Şimdi İndir ve Kur', style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}
