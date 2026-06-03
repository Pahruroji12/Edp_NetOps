import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/platform/feature_availability.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../auth/domain/auth_state.dart';
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
  bool isHostMachine = false;

  static Completer<void>? _autoStartCompleter;

  Future<void> fetchWorkerStatus() async {
    isWorkerLoading = true;
    notifyListeners();

    if (_autoStartCompleter != null && !_autoStartCompleter!.isCompleted) {
      debugPrint('[Worker Status] Waiting for auto-start to finish booting...');
      await _autoStartCompleter!.future;
    }

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

      // 2. Ambil URL API worker untuk dicek keaktifannya secara langsung
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

      // 3. Deteksi peran komputer ini: HOST (Komputer Utama) atau CLIENT (Komputer Lain)
      isHostMachine = await _service.checkFolderExists();
      final bool isLocalhostUrl =
          workerUrl.contains('localhost') || workerUrl.contains('127.0.0.1');

      // 4. Ping endpoint /status untuk memastikan proses worker benar-benar hidup secara fisik
      isWorkerApiReachable = false;
      if (!kIsWeb) {
        if (isHostMachine || !isLocalhostUrl) {
          isWorkerApiReachable = await _service.pingLocalhost(workerUrl);
        } else {
          isWorkerApiReachable = true;
        }
      }

      // 5. Override status Supabase ke 'unknown' (offline) jika host mendeteksi local api mati,
      // atau jika client mendeteksi remote IP worker mati.
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
          'Gagal menghubungi Background Worker. Pastikan service Deno aktif.',
        );
      }
    } catch (e) {
      debugPrint('[Worker Trigger Error] $e');
      CustomSnackBar.error(
        'Gagal menghubungi Background Worker. Pastikan service Deno aktif.',
      );
    } finally {
      isSyncingWorker = false;
      notifyListeners();
    }
  }

  Future<void> startBackgroundWorker() async {
    if (!FeatureAvailability.canUseWorkerControl) {
      CustomSnackBar.info('Menyalakan worker tidak didukung di platform ini.');
      return;
    }

    final workerDir = await _service.getWorkerPath();
    debugPrint('[Worker Manager] Starting worker at directory: $workerDir');

    if (!await _service.checkFolderExists()) {
      CustomSnackBar.error('Folder worker tidak ditemukan di: $workerDir');
      return;
    }

    try {
      await _service.launchHiddenWorker();

      debugPrint('[Worker Manager] Started hidden worker via VBS');
      CustomSnackBar.success(
        'Background Worker berhasil dijalankan di latar belakang (silent)!',
      );

      // Tunggu 4 detik agar server booting, lalu ambil statusnya
      await Future.delayed(const Duration(seconds: 4));
      await fetchWorkerStatus();
    } catch (e) {
      debugPrint('[Worker Manager Error] $e');
      CustomSnackBar.error('Gagal menyalakan worker secara otomatis: $e');
    }
  }

  static Future<void> autoStartWorkerIfNeeded() async {
    if (!FeatureAvailability.canUseWorkerControl) return;

    if (!AuthState.instance.isAdmin) {
      debugPrint(
        '[Background Worker] User is not admin/administrator. Skip worker auto-start.',
      );
      return;
    }

    _autoStartCompleter = Completer<void>();

    try {
      final client = Supabase.instance.client;

      // 1. Dapatkan URL API worker
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

      // 2. Ping endpoint status local worker
      final service = WorkerService();
      bool isRunning = await service.pingLocalhost(workerUrl);

      // 3. Jika sudah jalan, tidak perlu dijalankan ulang
      if (isRunning) {
        debugPrint(
          '[Background Worker] Worker is already running. Skip auto-start.',
        );
        _autoStartCompleter?.complete();
        return;
      }

      // 4. Jika mati, jalankan via wscript.exe
      if (!await service.checkFolderExists()) {
        final path = await service.getWorkerPath();
        debugPrint(
          '[Background Worker] Folder worker tidak ditemukan di: $path. Skip auto-start.',
        );
        _autoStartCompleter?.complete();
        return;
      }

      await service.launchHiddenWorker();

      debugPrint(
        '[Background Worker] Auto-started background worker. Waiting for boot...',
      );

      await Future.delayed(const Duration(seconds: 4));
      debugPrint(
        '[Background Worker] Boot wait complete. Worker should be ready.',
      );
    } catch (e) {
      debugPrint('[Background Worker] Error in autoStartWorkerIfNeeded: $e');
    } finally {
      if (_autoStartCompleter != null && !_autoStartCompleter!.isCompleted) {
        _autoStartCompleter!.complete();
      }
    }
  }

  Future<void> stopBackgroundWorker() async {
    if (!FeatureAvailability.canUseWorkerControl) {
      CustomSnackBar.info(
        'Menghentikan worker tidak didukung di platform ini.',
      );
      return;
    }

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

      final decoded = await _service.shutdownWorker(workerUrl);

      if (decoded != null && decoded['success'] == true) {
        CustomSnackBar.success('Worker berhasil dihentikan.');
      } else {
        CustomSnackBar.error(
          'Gagal menghentikan worker: ${decoded?['error'] ?? 'Unknown'}',
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      await fetchWorkerStatus();
    } catch (e) {
      debugPrint('[Worker Stop Error] $e');
      CustomSnackBar.error(
        'Worker tidak merespon (mungkin sudah mati). Error: $e',
      );
      await fetchWorkerStatus();
    }
  }
}
