import 'package:flutter/material.dart';
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
  int get _totalCount => _passengers.length;

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
                        Row(
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.tr('driver_route_title'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  AppStrings.tr('driver_route_subtitle'),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                        Text(
                          '${AppStrings.tr('driver_checklist_title')}:',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
              const SizedBox(height: 16),

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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: passenger.status == PassengerBoardingStatus.absent
                          ? Colors.red.shade900
                          : Colors.grey.shade700,
                      side: BorderSide(
                        color: passenger.status == PassengerBoardingStatus.absent
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: passenger.status == PassengerBoardingStatus.absent
                          ? Colors.red.shade50
                          : Colors.transparent,
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
                      backgroundColor: passenger.status == PassengerBoardingStatus.boarded
                          ? Colors.green.shade800
                          : AppTheme.primaryNavy,
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
