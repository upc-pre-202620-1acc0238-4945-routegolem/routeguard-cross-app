import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../data/notifications_repository.dart';
import '../models/safety_alert.dart';

enum AlertFilter { all, priority, trip, notices }

class NotificationsScreen extends StatefulWidget {
  final SessionManager? sessionManager;
  final NotificationsRepository? repository;

  const NotificationsScreen({
    super.key,
    this.sessionManager,
    this.repository,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _broadcastController = TextEditingController();
  late final NotificationsRepository _repository;
  SessionManager? _resolvedSession;
  bool _isPublishing = false;
  bool _isLoading = false;
  AlertFilter _selectedFilter = AlertFilter.all;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? NotificationsRepository();
    _initAndLoad();
  }

  @override
  void dispose() {
    _broadcastController.dispose();
    super.dispose();
  }

  Future<SessionManager?> _ensureSession() async {
    if (widget.sessionManager != null) return widget.sessionManager;
    if (_resolvedSession != null) return _resolvedSession;
    try {
      _resolvedSession = await SessionManager.create();
    } catch (_) {}
    return _resolvedSession;
  }

  Future<void> _initAndLoad() async {
    final session = await _ensureSession();
    final token = session?.token ?? '';
    if (token.isEmpty || token.startsWith('mock_') || token.startsWith('demo-')) {
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    final list = await _repository.getNotifications(
      token: token,
      sessionManager: session,
      userId: session?.userId,
      role: session?.role,
      profileId: session?.profileId,
    );
    if (mounted) setState(() => _isLoading = false);

    final isDriver = SessionManager.normalizeRole(session?.role ?? '') == 'DRIVER';
    if (!isDriver && list.any((a) => !a.isDelivered)) {
      await _repository.markDelivered(token, list);
    }
  }

  Future<void> _refresh() async {
    final session = await _ensureSession();
    final token = session?.token ?? '';
    if (token.isEmpty || token.startsWith('mock_') || token.startsWith('demo-')) {
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    final list = await _repository.getNotifications(
      token: token,
      sessionManager: session,
      userId: session?.userId,
      role: session?.role,
      profileId: session?.profileId,
    );
    if (mounted) setState(() => _isLoading = false);

    final isDriver = SessionManager.normalizeRole(session?.role ?? '') == 'DRIVER';
    if (!isDriver && list.any((a) => !a.isDelivered)) {
      await _repository.markDelivered(token, list);
    }
  }

  List<SafetyAlert> _filterAlerts(List<SafetyAlert> all) {
    switch (_selectedFilter) {
      case AlertFilter.all:
        return all;
      case AlertFilter.priority:
        return all.where((a) => a.isHighPriority).toList();
      case AlertFilter.trip:
        return all.where((a) {
          final t = a.type.toUpperCase();
          return t == 'TRIP_STARTED' ||
              t == 'GEOFENCE_BREACHED' ||
              t == 'ARRIVED' ||
              t == 'STUDENT_BOARDED' ||
              t == 'BOARDING';
        }).toList();
      case AlertFilter.notices:
        return all.where((a) {
          final t = a.type.toUpperCase();
          return t == 'ANNOUNCEMENT' || t == 'GENERAL' || t == 'INFO';
        }).toList();
    }
  }

  void _showPanicConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(AppStrings.tr('alerts_panic_dialog_title'))),
          ],
        ),
        content: Text(
          AppStrings.tr('alerts_panic_dialog_msg'),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('common_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final session = await _ensureSession();
              final token = session?.token ?? '';
              final notified = await _repository.triggerPanic(token);
              if (notified != null) {
                await _refresh();
              } else {
                SafetyAlert.addAlert(
                  title: '🚨 ALERTA DE PÁNICO DEL CONDUCTOR',
                  titleEn: '🚨 DRIVER PANIC ALERT',
                  message:
                      'El conductor ${session?.fullName ?? 'Luis Johnny'} ha activado la alerta de emergencia en la ruta. Central de monitoreo interviniendo.',
                  messageEn:
                      'Driver ${session?.fullName ?? 'Luis Johnny'} triggered an emergency alert on the route. Monitoring center intervening.',
                  type: 'PANIC_ALERT',
                );
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.tr('alerts_panic_snack')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              AppStrings.tr('alerts_panic_confirm_btn'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishBroadcast() async {
    final text = _broadcastController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPublishing = true);
    final session = await _ensureSession();
    final token = session?.token ?? '';
    final notified = await _repository.sendBroadcast(token, text);
    if (notified != null) {
      await _refresh();
    } else {
      SafetyAlert.addAlert(
        title: 'Aviso del Conductor en Ruta',
        titleEn: 'On-Route Driver Notice',
        message: text,
        type: 'ANNOUNCEMENT',
      );
    }
    _broadcastController.clear();
    if (mounted) {
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('alerts_broadcast_snack')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAllRead(List<SafetyAlert> alerts) async {
    final session = await _ensureSession();
    final token = session?.token ?? '';
    await _repository.markDelivered(token, alerts);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('alerts_marked_read_snack')),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppStrings.currentLanguage,
      builder: (context, _, _) {
        return ValueListenableBuilder<String>(
          valueListenable: SessionManager.activeRoleNotifier,
          builder: (context, activeRole, _) {
            final isDriver = SessionManager.normalizeRole(activeRole) == 'DRIVER';

            return ValueListenableBuilder<List<SafetyAlert>>(
              valueListenable: SafetyAlert.sharedAlertsNotifier,
              builder: (context, alerts, _) {
                final filtered = _filterAlerts(alerts);

                return Scaffold(
                  backgroundColor: AppTheme.surfaceBackground,
                  appBar: AppBar(
                    title: Text(AppStrings.tr('alerts_title')),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: AppStrings.tr('alerts_refresh_tooltip'),
                        onPressed: _isLoading ? null : _refresh,
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outlined),
                        tooltip: AppStrings.tr('alerts_mark_all_read'),
                        onPressed: () => _markAllRead(alerts),
                      ),
                    ],
                  ),
                  body: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_isLoading && alerts.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        if (isDriver) ...[
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
                              label: Text(
                                AppStrings.tr('alerts_panic_btn'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              onPressed: _showPanicConfirmDialog,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                  Text(
                                    AppStrings.tr('alerts_broadcast_heading'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _broadcastController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      hintText: AppStrings.tr('alerts_broadcast_hint'),
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
                                    label: Text(
                                      AppStrings.tr('alerts_broadcast_btn'),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: _isPublishing ? null : _publishBroadcast,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isDriver
                                  ? AppStrings.tr('alerts_history_driver')
                                  : AppStrings.tr('alerts_history_parent'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Text(
                              AppStrings.trf('alerts_count_label', {'count': filtered.length}),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(AlertFilter.all, 'alerts_filter_all'),
                              const SizedBox(width: 8),
                              _buildFilterChip(AlertFilter.priority, 'alerts_filter_priority'),
                              const SizedBox(width: 8),
                              _buildFilterChip(AlertFilter.trip, 'alerts_filter_trip'),
                              const SizedBox(width: 8),
                              _buildFilterChip(AlertFilter.notices, 'alerts_filter_notices'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filtered.isEmpty && !_isLoading)
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(Icons.notifications_none, size: 42, color: Colors.grey.shade500),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.tr('alerts_empty_title'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.tr('alerts_empty_desc'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filtered.map((alert) => _buildAlertCard(alert)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(AlertFilter filter, String labelKey) {
    final selected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(AppStrings.tr(labelKey), style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
    );
  }

  Widget _buildAlertCard(SafetyAlert alert) {
    IconData icon;
    Color iconBg;
    final isPanic = alert.isPanic;

    switch (alert.type.toUpperCase()) {
      case 'PANIC':
      case 'PANIC_ALERT':
        icon = Icons.warning;
        iconBg = Colors.red.shade700;
        break;
      case 'BOARDING':
      case 'STUDENT_BOARDED':
        icon = Icons.check_circle_outline;
        iconBg = Colors.green.shade600;
        break;
      case 'ARRIVED':
        icon = Icons.school_outlined;
        iconBg = AppTheme.primaryNavy;
        break;
      case 'GEOFENCE_BREACHED':
        icon = Icons.location_on_outlined;
        iconBg = AppTheme.primaryTeal;
        break;
      case 'TRAFFIC':
      case 'INCIDENT_REPORTED':
        icon = Icons.warning_amber_rounded;
        iconBg = Colors.orange.shade700;
        break;
      case 'TRIP_STARTED':
        icon = Icons.directions_bus_outlined;
        iconBg = AppTheme.primaryTeal;
        break;
      default:
        icon = Icons.info_outline;
        iconBg = AppTheme.primaryNavy;
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
                          alert.localizedTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isPanic ? Colors.red.shade900 : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        alert.localizedTimestamp,
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.localizedMessage,
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
