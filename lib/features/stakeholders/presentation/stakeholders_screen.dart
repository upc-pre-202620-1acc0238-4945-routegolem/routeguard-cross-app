import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/stakeholder_repository.dart';
import '../models/driver_model.dart';
import '../models/parent_model.dart';
import '../models/student_group_model.dart';
import 'dialogs/create_group_dialog.dart';
import 'dialogs/register_child_dialog.dart';
import 'dialogs/register_driver_dialog.dart';
import 'dialogs/register_parent_dialog.dart';

enum StakeholderTab { drivers, parents, groups }

class StakeholdersScreen extends StatefulWidget {
  final StakeholderRepository? repository;

  const StakeholdersScreen({super.key, this.repository});

  @override
  State<StakeholdersScreen> createState() => _StakeholdersScreenState();
}

class _StakeholdersScreenState extends State<StakeholdersScreen> {
  late final StakeholderRepository _repository;
  StakeholderTab _selectedTab = StakeholderTab.drivers;
  String _searchQuery = '';

  List<DriverModel> _drivers = [];
  List<ParentModel> _parents = [];
  List<StudentGroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StakeholderRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final drivers = await _repository.getDrivers();
    final parents = await _repository.getParents();
    final groups = await _repository.getGroups();

    if (mounted) {
      setState(() {
        _drivers = drivers;
        _parents = parents;
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  void _openRegisterDriver() {
    showDialog(
      context: context,
      builder: (_) => RegisterDriverDialog(
        repository: _repository,
        onRegistered: _loadData,
      ),
    );
  }

  void _openRegisterParent() {
    showDialog(
      context: context,
      builder: (_) => RegisterParentDialog(
        repository: _repository,
        onRegistered: _loadData,
      ),
    );
  }

  void _openRegisterChild() {
    showDialog(
      context: context,
      builder: (_) => RegisterChildDialog(
        repository: _repository,
        parents: _parents,
        onRegistered: _loadData,
      ),
    );
  }

  void _openCreateGroup() {
    showDialog(
      context: context,
      builder: (_) => CreateGroupDialog(
        repository: _repository,
        parents: _parents,
        onCreated: _loadData,
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
            title: Text(AppStrings.tr('stakeholders_title')),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(AppStrings.tr('tab_drivers')),
                      selected: _selectedTab == StakeholderTab.drivers,
                      onSelected: (val) {
                        if (val) setState(() => _selectedTab = StakeholderTab.drivers);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(AppStrings.tr('tab_parents')),
                      selected: _selectedTab == StakeholderTab.parents,
                      onSelected: (val) {
                        if (val) setState(() => _selectedTab = StakeholderTab.parents);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(AppStrings.tr('tab_groups')),
                      selected: _selectedTab == StakeholderTab.groups,
                      onSelected: (val) {
                        if (val) setState(() => _selectedTab = StakeholderTab.groups);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: _selectedTab == StakeholderTab.drivers
                        ? AppStrings.tr('stakeholders_search_drivers')
                        : _selectedTab == StakeholderTab.parents
                            ? AppStrings.tr('stakeholders_search_parents')
                            : AppStrings.tr('stakeholders_search_groups'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: Builder(
                          builder: (context) {
                            final filteredDrivers = _drivers.where((d) =>
                                _searchQuery.isEmpty ||
                                d.fullName.toLowerCase().contains(_searchQuery) ||
                                d.licenseNumber.toLowerCase().contains(_searchQuery) ||
                                d.email.toLowerCase().contains(_searchQuery)).toList();

                            final filteredParents = _parents.where((p) =>
                                _searchQuery.isEmpty ||
                                p.fullName.toLowerCase().contains(_searchQuery) ||
                                p.email.toLowerCase().contains(_searchQuery) ||
                                p.children.any((c) => c.fullName.toLowerCase().contains(_searchQuery))).toList();

                            final filteredGroups = _groups.where((g) =>
                                _searchQuery.isEmpty ||
                                g.name.toLowerCase().contains(_searchQuery)).toList();

                            return ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (_selectedTab == StakeholderTab.drivers) ...[
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryNavy,
                                      side: const BorderSide(color: AppTheme.primaryNavy),
                                      minimumSize: const Size.fromHeight(46),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.person_add),
                                    label: Text(AppStrings.tr('btn_register_driver')),
                                    onPressed: _openRegisterDriver,
                                  ),
                                  const SizedBox(height: 12),
                                  if (filteredDrivers.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Text(
                                          AppStrings.tr('stakeholders_empty_drivers'),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  else
                                    ...filteredDrivers.map((drv) => _buildDriverCard(drv)),
                                ] else if (_selectedTab == StakeholderTab.parents) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.primaryNavy,
                                            side: const BorderSide(color: AppTheme.primaryNavy),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.person_add, size: 18),
                                          label: Text(AppStrings.tr('btn_register_parent'), style: const TextStyle(fontSize: 12)),
                                          onPressed: _openRegisterParent,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryNavy,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.child_care, size: 18),
                                          label: Text(AppStrings.tr('btn_register_child'), style: const TextStyle(fontSize: 12)),
                                          onPressed: _openRegisterChild,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (filteredParents.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Text(
                                          AppStrings.tr('stakeholders_empty_parents'),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  else
                                    ...filteredParents.map((par) => _buildParentCard(par)),
                                ] else ...[
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryNavy,
                                      side: const BorderSide(color: AppTheme.primaryNavy),
                                      minimumSize: const Size.fromHeight(46),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.group_add),
                                    label: Text(AppStrings.tr('btn_create_group')),
                                    onPressed: _openCreateGroup,
                                  ),
                                  const SizedBox(height: 12),
                                  if (filteredGroups.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Text(
                                          AppStrings.tr('stakeholders_empty_groups'),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  else
                                    ...filteredGroups.map((grp) => _buildGroupCard(grp)),
                                ],
                              ],
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

  Widget _buildDriverCard(DriverModel driver) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
          child: const Icon(Icons.badge, color: AppTheme.primaryNavy),
        ),
        title: Text(
          driver.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${AppStrings.trf('stakeholders_driver_license_prefix', {'license': driver.licenseNumber, 'phone': driver.phone})}\n${driver.email}',
          style: const TextStyle(fontSize: 12, height: 1.3),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Text(
            driver.vehiclePlate,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentCard(ParentModel parent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  child: const Icon(Icons.family_restroom, color: AppTheme.primaryTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parent.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${parent.email} • ${parent.phone}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (parent.children.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                AppStrings.tr('stakeholders_children_header'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
              ),
              const SizedBox(height: 4),
              ...parent.children.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    '• ${c.fullName} (${c.age} ${AppStrings.tr('common_years')}) — ${c.grade}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(StudentGroupModel group) {
    final statusStr = group.isFinalized
        ? AppStrings.tr('stakeholders_group_finalized')
        : AppStrings.tr('stakeholders_group_draft');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (group.isFinalized ? Colors.green : Colors.orange).withValues(alpha: 0.1),
          child: Icon(
            Icons.groups,
            color: group.isFinalized ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          AppStrings.trf('stakeholders_group_students_count', {
            'status': statusStr,
            'count': group.studentIds.length,
          }),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(
          group.isFinalized ? Icons.check_circle : Icons.edit_note,
          color: group.isFinalized ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
