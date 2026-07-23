import 'worker_service_stub.dart'
    if (dart.library.io) 'worker_service_io.dart';

abstract class WorkerService {
  factory WorkerService() => getWorkerService();

  Future<bool> pingLocalhost(String url);
  Future<Map<String, dynamic>?> triggerSync(String url);
}
