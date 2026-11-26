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
  final String status; // 'COMPLETED' | 'CANCELLED'
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

  bool get isCancelled => status.toUpperCase() == 'CANCELLED' || status.toUpperCase() == 'CANCELADO';

  factory TripHistoryRecord.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? json['Status'] ?? 'COMPLETED').toString().toUpperCase();
    final dateStr = (json['date'] ?? json['startedAt'] ?? json['scheduledDate'] ?? 'Hoy, 07:50 AM').toString();

    return TripHistoryRecord(
      tripId: (json['id'] ?? json['tripId'] ?? json['TripId'] ?? 'TRP-HIST').toString(),
      routeName: (json['routeName'] ?? json['RouteName'] ?? 'Ruta Escolar 02').toString(),
      driverName: (json['driverName'] ?? json['DriverName'] ?? 'Carlos Ramírez').toString(),
      vehiclePlate: (json['vehiclePlate'] ?? json['VehiclePlate'] ?? 'ABC-789').toString(),
      dateEs: json['dateEs']?.toString() ?? dateStr,
      dateEn: json['dateEn']?.toString() ?? dateStr,
      boardedCount: (json['boardedCount'] ?? json['onboardStudents'] ?? 12) as int,
      totalStudents: (json['totalStudents'] ?? json['totalChildren'] ?? 14) as int,
      status: rawStatus == 'CANCELLED' || rawStatus == 'CANCELADO' ? 'CANCELLED' : 'COMPLETED',
      rating: json['rating'] is int ? json['rating'] as int : null,
      ratingComment: json['ratingComment']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
    );
  }
}
