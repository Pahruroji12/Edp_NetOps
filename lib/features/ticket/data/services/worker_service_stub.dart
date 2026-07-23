import 'worker_service.dart';

WorkerService getWorkerService() => StubWorkerService();

class StubWorkerService implements WorkerService {
  @override
  Future<bool> pingLocalhost(String url) async => false;

  @override
  Future<Map<String, dynamic>?> triggerSync(String url) async => null;
}
