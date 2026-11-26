import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/platform_features_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../../../core/widgets/platform_feature_dialogs.dart';
import '../data/fleet_repository.dart';
import '../models/route_model.dart';
import 'route_detail_screen.dart';

class RoutesScreen extends StatefulWidget {
  final FleetRepository? repository;

  const RoutesScreen({super.key, this.repository});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late final FleetRepository _repository;
  final PlatformFeaturesRepository _platformRepo = PlatformFeaturesRepository();
  final _newRouteController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String _token = '';

  List<RouteModel> _routes = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FleetRepository();
    SessionManager.create().then((s) {
      if (mounted) setState(() => _token = s.token ?? '');
    }).catchError((_) {});
    _loadRoutes();
  }

  @override
  void dispose() {
    _newRouteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    final routes = await _repository.getRoutes();
    if (mounted) {
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCreateRoute() async {
    final name = _newRouteController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    final created = await _repository.createRoute(name);
    _newRouteController.clear();

    await _loadRoutes();

    if (mounted) {
      setState(() => _isCreating = false);
      _openRouteDetail(created.id);
    }
  }

  void _openRouteDetail(String routeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailScreen(
          routeId: routeId,
          repository: _repository,
          onRouteUpdated: _loadRoutes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppStrings.currentLanguage,
      builder: (context, _, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.tr('routes_title')),
            actions: [
              IconButton(
                icon: const Icon(Icons.build_outlined),
                tooltip: AppStrings.tr('maintenances_btn'),
                onPressed: () => PlatformFeatureDialogs.showMaintenanceDialog(
                  context,
                  repo: _platformRepo,
                  token: _token,
                  canAdd: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: AppStrings.tr('expenses_btn'),
                onPressed: () => PlatformFeatureDialogs.showExpensesDialog(
                  context,
                  repo: _platformRepo,
                  token: _token,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.alt_route_outlined),
                tooltip: AppStrings.tr('pickup_opt_btn'),
                onPressed: () => PlatformFeatureDialogs.showPickupAndOptimizationDialog(
                  context,
                  repo: _platformRepo,
                  token: _token,
                  canRequestChange: false,
                  canApproveChanges: true,
                  routeId: _routes.isNotEmpty ? _routes.first.id : 'f0000000-0000-0000-0000-000000000001',
                ),
              ),
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                tooltip: AppStrings.tr('routes_search_tooltip'),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadRoutes,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Card(
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
                          AppStrings.tr('route_define_heading'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newRouteController,
                          decoration: InputDecoration(
                            labelText: AppStrings.tr('route_name_hint'),
                            hintText: AppStrings.tr('route_name_hint'),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNavy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isCreating ? null : _handleCreateRoute,
                            icon: _isCreating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              AppStrings.tr('btn_define_route'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.tr('routes_search_hint'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  AppStrings.trf('routes_registered_count', {
                    'count': _routes.where((r) => _searchQuery.isEmpty || r.name.toLowerCase().contains(_searchQuery)).length,
                  }),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadRoutes,
                        child: Builder(
                          builder: (context) {
                            final filteredRoutes = _routes.where((r) =>
                                _searchQuery.isEmpty || r.name.toLowerCase().contains(_searchQuery)).toList();

                            if (filteredRoutes.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    AppStrings.tr('routes_empty_search'),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredRoutes.length,
                              itemBuilder: (ctx, index) {
                                final route = filteredRoutes[index];
                                final isDraft = route.isEditable;
                                final statusLabel = isDraft
                                    ? AppStrings.tr('route_status_draft')
                                    : AppStrings.tr('route_status_active');
                                final statusColor = isDraft ? Colors.orange : Colors.green;
                                final summaryBase = AppStrings.trf('routes_summary_line', {
                                  'stops': route.stopCount,
                                  'students': route.studentIds.length,
                                });
                                final departureText = route.departureTime != null
                                    ? AppStrings.trf('routes_departure_suffix', {'time': route.departureTime!})
                                    : '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _openRouteDetail(route.id),
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
                                                  route.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: TextStyle(
                                                    color: statusColor.shade900,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$summaryBase$departureText',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.directions_bus, size: 14, color: AppTheme.primaryNavy),
                                              const SizedBox(width: 4),
                                              Text(
                                                AppStrings.trf('routes_unit_line', {
                                                  'plate': route.vehiclePlate,
                                                  'driver': route.driverName,
                                                }),
                                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                                              ),
                                              const Spacer(),
                                              const Icon(Icons.chevron_right, color: Colors.grey),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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
