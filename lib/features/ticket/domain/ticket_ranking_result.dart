import 'ticket_model.dart';

enum SeverityLevel { critical, warning, stable }

class StoreRanking {
  final String storeCode;
  final String storeName;
  final int total;
  final int open;
  final int inProgress;
  final int resolved;
  final DateTime? lastIncident;
  final List<TicketModel> tickets;
  final SeverityLevel severity;

  StoreRanking({
    required this.storeCode,
    required this.storeName,
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
    this.lastIncident,
    required this.tickets,
    required this.severity,
  });

  /// Operator [] overloading for map-like backward compatibility
  dynamic operator [](String key) {
    switch (key) {
      case 'store_code':
        return storeCode;
      case 'store_name':
        return storeName;
      case 'total':
        return total;
      case 'open':
        return open;
      case 'in_progress':
        return inProgress;
      case 'resolved':
        return resolved;
      case 'last_incident':
        return lastIncident;
      case 'tickets':
        return tickets;
      case 'severity':
        return severity;
      default:
        return null;
    }
  }

  /// Converts the model to a Map for legacy compatibility with UI and exports
  Map<String, dynamic> toMap() {
    return {
      'store_code': storeCode,
      'store_name': storeName,
      'total': total,
      'open': open,
      'in_progress': inProgress,
      'resolved': resolved,
      'last_incident': lastIncident,
      'tickets': tickets,
      'severity': severity,
    };
  }
}
