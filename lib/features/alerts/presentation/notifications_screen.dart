import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/safety_alert.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  List<SafetyAlert> _getMockAlerts() {
    return [
      SafetyAlert(
        id: 'alt-01',
        title: 'Abordaje Confirmado',
        message: 'Tu hijo Mateo Gómez ha subido a la unidad de transporte en Parada Javier Prado Este 2450.',
        timestamp: 'Hoy, 07:25 AM',
        type: 'BOARDING',
      ),
      SafetyAlert(
        id: 'alt-02',
        title: 'Inicio de Recorrido Escolar',
        message: 'El conductor Luis Johnny inició la Ruta 02 hacia el Colegio San Juan.',
        timestamp: 'Hoy, 07:10 AM',
        type: 'INFO',
      ),
      SafetyAlert(
        id: 'alt-03',
        title: 'Llegada Segura al Colegio',
        message: 'Ayer todos los estudiantes fueron entregados en la puerta principal del colegio sin incidentes.',
        timestamp: 'Ayer, 07:52 AM',
        type: 'ARRIVED',
      ),
      SafetyAlert(
        id: 'alt-04',
        title: 'Aviso de Tránsito Matutino',
        message: 'Congestión moderada reportada en Av. Javier Prado. Tiempo estimado de retraso: +5 minutos.',
        timestamp: 'Ayer, 07:15 AM',
        type: 'TRAFFIC',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _getMockAlerts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones y Avisos'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final alert = alerts[index];

          IconData icon;
          Color iconBg;

          switch (alert.type) {
            case 'BOARDING':
              icon = Icons.check_circle_outline;
              iconBg = Colors.green.shade600;
              break;
            case 'ARRIVED':
              icon = Icons.school_outlined;
              iconBg = AppTheme.primaryNavy;
              break;
            case 'TRAFFIC':
              icon = Icons.warning_amber_rounded;
              iconBg = Colors.orange.shade700;
              break;
            default:
              icon = Icons.info_outline;
              iconBg = AppTheme.primaryTeal;
          }

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconBg, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              alert.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              alert.timestamp,
                              style: const TextStyle(fontSize: 11, color: Colors.black45),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alert.message,
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
