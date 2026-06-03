import 'dart:convert';
import 'package:edp_netops/core/platform/native_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../constants/app_constants.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String changelog;
  final String fileName;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.changelog,
    required this.fileName,
  });
}

class AutoUpdateService {
  static const String githubUsername = 'Pahruroji12';
  static const String githubRepo = 'Edp_NetOps_Releases'; // Repositori khusus rilis publik
  static const String apiEndpoint = 'https://api.github.com/repos/$githubUsername/$githubRepo/releases/latest';

  /// Memeriksa apakah pembaruan versi baru tersedia di GitHub Releases
  static Future<UpdateInfo?> checkForUpdates() async {
    final client = HttpClient();
    // GitHub API mewajibkan User-Agent header agar tidak ditolak
    client.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) EDP-NetOps/1.0';
    
    try {
      final request = await client.getUrl(Uri.parse(apiEndpoint));
      request.headers.add('Accept', 'application/vnd.github.v3+json');
      
      final response = await request.close();
      if (response.statusCode != 200) {
        debugPrint('[Auto Update] Gagal menghubungi API GitHub (Status: ${response.statusCode})');
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(responseBody);
      
      // Ambil tag versi, misal "v2.8.0" -> bersihkan jadi "2.8.0"
      String tagVersion = data['tag_name']?.toString() ?? '';
      if (tagVersion.startsWith('v')) {
        tagVersion = tagVersion.substring(1);
      }

      final currentVersion = AppConstants.appVersion;

      if (_isNewerVersion(tagVersion, currentVersion)) {
        final assets = data['assets'] as List<dynamic>;
        if (assets.isEmpty) return null;

        // Cari file installer yang sesuai platform (Windows -> .exe, Android -> .apk)
        final bool isAndroid = Platform.isAndroid;
        final targetExtension = isAndroid ? '.apk' : '.exe';

        final targetAsset = assets.firstWhere(
          (asset) => asset['name'].toString().toLowerCase().endsWith(targetExtension),
          orElse: () => null,
        );

        if (targetAsset != null) {
          return UpdateInfo(
            latestVersion: tagVersion,
            downloadUrl: targetAsset['browser_download_url'],
            changelog: data['body'] ?? 'Tidak ada catatan rilis.',
            fileName: targetAsset['name'],
          );
        }
      }
    } catch (e) {
      debugPrint('[Auto Update Error] $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// Melakukan unduhan file installer ke direktori Temp dengan progress callback
  static Future<String> downloadUpdate({
    required String url,
    required String fileName,
    required Function(double progress) onProgress,
  }) async {
    final client = HttpClient();
    client.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) EDP-NetOps/1.0';
    
    try {
      final tempDir = await getTemporaryDirectory();
      final pathSeparator = Platform.pathSeparator;
      final savePath = '${tempDir.path}$pathSeparator$fileName';

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final contentLength = response.contentLength;
        int downloaded = 0;
        final file = File(savePath);

        // Hapus file lama di folder Temp jika ada untuk menghindari konflik penguncian
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }

        final sink = file.openWrite();
        try {
          await for (final chunk in response) {
            sink.add(chunk);
            downloaded += chunk.length;
            if (contentLength > 0) {
              onProgress(downloaded / contentLength);
            }
          }
        } finally {
          await sink.flush();
          await sink.close();
        }
        return savePath;
      } else {
        throw Exception('Gagal mengunduh file, status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Auto Update Download Error] $e');
      throw Exception('Gagal mengunduh pembaruan: $e');
    } finally {
      client.close();
    }
  }

  /// Menjalankan installer eksternal secara detached dan menutup aplikasi utama
  static Future<void> installAndExit(String savePath) async {
    try {
      if (Platform.isWindows) {
        // Jalankan installer eksternal secara detached
        await Process.start(
          savePath,
          ['/SILENT', '/SP-', '/NOCANCEL', '/SUPPRESSMSGBOXES'],
          mode: ProcessStartMode.detached,
        );

        // Tutup aplikasi utama agar installer bisa menimpa file exe yang lama
        exit(0);
      } else if (Platform.isAndroid) {
        // Membuka file APK menggunakan open_filex
        final result = await OpenFilex.open(savePath);
        if (result.type != ResultType.done) {
          throw Exception('Gagal membuka berkas APK: ${result.message}');
        }
      } else {
        throw Exception('Metode instalasi tidak didukung pada platform ini.');
      }
    } catch (e) {
      debugPrint('[Auto Update Install Error] $e');
      throw Exception('Gagal menjalankan installer: $e');
    }
  }

  /// Helper untuk membandingkan semantik versi (2.8.0 > 2.7.0)
  static bool _isNewerVersion(String latest, String current) {
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
