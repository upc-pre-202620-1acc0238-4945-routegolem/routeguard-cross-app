import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
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
  final _newRouteController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  List<RouteModel> _routes = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FleetRepository();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr('routes_title')),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: 'Buscar rutas',
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
        children: [
          // Header Input Card to Define New Route
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.tr('route_define_heading'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newRouteController,
                            decoration: InputDecoration(
                              hintText: AppStrings.tr('route_name_hint'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onPressed: _isCreating ? null : _handleCreateRoute,
                          child: _isCreating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(AppStrings.tr('btn_define_route')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search input for routes when toggled (RuwaLabs Heuristic #10)
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar ruta por nombre...',
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          const SizedBox(height: 8),

          // Routes List
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
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No se encontraron rutas con ese criterio.', style: TextStyle(color: Colors.grey)),
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
                                    '${route.stopCount} paradas • ${route.studentIds.length} estudiantes${route.departureTime != null ? ' • sale ${route.departureTime}' : ''}',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_bus, size: 14, color: AppTheme.primaryNavy),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Unidad: ${route.vehiclePlate} (${route.driverName})',
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
  }
}
