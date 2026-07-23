import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/widgets/custom_snackbar.dart';
import '../../data/services/worker_service.dart';

class WorkerController extends ChangeNotifier {
  static final WorkerController _instance = WorkerController._internal();
  factory WorkerController() => _instance;
  WorkerController._internal();

  final _service = WorkerService();

  Map<String, dynamic>? workerStatus;
  bool isWorkerLoading = false;
  bool isSyncingWorker = false;
  bool isWorkerApiReachable = false;

  /// URL worker yang sedang digunakan (dari app_settings)
  String _workerUrl = 'http://localhost:8080';
  String get workerUrl => _workerUrl;

  Future<void> fetchWorkerStatus() async {
    isWorkerLoading = true;
    notifyListeners();

    try {
      final client = Supabase.instance.client;

      // 1. Ambil status dari database Supabase
      final res = await client
          .from('worker_status')
          .select()
          .eq('id', 'ticket-sync-worker')
          .maybeSingle();

      Map<String, dynamic>? statusMap = res != null
          ? Map<String, dynamic>.from(res)
          : null;

      // 2. Ambil URL API worker
      final rows = await client
          .from('app_settings')
          .select('key, value')
          .eq('key', 'worker_api_url')
          .maybeSingle();

      _workerUrl = 'http://localhost:8080';
      if (rows != null && rows['value'] != null) {
        _workerUrl = rows['value'].toString().trim();
      }
      if (_workerUrl.endsWith('/')) {
        _workerUrl = _workerUrl.substring(0, _workerUrl.length - 1);
      }

      // 3. Ping endpoint /status untuk cek apakah worker hidup
      isWorkerApiReachable = false;
      if (!kIsWeb) {
        isWorkerApiReachable = await _service.pingLocalhost(_workerUrl);
      }

      // 4. Override status ke 'unknown' jika API tidak merespons
      if (!isWorkerApiReachable) {
        if (statusMap == null) {
          statusMap = {'status': 'unknown'};
        } else {
          statusMap['status'] = 'unknown';
        }
      }

      workerStatus = statusMap;
    } catch (e) {
      debugPrint('Error fetching worker status: $e');
    } finally {
      isWorkerLoading = false;
      notifyListeners();
    }
  }

  Future<void> triggerWorkerSync({required AsyncCallback onLoadTickets}) async {
    if (isSyncingWorker) return;
    isSyncingWorker = true;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('app_settings')
          .select('key, value')
          .eq('key', 'worker_api_url')
          .maybeSingle();

      String workerUrl = 'http://localhost:8080';
      if (rows != null && rows['value'] != null) {
        workerUrl = rows['value'].toString().trim();
      }

      if (workerUrl.endsWith('/')) {
        workerUrl = workerUrl.substring(0, workerUrl.length - 1);
      }

      debugPrint('[Worker Trigger] Hitting sync endpoint: $workerUrl/sync');

      if (kIsWeb) {
        CustomSnackBar.info(
          'Pemicu manual worker tidak didukung langsung dari Web. Silakan trigger endpoint /sync di server.',
        );
        return;
      }

      final decoded = await _service.triggerSync(workerUrl);

      if (decoded != null) {
        if (decoded['error'] == null) {
          final count = decoded['updated_tickets_count'] ?? 0;
          CustomSnackBar.success(
            'Worker Sync Sukses! $count tiket baru disinkronisasi.',
          );
          await onLoadTickets();
          await fetchWorkerStatus();
        } else {
          final err = decoded['error'] ?? 'Terjadi kesalahan internal server';
          CustomSnackBar.error('Worker Sync Gagal: $err');
        }
      } else {
        CustomSnackBar.error(
          'Gagal menghubungi Background Worker. Pastikan worker aktif di server.',
        );
      }
    } catch (e) {
      debugPrint('[Worker Trigger Error] $e');
      CustomSnackBar.error(
        'Gagal menghubungi Background Worker. Pastikan worker aktif di server.',
      );
    } finally {
      isSyncingWorker = false;
      notifyListeners();
    }
  }
}
