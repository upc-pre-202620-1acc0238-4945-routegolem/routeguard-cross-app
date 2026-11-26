import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../data/tracking_repository.dart';
import '../models/student_stop.dart';
import '../models/trip_telemetry.dart';

class LiveTrackingScreen extends StatefulWidget {
  final SessionManager sessionManager;

  const LiveTrackingScreen({super.key, required this.sessionManager});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _repository = TrackingRepository();
  final _mapController = MapController();

  TripTelemetry? _telemetry;
  List<StudentStop> _stops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    setState(() => _isLoading = true);
    final token = widget.sessionManager.token ?? '';
    final telemetry = await _repository.getActiveTrip(token);
    final stops = await _repository.getStudentStops(token);

    if (mounted) {
      setState(() {
        _telemetry = telemetry;
        _stops = stops;
        _isLoading = false;
      });
    }
  }

  void _showDriverVehicleSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user, color: AppTheme.primaryNavy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.tr('tracking_vehicle_sheet_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryNavy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVehicleDetailRow(
              Icons.directions_bus,
              AppStrings.tr('tracking_vehicle_unit_label'),
              AppStrings.tr('tracking_vehicle_unit_val'),
            ),
            _buildVehicleDetailRow(
              Icons.confirmation_number_outlined,
              AppStrings.tr('tracking_vehicle_plate_label'),
              _telemetry?.vehiclePlate ?? 'ABC-789',
            ),
            _buildVehicleDetailRow(
              Icons.palette_outlined,
              AppStrings.tr('tracking_vehicle_color_label'),
              AppStrings.tr('tracking_vehicle_color_val'),
            ),
            _buildVehicleDetailRow(
              Icons.badge_outlined,
              AppStrings.tr('tracking_vehicle_driver_label'),
              '${_telemetry?.driverName ?? "Carlos Ramírez"} · DNI: 08492019',
            ),
            _buildVehicleDetailRow(
              Icons.security,
              AppStrings.tr('tracking_vehicle_soat_label'),
              AppStrings.tr('tracking_vehicle_soat_val'),
            ),
            _buildVehicleDetailRow(
              Icons.phone_android,
              AppStrings.tr('tracking_vehicle_phone_label'),
              '+51 987 654 321',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.phone),
                label: Text(AppStrings.tr('tracking_btn_call_driver')),
                onPressed: () {
                  Navigator.pop(ctx);
                  _callDriver();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryNavy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callDriver() async {
    final phoneUri = Uri.parse('tel:+51987654321');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.tr('tracking_calling_snack')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showStopsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppStrings.tr('tracking_stops_sheet_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryNavy),
                  ),
                ),
                Text(
                  AppStrings.trf('tracking_stops_count', {'count': _stops.length}),
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _stops.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final stop = _stops[idx];
                  final isSchool = stop.studentName.contains('Colegio') || stop.studentName.contains('School');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isSchool
                          ? Colors.red.shade100
                          : (stop.isPickedUp ? Colors.green.shade100 : Colors.orange.shade100),
                      child: Icon(
                        isSchool ? Icons.school : (stop.isPickedUp ? Icons.check : Icons.person_pin),
                        size: 16,
                        color: isSchool
                            ? Colors.red.shade900
                            : (stop.isPickedUp ? Colors.green.shade900 : Colors.orange.shade900),
                      ),
                    ),
                    title: Text(stop.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(stop.address, style: const TextStyle(fontSize: 11)),
                    trailing: Text(
                      stop.estimatedTime,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryNavy),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final busPos = _telemetry != null
        ? LatLng(_telemetry!.currentLatitude, _telemetry!.currentLongitude)
        : const LatLng(-12.0965, -77.0360);

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppStrings.currentLanguage,
      builder: (context, _, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr('tracking_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_telemetry != null)
                  Text(
                    _telemetry!.routeName,
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.normal),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.list_alt_rounded),
                tooltip: AppStrings.tr('tracking_tooltip_stops'),
                onPressed: _showStopsSheet,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.tr('tracking_tooltip_refresh'),
                onPressed: _loadTrackingData,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: busPos,
                        initialZoom: 14.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'pe.edu.upc.routeguard.crossapp',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                LatLng(-12.0920, -77.0280),
                                busPos,
                                LatLng(-12.1050, -77.0320),
                                LatLng(-12.1120, -77.0350),
                              ],
                              strokeWidth: 4.5,
                              color: AppTheme.primaryNavy.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: busPos,
                              width: 54,
                              height: 54,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            ..._stops.map((stop) {
                              final isSchool = stop.studentName.contains('Colegio') || stop.studentName.contains('School');
                              final isPicked = stop.isPickedUp;
                              return Marker(
                                point: LatLng(stop.latitude, stop.longitude),
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSchool
                                        ? Colors.red.shade700
                                        : (isPicked ? Colors.green.shade600 : Colors.orange.shade700),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    isSchool ? Icons.school : (isPicked ? Icons.check : Icons.person_pin),
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem(AppTheme.primaryNavy, AppStrings.tr('tracking_legend_bus')),
                            const SizedBox(height: 4),
                            _buildLegendItem(Colors.green.shade600, AppStrings.tr('tracking_legend_boarded')),
                            const SizedBox(height: 4),
                            _buildLegendItem(Colors.orange.shade700, AppStrings.tr('tracking_legend_next')),
                            const SizedBox(height: 4),
                            _buildLegendItem(Colors.red.shade700, AppStrings.tr('tracking_legend_school')),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppStrings.tr('tracking_trip_in_progress'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_telemetry?.speedKmh ?? 0} km/h',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                              if ((_telemetry?.speedKmh ?? 0) <= 0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          AppStrings.tr('tracking_gps_stale'),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.errorColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const Divider(height: 20),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: AppTheme.primaryNavy),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _telemetry?.driverName ?? 'Carlos Ramírez',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          AppStrings.trf('tracking_plate_prefix', {
                                            'plate': _telemetry?.vehiclePlate ?? 'ABC-789',
                                          }),
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.green),
                                    tooltip: AppStrings.tr('tracking_tooltip_call'),
                                    onPressed: _callDriver,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.shield_outlined, color: AppTheme.primaryNavy),
                                    tooltip: AppStrings.tr('tracking_tooltip_security'),
                                    onPressed: _showDriverVehicleSheet,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
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
                                        AppStrings.tr('tracking_child_boarded_eta'),
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _showStopsSheet,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        AppStrings.tr('tracking_btn_itinerary'),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF047857),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.call, size: 18),
                                  label: Text(
                                    AppStrings.trf('tracking_btn_call_driver_named', {
                                      'name': _telemetry?.driverName ?? 'Carlos Ramírez',
                                    }),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: _callDriver,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
