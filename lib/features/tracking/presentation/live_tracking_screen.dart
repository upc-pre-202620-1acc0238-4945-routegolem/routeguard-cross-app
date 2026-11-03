import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  Widget build(BuildContext context) {
    final busPos = _telemetry != null
        ? LatLng(_telemetry!.currentLatitude, _telemetry!.currentLongitude)
        : const LatLng(-12.0965, -77.0360);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seguimiento en Vivo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar telemetría',
            onPressed: _loadTrackingData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 1. Interactive OpenStreetMap via flutter_map
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
                    // Route Polyline
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
                    // Markers Layer
                    MarkerLayer(
                      markers: [
                        // School Bus Marker
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
                        // Student Stops Markers
                        ..._stops.map((stop) {
                          final isSchool = stop.studentName.contains('Colegio');
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

                // 2. Telemetry Overlay Card at the bottom
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
                          // Trip Status Header
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
                                  const Text(
                                    'VIAJE EN CURSO',
                                    style: TextStyle(
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
                          const Divider(height: 20),

                          // Driver & Unit Details
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
                                      _telemetry?.driverName ?? 'Conductor',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Placa: ${_telemetry?.vehiclePlate ?? ""} · Estudiantes a bordo: ${_telemetry?.onboardStudents}/${_telemetry?.totalStudents}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Child Status Card
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tu hijo Mateo Gómez abordó la movilidad (07:25 AM). Llegada estimada al colegio: 07:50 AM.',
                                    style: TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ],
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
  }
}
