import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/tool_helper.dart';
import 'worker_service.dart';

WorkerService getWorkerService() => IoWorkerService();

class IoWorkerService implements WorkerService {
  @override
  Future<String> getWorkerPath() async {
    return ToolHelper.getWorkerPath();
  }

  @override
  Future<bool> checkFolderExists() async {
    final path = await getWorkerPath();
    return Directory(path).exists();
  }

  @override
  Future<bool> pingLocalhost(String url) async {
    try {
      final uri = Uri.parse('$url/status');
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(milliseconds: 1500);
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> launchHiddenWorker() async {
    final workerDir = await getWorkerPath();
    final tempDir = await getTemporaryDirectory();
    final vbsPath = '${tempDir.path}\\start_hidden_worker.vbs';

    // Deteksi mode: production menggunakan compiled JS, dev menggunakan tsx
    final hasDistFile = await File('$workerDir\\dist\\main.js').exists();
    final hasSrcFile = await File('$workerDir\\src\\main.ts').exists();

    String runCommand;
    if (hasDistFile && !hasSrcFile) {
      // Production (installed via Inno Setup) — src/ tidak dikopikan, hanya dist/
      runCommand = 'node dist/main.js';
      debugPrint('[Worker] Mode: PRODUCTION (node dist/main.js)');
    } else {
      // Development (IDE) — src/ tersedia
      runCommand = 'npm run start';
      debugPrint('[Worker] Mode: DEVELOPMENT (npm run start)');
    }

    final lines = <String>[
      'Set objShell = CreateObject("WScript.Shell")',
      'objShell.Run "cmd /c cd /d ""$workerDir"" && $runCommand", 0, False',
    ];
    await File(vbsPath).writeAsString(lines.join('\r\n'));
    debugPrint('[Worker] VBS content: ${lines.join(' | ')}');
    debugPrint('[Worker] VBS path: $vbsPath');

    await Process.start(
      'wscript.exe',
      [vbsPath],
      mode: ProcessStartMode.detached,
    );
  }

  @override
  Future<Map<String, dynamic>?> triggerSync(String url) async {
    try {
      final uri = Uri.parse('$url/sync');
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 15);
      final request = await httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> shutdownWorker(String url) async {
    try {
      final uri = Uri.parse('$url/shutdown');
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 10);
      final request = await httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
