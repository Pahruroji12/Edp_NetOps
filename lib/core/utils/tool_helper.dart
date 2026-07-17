import 'package:edp_netops/core/platform/native_io.dart';
import 'package:flutter/foundation.dart';

/// ToolHelper — Utilitas sentral untuk mencari path program pendukung secara dinamis.
///
/// Tanggung Jawab:
///   - Menghilangkan hardcoded path legacy (D:\Edp NetOps) di seluruh halaman/kontroler.
///   - Mendukung instalasi modern di C:\Program Files\ (Inno Setup) dengan mendeteksi
///     lokasi relatif dari file executable utama (resolvedExecutable).
class ToolHelper {
  ToolHelper._();

  /// Mendapatkan path folder executables utama (lokasi edp_netops.exe berada)
  static String getAppDirectory() {
    try {
      final exeFile = File(Platform.resolvedExecutable);
      return exeFile.parent.path;
    } catch (e) {
      debugPrint('[ToolHelper] Gagal mengambil resolvedExecutable: $e');
      return '';
    }
  }

  /// Menemukan path Winbox secara dinamis (prioritas lokal installer -> legacy path)
  static Future<String> getWinboxPath() async {
    final appDir = getAppDirectory();
    if (appDir.isNotEmpty) {
      // 1. Cek folder installer standar (appDir\tools\winbox.exe)
      final localToolsPath = File('$appDir\\tools\\winbox.exe');
      if (await localToolsPath.exists()) {
        return localToolsPath.path;
      }
      // 2. Cek folder lokal tanpa folder tools (appDir\winbox.exe)
      final localPath = File('$appDir\\winbox.exe');
      if (await localPath.exists()) {
        return localPath.path;
      }
    }

    // 3. Cek legacy paths di D:\
    final defaultToolsPath = File(r'D:\Edp NetOps\tools\winbox.exe');
    if (await defaultToolsPath.exists()) {
      return defaultToolsPath.path;
    }

    final defaultProdPath = File(r'D:\Edp NetOps\winbox.exe');
    if (await defaultProdPath.exists()) {
      return defaultProdPath.path;
    }

    // Default fallback jika tidak ada yang ditemukan
    return r'D:\Edp NetOps\winbox.exe';
  }

  /// Menemukan path VNC Viewer secara dinamis (prioritas lokal installer -> legacy path)
  static Future<String> getVncPath() async {
    final appDir = getAppDirectory();
    if (appDir.isNotEmpty) {
      // 1. Cek folder installer standar (appDir\tools\vncviewer.exe)
      final localToolsPath = File('$appDir\\tools\\vncviewer.exe');
      if (await localToolsPath.exists()) {
        return localToolsPath.path;
      }
      // 2. Cek folder lokal tanpa folder tools (appDir\vncviewer.exe)
      final localPath = File('$appDir\\vncviewer.exe');
      if (await localPath.exists()) {
        return localPath.path;
      }
    }

    // 3. Cek legacy paths di D:\
    final defaultToolsPath = File(r'D:\Edp NetOps\tools\vncviewer.exe');
    if (await defaultToolsPath.exists()) {
      return defaultToolsPath.path;
    }

    final defaultProdPath = File(r'D:\Edp NetOps\vncviewer.exe');
    if (await defaultProdPath.exists()) {
      return defaultProdPath.path;
    }

    // Default fallback jika tidak ada yang ditemukan
    return r'D:\Edp NetOps\vncviewer.exe';
  }

  /// Menemukan path Background Worker secara dinamis (prioritas lokal installer -> legacy -> dev)
  static Future<String> getWorkerPath() async {
    final appDir = getAppDirectory();
    if (appDir.isNotEmpty) {
      // 1. Cek folder worker versi installer (appDir\worker)
      final localWorker = Directory('$appDir\\worker');
      if (await localWorker.exists()) {
        return localWorker.path;
      }
      // 2. Cek folder worker-ticket-sync versi installer (appDir\worker-ticket-sync)
      final localWorkerSync = Directory('$appDir\\worker-ticket-sync');
      if (await localWorkerSync.exists()) {
        return localWorkerSync.path;
      }
    }

    // 3. Cek default legacy path di D:\
    final defaultProd = Directory(r'D:\Edp NetOps\worker-ticket-sync');
    if (await defaultProd.exists()) {
      return defaultProd.path;
    }
    
    final defaultProdShort = Directory(r'D:\Edp NetOps\worker');
    if (await defaultProdShort.exists()) {
      return defaultProdShort.path;
    }

    // 4. Cek path pengembangan (development)
    final devPath = Directory(r'd:\DartProject\edp_netops\worker-ticket-sync');
    if (await devPath.exists()) {
      return devPath.path;
    }

    // Fallback default
    return r'D:\Edp NetOps\worker-ticket-sync';
  }

  /// Menemukan path sla_scraper.exe secara dinamis (prioritas lokal installer -> dev/dist -> legacy path)
  static Future<String> getSlaScraperPath() async {
    final appDir = getAppDirectory();
    if (appDir.isNotEmpty) {
      // 1. Cek folder installer standar (appDir\tools\sla_scraper.exe)
      final localToolsPath = File('$appDir\\tools\\sla_scraper.exe');
      if (await localToolsPath.exists()) {
        return localToolsPath.path;
      }
      // 2. Cek folder lokal tanpa folder tools (appDir\sla_scraper.exe)
      final localPath = File('$appDir\\sla_scraper.exe');
      if (await localPath.exists()) {
        return localPath.path;
      }
    }

    // 3. Cek development output path
    final devDistPath = File(r'D:\DartProject\edp_netops\dist\sla_scraper.exe');
    if (await devDistPath.exists()) {
      return devDistPath.path;
    }

    // 4. Cek default legacy path di D:\
    final defaultToolsPath = File(r'D:\Edp NetOps\tools\sla_scraper.exe');
    if (await defaultToolsPath.exists()) {
      return defaultToolsPath.path;
    }

    final defaultProdPath = File(r'D:\Edp NetOps\sla_scraper.exe');
    if (await defaultProdPath.exists()) {
      return defaultProdPath.path;
    }

    // Default fallback jika tidak ada yang ditemukan
    return r'D:\Edp NetOps\tools\sla_scraper.exe';
  }
}
