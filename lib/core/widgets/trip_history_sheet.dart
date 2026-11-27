import 'package:flutter/material.dart';
import '../../features/tracking/data/tracking_repository.dart';
import '../../features/tracking/models/trip_history_record.dart';
import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

/// Shared US-15 bottom sheet displaying completed/cancelled trips
/// with optional US-14 rating trigger for completed trips.
Future<void> showTripHistorySheet(
  BuildContext context, {
  required TrackingRepository repository,
  required String token,
  bool allowRating = false,
  void Function(TripHistoryRecord record, int stars, String comment)? onRateTrip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _TripHistorySheetContent(
      repository: repository,
      token: token,
      allowRating: allowRating,
      onRateTrip: onRateTrip,
    ),
  );
}

class _TripHistorySheetContent extends StatefulWidget {
  final TrackingRepository repository;
  final String token;
  final bool allowRating;
  final void Function(TripHistoryRecord record, int stars, String comment)? onRateTrip;

  const _TripHistorySheetContent({
    required this.repository,
    required this.token,
    required this.allowRating,
    this.onRateTrip,
  });

  @override
  State<_TripHistorySheetContent> createState() => _TripHistorySheetContentState();
}

class _TripHistorySheetContentState extends State<_TripHistorySheetContent> {
  late Future<List<TripHistoryRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getTripHistory(widget.token);
  }

  Future<void> _openInlineRateDialog(TripHistoryRecord record) async {
    int selectedStars = record.rating ?? 5;
    final commentCtrl = TextEditingController(text: record.ratingComment ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              AppStrings.tr('rate_service_dialog_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryNavy),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  record.routeName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber.shade600,
                        size: 32,
                      ),
                      tooltip: '$star',
                      onPressed: () => setDialogState(() => selectedStars = star),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('rate_service_comment_label'),
                    hintText: AppStrings.tr('rate_service_comment_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(AppStrings.tr('common_cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                ),
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(AppStrings.tr('rate_service_submit_btn')),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      final comment = commentCtrl.text.trim();
      await widget.repository.submitServiceRating(
        tripId: record.tripId,
        stars: selectedStars,
        comment: comment,
        token: widget.token,
      );
      setState(() {
        record.rating = selectedStars;
        record.ratingComment = comment;
      });
      widget.onRateTrip?.call(record, selectedStars, comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.trf('rate_service_saved_snack', {'stars': selectedStars})),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
    commentCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppTheme.primaryNavy),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.tr('trip_history_sheet_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryNavy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: FutureBuilder<List<TripHistoryRecord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final records = snapshot.data ?? const [];
                    if (records.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(AppStrings.tr('trip_history_empty'), style: const TextStyle(color: Colors.grey)),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final cancelled = record.isCancelled;
                        final inProgress = record.isInProgress;
                        final pending = record.isPending;
                        final Color statusColor;
                        final Color statusBg;
                        final String statusLabel;
                        if (cancelled) {
                          statusColor = AppTheme.errorColor;
                          statusBg = AppTheme.errorContainer;
                          statusLabel = AppStrings.tr('trip_history_status_cancelled');
                        } else if (inProgress) {
                          statusColor = AppTheme.primaryNavy;
                          statusBg = AppTheme.primaryNavy.withValues(alpha: 0.12);
                          statusLabel = AppStrings.tr('trip_history_status_in_progress');
                        } else if (pending) {
                          statusColor = Colors.orange.shade900;
                          statusBg = Colors.orange.shade100;
                          statusLabel = AppStrings.tr('trip_history_status_pending');
                        } else {
                          statusColor = const Color(0xFF047857);
                          statusBg = const Color(0xFF10B981).withValues(alpha: 0.14);
                          statusLabel = AppStrings.tr('trip_history_status_completed');
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      record.routeName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${record.localizedDate} · ${record.driverName} (${record.vehiclePlate})',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppStrings.trf('trip_history_boarded_summary', {
                                        'boarded': record.boardedCount,
                                        'total': record.totalStudents,
                                      }),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  if (widget.allowRating && !cancelled) ...[
                                    const SizedBox(width: 8),
                                    record.rating != null
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.amber.shade300),
                                            ),
                                            child: Text(
                                              '★ ${record.rating}/5',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          )
                                        : TextButton.icon(
                                            onPressed: () => _openInlineRateDialog(record),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            icon: Icon(Icons.star_outline, size: 15, color: Colors.amber.shade800),
                                            label: Text(
                                              AppStrings.tr('trip_history_rate_btn'),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
