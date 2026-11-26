import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/driver/models/driver_passenger.dart';
import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

/// Shared US-17 dialog displaying trip attendance summary metrics,
/// per-student statuses, and CSV clipboard export.
Future<void> showAttendanceReportDialog(
  BuildContext context, {
  required String routeName,
  required List<DriverPassenger> passengers,
}) {
  final total = passengers.length;
  final boarded = passengers.where((p) => p.status == PassengerBoardingStatus.boarded).length;
  final absent = passengers.where((p) => p.status == PassengerBoardingStatus.absent).length;
  final pending = passengers.where((p) => p.status == PassengerBoardingStatus.pending).length;
  final attendancePct = total == 0 ? 0 : ((boarded / total) * 100).round();

  String statusLabel(PassengerBoardingStatus status) {
    switch (status) {
      case PassengerBoardingStatus.boarded:
        return AppStrings.tr('driver_status_boarded');
      case PassengerBoardingStatus.absent:
        return AppStrings.tr('driver_status_absent');
      case PassengerBoardingStatus.pending:
        return AppStrings.tr('driver_status_pending');
    }
  }

  Color statusColor(PassengerBoardingStatus status) {
    switch (status) {
      case PassengerBoardingStatus.boarded:
        return const Color(0xFF047857);
      case PassengerBoardingStatus.absent:
        return AppTheme.errorColor;
      case PassengerBoardingStatus.pending:
        return Colors.grey.shade700;
    }
  }

  String escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String buildCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Route,Student,Grade,Stop,ScheduledTime,Status');
    for (final p in passengers) {
      buffer.writeln(
        [
          escapeCsv(routeName),
          escapeCsv(p.name),
          escapeCsv(p.grade),
          escapeCsv(p.stopAddress),
          escapeCsv(p.scheduledTime),
          escapeCsv(statusLabel(p.status)),
        ].join(','),
      );
    }
    return buffer.toString().trimRight();
  }

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.primaryNavy, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr('attendance_report_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryNavy),
                ),
                Text(
                  routeName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary metrics grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    label: AppStrings.tr('attendance_total_label'),
                    value: '$total',
                    color: AppTheme.primaryNavy,
                  ),
                  _MetricChip(
                    label: AppStrings.tr('driver_status_boarded'),
                    value: '$boarded',
                    color: const Color(0xFF10B981),
                  ),
                  _MetricChip(
                    label: AppStrings.tr('driver_status_absent'),
                    value: '$absent',
                    color: AppTheme.errorColor,
                  ),
                  _MetricChip(
                    label: AppStrings.tr('driver_status_pending'),
                    value: '$pending',
                    color: Colors.orange.shade700,
                  ),
                  _MetricChip(
                    label: AppStrings.tr('attendance_rate_label'),
                    value: '$attendancePct%',
                    color: AppTheme.primaryTeal,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...passengers.map((p) {
                final color = statusColor(p.status);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(
                              '${p.grade} · ${p.scheduledTime}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel(p.status),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppStrings.tr('common_close')),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.copy_all_outlined, size: 16),
          label: Text(
            AppStrings.tr('attendance_copy_csv_btn'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            final csv = buildCsv();
            await Clipboard.setData(ClipboardData(text: csv));
            if (ctx.mounted) {
              Navigator.pop(ctx);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.tr('attendance_csv_copied_snack')),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
