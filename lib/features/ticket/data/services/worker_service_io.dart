import 'dart:io';
import 'dart:convert';
import 'worker_service.dart';

WorkerService getWorkerService() => IoWorkerService();

class IoWorkerService implements WorkerService {
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
}
