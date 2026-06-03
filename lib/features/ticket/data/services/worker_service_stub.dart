import 'worker_service.dart';

WorkerService getWorkerService() => StubWorkerService();

class StubWorkerService implements WorkerService {
  @override
  Future<bool> checkFolderExists() async => false;

  @override
  Future<bool> pingLocalhost(String url) async => false;

  @override
  Future<void> launchHiddenWorker() async {}

  @override
  Future<String> getWorkerPath() async => '';

  @override
  Future<Map<String, dynamic>?> triggerSync(String url) async => null;

  @override
  Future<Map<String, dynamic>?> shutdownWorker(String url) async => null;
}
