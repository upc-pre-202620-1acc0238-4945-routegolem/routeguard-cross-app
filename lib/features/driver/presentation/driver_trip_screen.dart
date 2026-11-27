import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/platform_features_repository.dart';
import '../../../core/network/road_routing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../../../core/widgets/attendance_report_dialog.dart';
import '../../../core/widgets/platform_feature_dialogs.dart';
import '../../../core/widgets/trip_history_sheet.dart';
import '../../../core/widgets/vehicle_docs_dialog.dart';
import '../../alerts/models/safety_alert.dart';
import '../../fleet/models/route_model.dart';
import '../../tracking/data/tracking_repository.dart';
import '../../tracking/models/student_stop.dart';
import '../models/driver_passenger.dart';

enum DriverTripState { inProgress, finished, cancelled }

class DriverTripScreen extends StatefulWidget {
  final TrackingRepository? repository;

  const DriverTripScreen({super.key, this.repository});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  String _activeTripId = 'TRP-2026-08';
  String? _activeRouteId;
  String? _liveRouteName;
  String? _liveVehiclePlate;
  LatLng _busPos = const LatLng(-12.0898, -77.0055);
  double _speedKmh = 35.0;
  List<StudentStop> _stops = const [];
  List<LatLng>? _roadPath;
  List<RouteModel> _assignedRoutes = const [];
  String? _selectedStartRouteId;
  bool _awaitingTripStart = false;

  late final TrackingRepository _repository;
  final RoadRoutingService _routingService = RoadRoutingService.instance;
  final PlatformFeaturesRepository _platformRepo = PlatformFeaturesRepository();
  final List<DriverPassenger> _passengers = DriverPassenger.getInitialRoster();
  SessionManager? _session;
  Map<String, Object?>? _vehicleDocs;
  DriverTripState _tripState = DriverTripState.inProgress;
  String? _cancelReasonKey;
  String? _activeIncidentTypeKey;
  int? _activeIncidentDelayMins;

  bool get _isTripActive => _tripState == DriverTripState.inProgress;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TrackingRepository();
    _loadSessionAndDocs();
  }

  Future<void> _loadSessionAndDocs() async {
    try {
      final session = await SessionManager.create();
      final token = session.token ?? '';
      final docs = await _platformRepo.loadPrimaryVehicleDocs(token);
      DriverActiveTripResult? driverTrip;
      List<LatLng>? roadPath;
      if (token.isNotEmpty) {
        driverTrip = await _repository.getDriverActiveTrip(
          token,
          sessionManager: session,
          organizationId: session.organizationId,
          driverProfileId: session.profileId,
          userId: session.userId,
        );
        if (!driverTrip.isOfflineFallback) {
          if (driverTrip.hasActiveTrip) {
            final start = LatLng(
              driverTrip.currentLatitude ?? -12.0898,
              driverTrip.currentLongitude ?? -77.0055,
            );
            final routePts = <LatLng>[
              start,
              ...driverTrip.stops.map((s) => LatLng(s.latitude, s.longitude)),
            ];
            if (routePts.length >= 2) {
              roadPath = (await _routingService.getRoadRoute(routePts))?.path;
            }
          } else if (driverTrip.assignedRoutes.isNotEmpty) {
            final firstRoute = driverTrip.assignedRoutes.first;
            final wpPts = firstRoute.waypoints
                .map((w) => LatLng(w.latitude, w.longitude))
                .toList();
            if (wpPts.length >= 2) {
              roadPath = (await _routingService.getRoadRoute(wpPts))?.path;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _session = session;
          _vehicleDocs = docs;
          if (driverTrip != null && !driverTrip.isOfflineFallback) {
            _assignedRoutes = driverTrip.assignedRoutes;
            if (driverTrip.hasActiveTrip && driverTrip.tripId != null) {
              _activeTripId = driverTrip.tripId!;
              _activeRouteId = driverTrip.routeId;
              _liveRouteName = driverTrip.routeName;
              _liveVehiclePlate = driverTrip.vehiclePlate;
              _speedKmh = driverTrip.speedKmh ?? 32.0;
              _stops = driverTrip.stops;
              if (driverTrip.currentLatitude != null &&
                  driverTrip.currentLongitude != null) {
                _busPos = LatLng(
                  driverTrip.currentLatitude!,
                  driverTrip.currentLongitude!,
                );
              }
              if (driverTrip.passengers.isNotEmpty) {
                _passengers
                  ..clear()
                  ..addAll(driverTrip.passengers);
              }
              _roadPath = roadPath;
              _tripState = DriverTripState.inProgress;
              _awaitingTripStart = false;
            } else {
              _awaitingTripStart = driverTrip.assignedRoutes.isNotEmpty;
              _selectedStartRouteId = driverTrip.assignedRoutes.firstOrNull?.id;
              if (driverTrip.assignedRoutes.isNotEmpty) {
                final firstRoute = driverTrip.assignedRoutes.first;
                _activeRouteId = firstRoute.id;
                _liveRouteName = firstRoute.name;
                _liveVehiclePlate = firstRoute.vehiclePlate;
                _stops = firstRoute.waypoints
                    .asMap()
                    .entries
                    .map(
                      (e) => StudentStop(
                        id: 'wp_${e.key}',
                        studentName: e.value.name,
                        address: e.value.address,
                        latitude: e.value.latitude,
                        longitude: e.value.longitude,
                        estimatedTime: '#${e.key + 1}',
                        order: e.key + 1,
                      ),
                    )
                    .toList();
                if (_stops.isNotEmpty) {
                  _busPos = LatLng(_stops.first.latitude, _stops.first.longitude);
                }
                _roadPath = roadPath;
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _startSelectedTrip() async {
    final token = _session?.token ?? '';
    final routeId = _selectedStartRouteId ?? _assignedRoutes.firstOrNull?.id;
    if (token.isEmpty || routeId == null || routeId.isEmpty) return;
    final ok = await _repository.startDriverTrip(
      token,
      organizationId: _session?.organizationId ?? 'org_school_01',
      routeId: routeId,
      driverId: _session?.profileId ?? _session?.userId ?? '',
    );
    if (ok) {
      await _loadSessionAndDocs();
    }
  }

  String _formatExpiryMmYyyy(String? raw) {
    if (raw == null || raw.isEmpty) return '12/2026';
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
      return '${raw.substring(5, 7)}/${raw.substring(0, 4)}';
    }
    return raw;
  }

  int get _boardedCount =>
      _passengers.where((p) => p.status == PassengerBoardingStatus.boarded).length;
  int get _totalCount => _passengers.length;

  Future<void> _openNavigationWithGoogleMaps() async {
    final targetStop = _stops.where((s) => !s.isPickedUp).firstOrNull;
    final lat = targetStop?.latitude ?? _busPos.latitude;
    final lng = targetStop?.longitude ?? _busPos.longitude;
    final url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final fallbackUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _updateStatus(DriverPassenger passenger, PassengerBoardingStatus newStatus) {
    setState(() {
      passenger.status = newStatus;
    });

    final token = _session?.token ?? '';
    if (token.isNotEmpty && _activeTripId != 'TRP-2026-08') {
      final stateStr = newStatus == PassengerBoardingStatus.boarded
          ? 'BOARDED'
          : newStatus == PassengerBoardingStatus.absent
              ? 'ABSENT'
              : 'MISSING';
      _repository.setBoardingStatus(
        token: token,
        tripId: _activeTripId,
        childId: passenger.id,
        boardingState: stateStr,
      );
    }

    final snackMessage = newStatus == PassengerBoardingStatus.boarded
        ? AppStrings.trf('driver_snack_boarded', {'name': passenger.name})
        : newStatus == PassengerBoardingStatus.absent
            ? AppStrings.trf('driver_snack_absent', {'name': passenger.name})
            : AppStrings.trf('driver_snack_pending', {'name': passenger.name});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackMessage),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReportIncidentDialog({String initialTypeKey = 'driver_incident_traffic'}) {
    final noteController = TextEditingController();
    String selectedTypeKey = initialTypeKey;
    int selectedDelayMinutes = 15;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr('driver_incident_title'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTypeKey,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('driver_incident_type_label'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'driver_incident_roadblock',
                          child: Text(AppStrings.tr('driver_incident_roadblock')),
                        ),
                        DropdownMenuItem(
                          value: 'driver_incident_traffic',
                          child: Text(AppStrings.tr('driver_incident_traffic')),
                        ),
                        DropdownMenuItem(
                          value: 'driver_incident_detour',
                          child: Text(AppStrings.tr('driver_incident_detour')),
                        ),
                        DropdownMenuItem(
                          value: 'driver_incident_mechanical',
                          child: Text(AppStrings.tr('driver_incident_mechanical')),
                        ),
                        DropdownMenuItem(
                          value: 'driver_incident_delay',
                          child: Text(AppStrings.tr('driver_incident_delay')),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedTypeKey = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.tr('driver_incident_delay_label'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [15, 30, 45].map((mins) {
                        return ChoiceChip(
                          label: Text(AppStrings.trf('driver_incident_delay_mins', {'mins': mins})),
                          selected: selectedDelayMinutes == mins,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => selectedDelayMinutes = mins);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('driver_incident_notes_label'),
                        hintText: AppStrings.tr('driver_incident_notes_hint'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: Text(
                        AppStrings.tr('driver_incident_send_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final notes = noteController.text.trim();
                        final label = AppStrings.tr(selectedTypeKey);
                        Navigator.pop(ctx);

                        await _repository.reportTripIncident(
                          tripId: _activeTripId,
                          category: selectedTypeKey,
                          delayMinutes: selectedDelayMinutes,
                          notes: notes,
                        );

                        SafetyAlert.addAlert(
                          title: 'Incidencia en Ruta: $label',
                          titleEn: 'Route Incident: $label',
                          message:
                              'Retraso estimado: +$selectedDelayMinutes min.${notes.isNotEmpty ? ' $notes' : ''}',
                          messageEn:
                              'Estimated delay: +$selectedDelayMinutes min.${notes.isNotEmpty ? ' $notes' : ''}',
                          type: 'TRAFFIC',
                        );

                        if (mounted) {
                          setState(() {
                            _activeIncidentTypeKey = selectedTypeKey;
                            _activeIncidentDelayMins = selectedDelayMinutes;
                          });
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.orange.shade800,
                              content: Text(
                                AppStrings.trf('driver_incident_sent_snack', {
                                  'type': '$label (+$selectedDelayMinutes min)',
                                }),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showForceMajeureCancelDialog() async {
    const reasonKeys = [
      'driver_cancel_reason_mechanical',
      'driver_cancel_reason_weather',
      'driver_cancel_reason_roadblock',
      'driver_cancel_reason_other',
    ];
    String? selectedReasonKey;
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.tr('driver_cancel_dialog_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.tr('driver_cancel_dialog_subtitle'),
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReasonKey,
                    isExpanded: true,
                    hint: Text(AppStrings.tr('driver_cancel_reason_label')),
                    decoration: InputDecoration(
                      labelText: AppStrings.tr('driver_cancel_reason_label'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: reasonKeys
                        .map((k) => DropdownMenuItem(value: k, child: Text(AppStrings.tr(k))))
                        .toList(),
                    onChanged: (val) => setDialogState(() => selectedReasonKey = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: AppStrings.tr('driver_cancel_notes_label'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppStrings.tr('common_cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                ),
                onPressed: selectedReasonKey == null ? null : () => Navigator.pop(ctx, true),
                child: Text(AppStrings.tr('driver_cancel_confirm_btn')),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && selectedReasonKey != null && mounted) {
      final reasonText = AppStrings.tr(selectedReasonKey!);
      final notes = notesCtrl.text.trim();

      await _repository.cancelTripForceMajeure(
        tripId: _activeTripId,
        reason: reasonText,
        notes: notes,
      );

      SafetyAlert.addAlert(
        title: '🚨 VIAJE CANCELADO POR FUERZA MAYOR',
        titleEn: '🚨 TRIP CANCELLED (FORCE MAJEURE)',
        message: 'Motivo: $reasonText.${notes.isNotEmpty ? ' $notes' : ''}',
        messageEn: 'Reason: $reasonText.${notes.isNotEmpty ? ' $notes' : ''}',
        type: 'PANIC',
      );

      if (mounted) {
        setState(() {
          _tripState = DriverTripState.cancelled;
          _cancelReasonKey = selectedReasonKey;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.tr('driver_cancel_snack')),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    notesCtrl.dispose();
  }

  void _confirmFinishTrip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.tr('driver_finish_dialog_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          AppStrings.tr('driver_finish_dialog_msg'),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('profile_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final token = _session?.token ?? '';
              if (token.isNotEmpty && _activeTripId != 'TRP-2026-08') {
                await _repository.completeTrip(
                  token: token,
                  tripId: _activeTripId,
                );
              }
              if (mounted) {
                setState(() {
                  _tripState = DriverTripState.finished;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.tr('driver_finish_snack')),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(AppStrings.tr('driver_finish_confirm')),
          ),
        ],
      ),
    );
  }

  void _arriveAllAtSchool() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.school, color: AppTheme.primaryNavy),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('driver_dropoff_dialog_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          AppStrings.tr('driver_dropoff_dialog_msg'),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('common_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                for (var p in _passengers) {
                  if (p.status == PassengerBoardingStatus.pending) {
                    p.status = PassengerBoardingStatus.boarded;
                  }
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.tr('driver_dropoff_snack')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              AppStrings.tr('driver_dropoff_confirm'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalCount == 0 ? 0.0 : _boardedCount / _totalCount;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppStrings.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppTheme.surfaceBackground,
          appBar: AppBar(
            title: Text(_liveRouteName ?? AppStrings.tr('driver_route_title')),
            actions: [
              TextButton.icon(
                onPressed: () => showTripHistorySheet(
                  context,
                  repository: _repository,
                  token: _session?.token ?? '',
                ),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: Text(
                  AppStrings.tr('trip_history_btn'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                tooltip: AppStrings.tr('driver_btn_incident'),
                onPressed: _isTripActive ? () => _showReportIncidentDialog() : null,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_awaitingTripStart && _assignedRoutes.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.tr('driver_pick_route_title'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStartRouteId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: _assignedRoutes
                            .map(
                              (r) => DropdownMenuItem<String>(
                                value: r.id,
                                child: Text(
                                  '${r.name} (${r.vehiclePlate})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _selectedStartRouteId = val),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _startSelectedTrip,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(AppStrings.tr('driver_start_trip_btn')),
                      ),
                    ],
                  ),
                ),
              ],
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.directions_bus, color: AppTheme.primaryNavy),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _liveRouteName ?? AppStrings.tr('driver_route_title'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _liveVehiclePlate != null
                                          ? 'Colegio San Juan • Van $_liveVehiclePlate'
                                          : AppStrings.tr('driver_route_subtitle'),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _tripState == DriverTripState.cancelled
                                ? AppTheme.errorContainer
                                : _tripState == DriverTripState.finished
                                    ? Colors.grey.shade200
                                    : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _tripState == DriverTripState.cancelled
                                ? AppStrings.tr('driver_badge_cancelled')
                                : _tripState == DriverTripState.finished
                                    ? AppStrings.tr('driver_badge_finished')
                                    : AppStrings.tr('driver_badge_in_progress'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _tripState == DriverTripState.cancelled
                                  ? AppTheme.errorColor
                                  : _tripState == DriverTripState.finished
                                      ? Colors.grey.shade700
                                      : Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // US-12 SOAT & License status + Verify Docs
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppStrings.trf('docs_summary_chip', {
                                'date': _formatExpiryMmYyyy(_vehicleDocs?['soat_expires_at']?.toString()),
                                'cat': 'A-IIIa',
                              }),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryNavy,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.verified_user_outlined, size: 15),
                            label: Text(
                              AppStrings.tr('docs_view_verify_btn'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => showVehicleDocsDialog(
                              context,
                              driverName: _session?.fullName ?? 'Carlos Ramirez',
                              vehiclePlate: _vehicleDocs?['plate']?.toString() ?? 'ABC-123',
                              licenseNumber: 'Q-44556677',
                              soatPolicy: _vehicleDocs?['soat_policy']?.toString() ?? 'SOAT-2026-88412',
                              soatExpiry: _formatExpiryMmYyyy(_vehicleDocs?['soat_expires_at']?.toString()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_tripState == DriverTripState.cancelled && _cancelReasonKey != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.trf('driver_cancelled_banner', {
                                  'reason': AppStrings.tr(_cancelReasonKey!),
                                }),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_activeIncidentTypeKey != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.traffic, color: Colors.orange.shade800, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.trf('driver_incident_active_banner', {
                                  'type': AppStrings.tr(_activeIncidentTypeKey!),
                                  'mins': _activeIncidentDelayMins ?? 15,
                                }),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${AppStrings.tr('driver_checklist_title')}:',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          AppStrings.trf('driver_boarded_counter', {
                            'boarded': _boardedCount,
                            'total': _totalCount,
                          }),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Route Map (Parity with Android Native)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: _busPos,
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'pe.edu.upc.routeguard.cross',
                          ),
                          if ((_roadPath != null && _roadPath!.length >= 2) ||
                              _stops.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: (_roadPath != null && _roadPath!.length >= 2)
                                      ? _roadPath!
                                      : [
                                          _busPos,
                                          ..._stops.map(
                                            (s) => LatLng(s.latitude, s.longitude),
                                          ),
                                        ],
                                  strokeWidth: 4.5,
                                  color: AppTheme.primaryNavy,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _busPos,
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: const Icon(Icons.directions_bus, color: Colors.black, size: 22),
                                ),
                              ),
                              ..._stops.map((stop) {
                                final isSchool = stop.studentName.toLowerCase().contains('colegio') ||
                                    stop.studentName.toLowerCase().contains('school');
                                return Marker(
                                  point: LatLng(stop.latitude, stop.longitude),
                                  width: 32,
                                  height: 32,
                                  child: Icon(
                                    isSchool ? Icons.school : Icons.location_on,
                                    color: isSchool
                                        ? AppTheme.primaryNavy
                                        : (stop.isPickedUp ? Colors.green : Colors.teal),
                                    size: 28,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.speed, size: 14, color: AppTheme.primaryNavy),
                              const SizedBox(width: 4),
                              Text(
                                _liveRouteName != null
                                    ? '${_speedKmh.toStringAsFixed(0)} km/h'
                                    : AppStrings.tr('driver_speed_moving'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.gps_fixed, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.tr('driver_gps_active'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Next Stop Card with Google Maps Navigation Button (Parity with Android Native)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.near_me, color: AppTheme.primaryNavy, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.tr('driver_next_stop_title'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  AppStrings.tr('driver_next_stop_subtitle'),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryNavy,
                          side: const BorderSide(color: AppTheme.primaryNavy),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.navigation_outlined, size: 16),
                        label: Text(
                          AppStrings.tr('driver_btn_navigate_maps'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: _openNavigationWithGoogleMaps,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade900,
                        side: BorderSide(color: Colors.orange.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.report_problem_outlined, size: 18),
                      label: Text(
                        AppStrings.tr('driver_btn_incident'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isTripActive ? () => _showReportIncidentDialog() : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isTripActive ? Colors.grey : AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: Text(
                        AppStrings.tr('driver_btn_finish'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: !_isTripActive ? null : _confirmFinishTrip,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // US-29 Roadblock quick action & US-17 Attendance Report
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepOrange.shade800,
                        side: BorderSide(color: Colors.deepOrange.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.traffic_outlined, size: 17),
                      label: Text(
                        AppStrings.tr('driver_incident_roadblock_btn'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isTripActive
                          ? () => _showReportIncidentDialog(initialTypeKey: 'driver_incident_roadblock')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryNavy,
                        side: const BorderSide(color: AppTheme.primaryNavy),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 17),
                      label: Text(
                        AppStrings.tr('attendance_report_btn'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => showAttendanceReportDialog(
                        context,
                        routeName: AppStrings.tr('driver_route_title'),
                        passengers: _passengers,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Batch drop-off action at school (V-05 Don Iván Oscco recommendation)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal.shade800,
                  side: BorderSide(color: Colors.teal.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.teal.shade50.withValues(alpha: 0.5),
                ),
                icon: const Icon(Icons.school, size: 18),
                label: Text(
                  AppStrings.tr('driver_btn_dropoff_all'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: !_isTripActive ? null : _arriveAllAtSchool,
              ),
              const SizedBox(height: 10),

              // US-21 Force Majeure Cancellation button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(
                  AppStrings.tr('driver_btn_force_majeure'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: !_isTripActive ? null : _showForceMajeureCancelDialog,
              ),
              const SizedBox(height: 14),

              // Passengers list header
              Text(
                AppStrings.trf('driver_students_list_header', {'count': _passengers.length}),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),

              ..._passengers.map((passenger) => _buildPassengerCard(passenger)),
              const SizedBox(height: 14),
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('driver_tools_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.campaign_outlined, size: 15, color: AppTheme.primaryNavy),
                            label: Text(AppStrings.tr('announcements_btn'), style: const TextStyle(fontSize: 11)),
                            onPressed: () => PlatformFeatureDialogs.showAnnouncementsDialog(
                              context,
                              repo: _platformRepo,
                              token: _session?.token ?? '',
                              canPublish: true,
                              routeId: _activeRouteId,
                            ),
                          ),
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.alt_route_outlined, size: 15, color: AppTheme.primaryNavy),
                            label: Text(AppStrings.tr('pickup_opt_btn'), style: const TextStyle(fontSize: 11)),
                            onPressed: () => PlatformFeatureDialogs.showPickupAndOptimizationDialog(
                              context,
                              repo: _platformRepo,
                              token: _session?.token ?? '',
                              canRequestChange: false,
                              canApproveChanges: true,
                              routeId: _activeRouteId ?? 'f0000000-0000-0000-0000-000000000001',
                            ),
                          ),
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.chat_bubble_outline, size: 15, color: AppTheme.primaryNavy),
                            label: Text(AppStrings.tr('chat_btn'), style: const TextStyle(fontSize: 11)),
                            onPressed: () => PlatformFeatureDialogs.showChatDialog(
                              context,
                              repo: _platformRepo,
                              token: _session?.token ?? '',
                              userId: _session?.userId ?? 'driver',
                              userName: _session?.fullName ?? 'Carlos Ramirez',
                              userRole: 'DRIVER',
                              routeId: _activeRouteId,
                            ),
                          ),
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.build_outlined, size: 15, color: AppTheme.primaryNavy),
                            label: Text(AppStrings.tr('maintenances_btn'), style: const TextStyle(fontSize: 11)),
                            onPressed: () => PlatformFeatureDialogs.showMaintenanceDialog(
                              context,
                              repo: _platformRepo,
                              token: _session?.token ?? '',
                              canAdd: true,
                              defaultPlate: _vehicleDocs?['plate']?.toString() ?? 'ABC-123',
                            ),
                          ),
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.receipt_long_outlined, size: 15, color: AppTheme.primaryNavy),
                            label: Text(AppStrings.tr('expenses_btn'), style: const TextStyle(fontSize: 11)),
                            onPressed: () => PlatformFeatureDialogs.showExpensesDialog(
                              context,
                              repo: _platformRepo,
                              token: _session?.token ?? '',
                              defaultPlate: _vehicleDocs?['plate']?.toString() ?? 'ABC-123',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassengerCard(DriverPassenger passenger) {
    Color statusBg;
    Color statusFg;
    String statusLabel;

    switch (passenger.status) {
      case PassengerBoardingStatus.boarded:
        statusBg = Colors.green.shade100;
        statusFg = Colors.green.shade900;
        statusLabel = AppStrings.tr('driver_status_boarded');
        break;
      case PassengerBoardingStatus.absent:
        statusBg = Colors.red.shade100;
        statusFg = Colors.red.shade900;
        statusLabel = AppStrings.tr('driver_status_absent');
        break;
      case PassengerBoardingStatus.pending:
        statusBg = Colors.grey.shade200;
        statusFg = Colors.grey.shade800;
        statusLabel = AppStrings.tr('driver_status_pending');
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    passenger.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              passenger.grade,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primaryNavy),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    passenger.stopAddress,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  passenger.scheduledTime,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryNavy),
                ),
              ],
            ),
            const Divider(height: 20),

            // Actions: If already boarded or absent, provide explicit UNDO / REVERT controls (RuwaLabs Heuristic #3)
            if (passenger.status == PassengerBoardingStatus.boarded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.tr('driver_card_onboard'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isTripActive ? () => _updateStatus(passenger, PassengerBoardingStatus.pending) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.undo, size: 14, color: Colors.black87),
                      label: Text(
                        AppStrings.tr('driver_btn_undo_pending'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else if (passenger.status == PassengerBoardingStatus.absent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.tr('driver_card_absent'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _isTripActive ? () => _updateStatus(passenger, PassengerBoardingStatus.pending) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppStrings.tr('driver_btn_back_pending'), style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: _isTripActive ? () => _updateStatus(passenger, PassengerBoardingStatus.boarded) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 14),
                      label: Text(
                        AppStrings.tr('driver_btn_mark_boarded'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(
                        AppStrings.tr('driver_status_absent'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isTripActive ? () => _updateStatus(passenger, PassengerBoardingStatus.absent) : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(
                        AppStrings.tr('driver_status_boarded'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isTripActive ? () => _updateStatus(passenger, PassengerBoardingStatus.boarded) : null,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
