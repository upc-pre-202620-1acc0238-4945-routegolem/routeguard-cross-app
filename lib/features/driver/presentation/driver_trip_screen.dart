import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../models/driver_passenger.dart';

class DriverTripScreen extends StatefulWidget {
  const DriverTripScreen({super.key});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  final List<DriverPassenger> _passengers = DriverPassenger.getInitialRoster();
  bool _isRouteFinished = false;

  int get _boardedCount =>
      _passengers.where((p) => p.status == PassengerBoardingStatus.boarded).length;
  int get _absentCount =>
      _passengers.where((p) => p.status == PassengerBoardingStatus.absent).length;
  int get _totalCount => _passengers.length;

  Future<void> _openNavigationWithGoogleMaps() async {
    final url = Uri.parse('google.navigation:q=-12.0898,-77.0055&mode=d');
    final fallbackUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=-12.0898,-77.0055');
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

    final snackMessage = newStatus == PassengerBoardingStatus.boarded
        ? '¡${passenger.name} abordó la movilidad escolar!'
        : newStatus == PassengerBoardingStatus.absent
            ? '${passenger.name} marcado como no asistió.'
            : 'Estado de ${passenger.name} restablecido a pendiente.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackMessage),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReportIncidentDialog() {
    final noteController = TextEditingController();
    String selectedType = 'Tráfico pesado';

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
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Reportar Incidencia en Ruta',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipo de contingencia',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tráfico pesado', child: Text('Tráfico pesado en vía')),
                      DropdownMenuItem(value: 'Desvío por obras', child: Text('Desvío por obras públicas')),
                      DropdownMenuItem(value: 'Falla mecánica menor', child: Text('Falla mecánica menor')),
                      DropdownMenuItem(value: 'Demora de abordaje', child: Text('Demora justificada de abordaje')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Detalles u observaciones para los padres',
                      hintText: 'Ej. Estimamos un retraso de 8 minutos en Av. Brasil.',
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
                    label: const Text('Notificar a los Padres de Familia', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.orange.shade800,
                          content: Text('Incidencia notificada: $selectedType'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isRouteFinished = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Recorrido finalizado exitosamente! Notificaciones enviadas.'),
                  backgroundColor: Colors.green,
                ),
              );
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
        title: const Row(
          children: [
            Icon(Icons.school, color: AppTheme.primaryNavy),
            SizedBox(width: 8),
            Text('Descenso General en Colegio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          '¿Deseas confirmar la entrega y descenso seguro de todos los estudiantes a bordo en la puerta del colegio?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
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
                const SnackBar(
                  content: Text('¡Descenso general completado! Todos los estudiantes llegaron a salvo al colegio.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar Llegada', style: TextStyle(fontWeight: FontWeight.bold)),
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
            title: Text(AppStrings.tr('driver_route_title')),
            actions: [
              IconButton(
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                tooltip: AppStrings.tr('driver_btn_incident'),
                onPressed: _showReportIncidentDialog,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                                      AppStrings.tr('driver_route_title'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      AppStrings.tr('driver_route_subtitle'),
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
                            color: _isRouteFinished ? Colors.grey.shade200 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isRouteFinished ? 'FINALIZADO' : 'EN CURSO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isRouteFinished ? Colors.grey.shade700 : Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          '$_boardedCount / $_totalCount ${AppStrings.tr('driver_status_boarded').toLowerCase()}s',
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
                        options: const MapOptions(
                          initialCenter: LatLng(-12.0898, -77.0055),
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'pe.edu.upc.routeguard.cross',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: const [
                                  LatLng(-12.0850, -77.0120),
                                  LatLng(-12.0898, -77.0055),
                                  LatLng(-12.0950, -76.9980),
                                  LatLng(-12.1020, -76.9920),
                                ],
                                strokeWidth: 4.5,
                                color: AppTheme.primaryNavy,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: const LatLng(-12.0898, -77.0055),
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
                              Marker(
                                point: const LatLng(-12.0850, -77.0120),
                                width: 32,
                                height: 32,
                                child: const Icon(Icons.location_on, color: Colors.green, size: 28),
                              ),
                              Marker(
                                point: const LatLng(-12.0950, -76.9980),
                                width: 32,
                                height: 32,
                                child: const Icon(Icons.location_on, color: Colors.teal, size: 28),
                              ),
                              Marker(
                                point: const LatLng(-12.1020, -76.9920),
                                width: 32,
                                height: 32,
                                child: const Icon(Icons.school, color: AppTheme.primaryNavy, size: 28),
                              ),
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
                                '38 km/h · En movimiento',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
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
                            children: const [
                              Icon(Icons.gps_fixed, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('GPS Activo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Próxima parada: Parada 1: Javier Prado Este',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'En curso hacia punto de recojo · 07:15 AM',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
                        label: const Text('Navegar con Google Maps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                      onPressed: _showReportIncidentDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRouteFinished ? Colors.grey : AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: Text(
                        AppStrings.tr('driver_btn_finish'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isRouteFinished ? null : _confirmFinishTrip,
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
                label: const Text(
                  'Llegada al Colegio (Descenso general)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _isRouteFinished ? null : _arriveAllAtSchool,
              ),
              const SizedBox(height: 14),

              // Passengers list header
              Text(
                'Lista de Estudiantes (${_passengers.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),

              ..._passengers.map((passenger) => _buildPassengerCard(passenger)),
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
                    const Expanded(
                      child: Text(
                        'A bordo de la unidad escolar',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _updateStatus(passenger, PassengerBoardingStatus.pending),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.undo, size: 14, color: Colors.black87),
                      label: const Text(
                        'Deshacer (volver a Pendiente)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                    const Expanded(
                      child: Text(
                        'Marcado como no asistió',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _updateStatus(passenger, PassengerBoardingStatus.pending),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Volver a Pendiente', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus(passenger, PassengerBoardingStatus.boarded),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text(
                        'Marcar Subió',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                      onPressed: () => _updateStatus(passenger, PassengerBoardingStatus.absent),
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
                      onPressed: () => _updateStatus(passenger, PassengerBoardingStatus.boarded),
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
