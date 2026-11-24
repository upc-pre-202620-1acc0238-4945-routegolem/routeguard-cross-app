import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../models/safety_alert.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _broadcastController = TextEditingController();
  bool _isPublishing = false;

  @override
  void dispose() {
    _broadcastController.dispose();
    super.dispose();
  }

  void _showPanicConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('¿Emitir Alerta de Pánico?'),
          ],
        ),
        content: const Text(
          'Esta acción notificará con máxima prioridad a la central de monitoreo y a todos los padres de familia sobre una situación de emergencia en la ruta.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              SafetyAlert.addAlert(
                title: '🚨 ALERTA DE PÁNICO DEL CONDUCTOR',
                message: 'El conductor Luis Johnny ha activado la alerta de emergencia en la Ruta 02. Central de monitoreo interviniendo.',
                type: 'PANIC',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Alerta de pánico transmitida a todos los apoderados y central!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Sí, emitir alerta', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _publishBroadcast() {
    final text = _broadcastController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPublishing = true);
    SafetyAlert.addAlert(
      title: 'Aviso del Conductor en Ruta',
      message: text,
      type: 'TRAFFIC',
    );
    _broadcastController.clear();
    setState(() => _isPublishing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Aviso publicado y sincronizado con los padres!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SessionManager.activeRoleNotifier,
      builder: (context, activeRole, _) {
        final isDriver = SessionManager.normalizeRole(activeRole) == 'DRIVER';

        return Scaffold(
          backgroundColor: AppTheme.surfaceBackground,
          appBar: AppBar(
            title: const Text('Notificaciones y Avisos'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check_circle_outlined),
                tooltip: 'Marcar todo leído',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todas las notificaciones marcadas como leídas.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ValueListenableBuilder<List<SafetyAlert>>(
            valueListenable: SafetyAlert.sharedAlertsNotifier,
            builder: (context, alerts, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Driver-specific Publisher Section (Parity with Android Native)
                  if (isDriver) ...[
                    // Panic Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.warning, color: Colors.white),
                        label: const Text(
                          'Alerta de pánico',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: _showPanicConfirmDialog,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Aviso a los padres Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Aviso a los padres',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _broadcastController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Mensaje (ej. retraso por tráfico)',
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryNavy,
                                side: const BorderSide(color: AppTheme.primaryNavy),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: _isPublishing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.campaign_outlined, size: 18),
                              label: const Text('Publicar aviso', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _isPublishing ? null : _publishBroadcast,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Section Title: Historial
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDriver ? 'Historial de Alertas' : 'Historial de Notificaciones',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                      ),
                      Text(
                        '${alerts.length} avisos',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...alerts.map((alert) => _buildAlertCard(alert)),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAlertCard(SafetyAlert alert) {
    IconData icon;
    Color iconBg;
    bool isPanic = alert.type == 'PANIC';

    switch (alert.type) {
      case 'PANIC':
        icon = Icons.warning;
        iconBg = Colors.red.shade700;
        break;
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPanic ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPanic ? Colors.red.shade400 : Colors.grey.shade200,
          width: isPanic ? 1.5 : 1.0,
        ),
      ),
      color: isPanic ? const Color(0xFFFFECEB) : Colors.white,
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
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isPanic ? Colors.red.shade900 : Colors.black87,
                          ),
                        ),
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
                    style: TextStyle(
                      fontSize: 13,
                      color: isPanic ? Colors.red.shade900 : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
