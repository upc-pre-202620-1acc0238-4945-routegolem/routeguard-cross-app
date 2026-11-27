import '../../../core/localization/app_strings.dart';

class TripHistoryRecord {
  final String tripId;
  final String routeName;
  final String driverName;
  final String vehiclePlate;
  final String dateEs;
  final String dateEn;
  final int boardedCount;
  final int totalStudents;
  final String status; // 'COMPLETED' | 'CANCELLED' | 'IN_PROGRESS' | 'PENDING'
  int? rating;
  String? ratingComment;
  final String? cancellationReason;

  TripHistoryRecord({
    required this.tripId,
    required this.routeName,
    required this.driverName,
    required this.vehiclePlate,
    required this.dateEs,
    required this.dateEn,
    required this.boardedCount,
    required this.totalStudents,
    required this.status,
    this.rating,
    this.ratingComment,
    this.cancellationReason,
  });

  String get localizedDate => AppStrings.isSpanish ? dateEs : dateEn;

  String get normalizedStatus => status.trim().toUpperCase();
  bool get isCancelled => normalizedStatus == 'CANCELLED' || normalizedStatus == 'CANCELADO';
  bool get isInProgress => normalizedStatus == 'IN_PROGRESS' || normalizedStatus == 'EN_RUTA';
  bool get isPending => normalizedStatus == 'PENDING' || normalizedStatus == 'PENDIENTE';
  bool get isCompleted => !isCancelled && !isInProgress && !isPending;

  static String _formatIsoDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '--:--';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} · $hh:$min';
  }

  static String _normalizeStatus(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'CANCELLED' || upper == 'CANCELADO') return 'CANCELLED';
    if (upper == 'IN_PROGRESS' || upper == 'EN_RUTA') return 'IN_PROGRESS';
    if (upper == 'PENDING' || upper == 'PENDIENTE') return 'PENDING';
    return 'COMPLETED';
  }

  factory TripHistoryRecord.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? json['Status'] ?? 'COMPLETED').toString();
    final explicitEs = json['dateEs']?.toString();
    final explicitEn = json['dateEn']?.toString();
    final rawBackendDate = (json['endTime'] ??
            json['startTime'] ??
            json['date'] ??
            json['startedAt'] ??
            json['scheduledDate'])
        ?.toString();
    final formatted = rawBackendDate != null ? _formatIsoDate(rawBackendDate) : '--:--';

    final rawRating = json['myRating'] ?? json['rating'];

    return TripHistoryRecord(
      tripId: (json['id'] ?? json['tripId'] ?? json['TripId'] ?? 'TRP-HIST').toString(),
      routeName: (json['routeName'] ?? json['RouteName'] ?? 'Ruta Escolar').toString(),
      driverName: (json['driverName'] ?? json['DriverName'] ?? 'Conductor').toString(),
      vehiclePlate: (json['vehiclePlate'] ?? json['VehiclePlate'] ?? 'ABC-123').toString(),
      dateEs: explicitEs ?? formatted,
      dateEn: explicitEn ?? formatted,
      boardedCount: (json['boardedCount'] ?? json['onboardStudents'] ?? 0) as int,
      totalStudents: (json['totalStudents'] ?? json['totalChildren'] ?? 0) as int,
      status: _normalizeStatus(rawStatus),
      rating: rawRating is num ? rawRating.toInt() : null,
      ratingComment: json['ratingComment']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
    );
  }
}
