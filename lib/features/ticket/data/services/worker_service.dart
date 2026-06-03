import 'worker_service_stub.dart'
    if (dart.library.io) 'worker_service_io.dart';

abstract class WorkerService {
  factory WorkerService() => getWorkerService();

  Future<bool> checkFolderExists();
  Future<bool> pingLocalhost(String url);
  Future<void> launchHiddenWorker();
  Future<String> getWorkerPath();
  Future<Map<String, dynamic>?> triggerSync(String url);
  Future<Map<String, dynamic>?> shutdownWorker(String url);
}
