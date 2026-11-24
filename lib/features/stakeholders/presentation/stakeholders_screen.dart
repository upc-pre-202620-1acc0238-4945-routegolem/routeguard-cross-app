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
          // Filter Chips
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
          const Divider(height: 1),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
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
                          ..._drivers.map((drv) => _buildDriverCard(drv)),
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
                          ..._parents.map((par) => _buildParentCard(par)),
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
                          ..._groups.map((grp) => _buildGroupCard(grp)),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
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
          'Licencia: ${driver.licenseNumber} • ${driver.phone}\n${driver.email}',
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
              const Text(
                'Estudiantes a cargo:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
              ),
              const SizedBox(height: 4),
              ...parent.children.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    '• ${c.fullName} (${c.age} años) — ${c.grade}',
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
          '${group.isFinalized ? "Finalizado" : "Borrador"} • ${group.studentIds.length} estudiantes asignados',
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
