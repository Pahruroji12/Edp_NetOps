class WorkerStatus {
  final String status;
  final String? lastRun;
  final String? lastSuccess;
  final String? errorMessage;
  final String processedCount;

  WorkerStatus({
    required this.status,
    this.lastRun,
    this.lastSuccess,
    this.errorMessage,
    required this.processedCount,
  });

  factory WorkerStatus.fromMap(Map<String, dynamic> map) {
    return WorkerStatus(
      status: map['status']?.toString() ?? 'unknown',
      lastRun: map['last_run']?.toString(),
      lastSuccess: map['last_success']?.toString(),
      errorMessage: map['error_message']?.toString(),
      processedCount: map['processed_count']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'last_run': lastRun,
      'last_success': lastSuccess,
      'error_message': errorMessage,
      'processed_count': processedCount,
    };
  }
}
