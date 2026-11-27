import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/road_routing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/fleet_repository.dart';
import '../models/route_model.dart';
import '../models/route_waypoint.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  final FleetRepository repository;
  final VoidCallback onRouteUpdated;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
    required this.repository,
    required this.onRouteUpdated,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final _mapController = MapController();
  final _stopNameController = TextEditingController();
  final _stopAddressController = TextEditingController();
  final _stopTimeController = TextEditingController(text: '07:20 AM');

  RouteModel? _route;
  bool _isLoading = true;
  LatLng? _pickedPoint;
  List<LatLng>? _roadPath;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _stopNameController.dispose();
    _stopAddressController.dispose();
    _stopTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final route = await widget.repository.getRouteDetail(widget.routeId);
    if (mounted) {
      setState(() {
        _route = route;
        _isLoading = false;
        if (route != null && route.waypoints.isNotEmpty) {
          _pickedPoint = LatLng(route.waypoints.first.latitude, route.waypoints.first.longitude);
        } else {
          _pickedPoint = const LatLng(-12.0965, -77.0360);
        }
      });
    }
    if (route != null && route.waypoints.length >= 2) {
      final pts = route.waypoints
          .map((w) => LatLng(w.latitude, w.longitude))
          .toList();
      final road = await RoadRoutingService.instance.getRoadRoute(pts);
      if (mounted && road != null && road.path.length >= 2) {
        setState(() {
          _roadPath = road.path;
        });
      }
    }
  }

  Future<void> _handleAddWaypoint() async {
    final name = _stopNameController.text.trim();
    final address = _stopAddressController.text.trim();
    if (name.isEmpty) return;

    final targetPoint = _pickedPoint ?? const LatLng(-12.0965, -77.0360);
    final order = (_route?.waypoints.length ?? 0) + 1;

    final newWaypoint = RouteWaypoint(
      id: 'wp_${DateTime.now().millisecondsSinceEpoch}',
      orderIndex: order,
      name: name,
      address: address.isEmpty ? name : address,
      latitude: targetPoint.latitude,
      longitude: targetPoint.longitude,
      scheduledTime: _stopTimeController.text.trim(),
    );

    await widget.repository.addWaypoint(widget.routeId, newWaypoint);
    _stopNameController.clear();
    _stopAddressController.clear();

    await _loadDetail();
    widget.onRouteUpdated();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.tr('route_stop_added_msg')} ("$name")'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleActivateRoute() async {
    await widget.repository.activateRoute(widget.routeId);
    await _loadDetail();
    widget.onRouteUpdated();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('route_activated_msg')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.tr('route_detail_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final route = _route;
    if (route == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.tr('route_detail_title'))),
        body: Center(child: Text(AppStrings.tr('route_not_found'))),
      );
    }

    final isDraft = route.isEditable;
    final mapCenter = _pickedPoint ??
        (route.waypoints.isNotEmpty
            ? LatLng(route.waypoints.first.latitude, route.waypoints.first.longitude)
            : const LatLng(-12.0965, -77.0360));

    final polylinePoints = route.waypoints
        .map((w) => LatLng(w.latitude, w.longitude))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(route.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Route Header Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDraft ? Colors.orange : Colors.green).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isDraft ? AppStrings.tr('route_status_draft') : AppStrings.tr('route_status_active'),
                          style: TextStyle(
                            color: isDraft ? Colors.orange.shade900 : Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.trf('route_detail_summary', {
                      'stops': route.stopCount,
                      'driver': route.driverName,
                      'plate': route.vehiclePlate,
                    }),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  if (route.departureTime != null)
                    Text(
                      AppStrings.trf('route_detail_departure', {'time': route.departureTime!}),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Map with Stops and Polyline
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 240,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 13.5,
                  onTap: isDraft
                      ? (tapPosition, point) {
                          setState(() {
                            _pickedPoint = point;
                          });
                        }
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'pe.edu.upc.routeguard.crossapp',
                  ),
                  if (polylinePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: (_roadPath != null && _roadPath!.length >= 2)
                              ? _roadPath!
                              : polylinePoints,
                          strokeWidth: 4,
                          color: AppTheme.primaryNavy,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      ...route.waypoints.map((wp) {
                        return Marker(
                          point: LatLng(wp.latitude, wp.longitude),
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryNavy,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${wp.orderIndex}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (isDraft && _pickedPoint != null)
                        Marker(
                          point: _pickedPoint!,
                          width: 38,
                          height: 38,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 38,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Stops List
          Text(
            AppStrings.tr('route_stops_heading'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (route.waypoints.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(AppStrings.tr('route_no_stops')),
              ),
            )
          else
            ...route.waypoints.map((wp) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
                    child: Text(
                      '${wp.orderIndex}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                    ),
                  ),
                  title: Text(wp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${wp.address}\n${AppStrings.trf('route_approx_time', {'time': wp.scheduledTime})}'),
                ),
              );
            }),

          // If Draft: Add Stop Form + Activate Route Button
          if (isDraft) ...[
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.tr('route_add_stop_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.tr('route_add_stop_instruction'),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _stopNameController,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('route_stop_name_label'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _stopAddressController,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('route_stop_address_label'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _stopTimeController,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('route_stop_time_label'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_location_alt),
                      label: Text(AppStrings.tr('route_btn_add_stop')),
                      onPressed: _handleAddWaypoint,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                AppStrings.tr('route_btn_activate'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _handleActivateRoute,
            ),
          ],
        ],
      ),
    );
  }
}
