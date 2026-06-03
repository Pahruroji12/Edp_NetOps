import '../ticket_model.dart';
import '../ticket_ranking_result.dart';

class TicketRankingCalculator {
  /// Calculates the ranking of stores based on incident frequency
  static List<StoreRanking> calculateRanking(List<TicketModel> data) {
    final map = <String, Map<String, dynamic>>{};
    for (final t in data) {
      map.putIfAbsent(
        t.storeCode,
        () => {
          'store_code': t.storeCode,
          'store_name': t.storeName,
          'total': 0,
          'open': 0,
          'in_progress': 0,
          'resolved': 0,
          'last_incident': null,
          'tickets': <TicketModel>[],
        },
      );
      map[t.storeCode]!['total'] = (map[t.storeCode]!['total'] as int) + 1;

      // Track last incident
      final currentLast = map[t.storeCode]!['last_incident'] as DateTime?;
      if (t.createdAt != null &&
          (currentLast == null || t.createdAt!.isAfter(currentLast))) {
        map[t.storeCode]!['last_incident'] = t.createdAt;
      }

      // Collect tickets for expandable detail
      (map[t.storeCode]!['tickets'] as List<TicketModel>).add(t);

      switch (t.status) {
        case 'Open':
          map[t.storeCode]!['open'] = (map[t.storeCode]!['open'] as int) + 1;
          break;
        case 'In Progress':
          map[t.storeCode]!['in_progress'] =
              (map[t.storeCode]!['in_progress'] as int) + 1;
          break;
        case 'Resolved':
          map[t.storeCode]!['resolved'] =
              (map[t.storeCode]!['resolved'] as int) + 1;
          break;
      }
    }

    final rankings = map.values.map((v) {
      final total = v['total'] as int;
      final open = v['open'] as int;
      return StoreRanking(
        storeCode: v['store_code'] as String,
        storeName: v['store_name'] as String,
        total: total,
        open: open,
        inProgress: v['in_progress'] as int,
        resolved: v['resolved'] as int,
        lastIncident: v['last_incident'] as DateTime?,
        tickets: v['tickets'] as List<TicketModel>,
        severity: calculateSeverity(total, open),
      );
    }).toList();

    // Sort by total incidents descending
    rankings.sort((a, b) => b.total.compareTo(a.total));
    return rankings;
  }

  /// Calculates severity level based on ticket thresholds
  static SeverityLevel calculateSeverity(int total, int open) {
    if (open >= 3 || total >= 5) return SeverityLevel.critical;
    if (open >= 1 || total >= 3) return SeverityLevel.warning;
    return SeverityLevel.stable;
  }
}
