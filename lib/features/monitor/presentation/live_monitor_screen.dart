import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../tracking/models/trip_telemetry.dart';
import '../data/monitor_repository.dart';

class LiveMonitorScreen extends StatefulWidget {
  final MonitorRepository? repository;

  const LiveMonitorScreen({super.key, this.repository});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  late final MonitorRepository _repository;
  final _mapController = MapController();

  List<TripTelemetry> _trips = [];
  TripTelemetry? _selectedTrip;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MonitorRepository();
    _loadTrips();
    // Poll every 10 seconds for real-time fleet updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadTrips(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrips({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final trips = await _repository.getActiveFleetTrips();
    if (mounted) {
      setState(() {
        _trips = trips;
        _isLoading = false;
        if (_selectedTrip == null && trips.isNotEmpty) {
          _selectedTrip = trips.first;
        } else if (_selectedTrip != null) {
          _selectedTrip = trips.firstWhere(
            (t) => t.tripId == _selectedTrip!.tripId,
            orElse: () => trips.first,
          );
        }
      });
    }
  }

  void _selectTrip(TripTelemetry trip) {
    setState(() {
      _selectedTrip = trip;
    });
    _mapController.move(
      LatLng(trip.currentLatitude, trip.currentLongitude),
      14.5,
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
    final mapCenter = _selectedTrip != null
        ? LatLng(_selectedTrip!.currentLatitude, _selectedTrip!.currentLongitude)
        : const LatLng(-12.0965, -77.0360);

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppStrings.currentLanguage,
      builder: (context, _, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.tr('monitor_title')),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadTrips(),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Top Interactive Fleet Map with Legend (RuwaLabs Heurística #9)
                    SizedBox(
                      height: 320,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: mapCenter,
                              initialZoom: 13.8,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'pe.edu.upc.routeguard.crossapp',
                              ),
                              MarkerLayer(
                                markers: _trips.map((trip) {
                                  final isSelected = trip.tripId == _selectedTrip?.tripId;
                                  return Marker(
                                    point: LatLng(trip.currentLatitude, trip.currentLongitude),
                                    width: 50,
                                    height: 50,
                                    child: GestureDetector(
                                      onTap: () => _selectTrip(trip),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppTheme.primaryNavy : Colors.teal.shade700,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: isSelected ? 3 : 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.directions_bus,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLegendItem(AppTheme.primaryNavy, AppStrings.tr('monitor_legend_selected')),
                                  const SizedBox(width: 12),
                                  _buildLegendItem(Colors.teal.shade700, AppStrings.tr('monitor_legend_active')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Trips List
                    Expanded(
                      child: _trips.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_off, size: 56, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(
                                      AppStrings.tr('monitor_no_trips'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppStrings.tr('monitor_no_trips_desc'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _trips.length,
                              itemBuilder: (ctx, index) {
                                final trip = _trips[index];
                                final isSelected = trip.tripId == _selectedTrip?.tripId;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: isSelected ? 4 : 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primaryNavy : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _selectTrip(trip),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  trip.routeName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${trip.speedKmh.toStringAsFixed(0)} km/h',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            AppStrings.trf('monitor_driver_plate', {
                                              'driver': trip.driverName,
                                              'plate': trip.vehiclePlate,
                                            }),
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.25)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.location_on, size: 14, color: AppTheme.primaryNavy),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      AppStrings.tr('monitor_selected_badge'),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.primaryNavy,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Icon(Icons.people, size: 16, color: AppTheme.primaryNavy),
                                              const SizedBox(width: 6),
                                              Text(
                                                AppStrings.trf('monitor_students_onboard', {
                                                  'onboard': trip.onboardStudents,
                                                  'total': trip.totalStudents,
                                                }),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                              const Spacer(),
                                              if (trip.nextStopName != null) ...[
                                                const Icon(Icons.near_me, size: 14, color: Colors.black54),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'ETA: ${trip.etaNextStopMinutes} min',
                                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
