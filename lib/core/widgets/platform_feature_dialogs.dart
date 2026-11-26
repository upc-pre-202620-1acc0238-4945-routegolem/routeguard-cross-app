import 'package:flutter/material.dart';
import '../localization/app_strings.dart';
import '../network/platform_features_repository.dart';
import '../theme/app_theme.dart';

class PlatformFeatureDialogs {
  static void showAnnouncementsDialog(
    BuildContext context, {
    required PlatformFeaturesRepository repo,
    required String token,
    required bool canPublish,
    String? routeId,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AnnouncementsDialog(
        repo: repo,
        token: token,
        canPublish: canPublish,
        routeId: routeId,
      ),
    );
  }

  static void showChatDialog(
    BuildContext context, {
    required PlatformFeaturesRepository repo,
    required String token,
    required String userId,
    required String userName,
    required String userRole,
    String? routeId,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ChatDialog(
        repo: repo,
        token: token,
        userId: userId,
        userName: userName,
        userRole: userRole,
        routeId: routeId,
      ),
    );
  }

  static void showMaintenanceDialog(
    BuildContext context, {
    required PlatformFeaturesRepository repo,
    required String token,
    required bool canAdd,
    String defaultPlate = 'ABC-123',
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _MaintenanceDialog(
        repo: repo,
        token: token,
        canAdd: canAdd,
        defaultPlate: defaultPlate,
      ),
    );
  }

  static void showExpensesDialog(
    BuildContext context, {
    required PlatformFeaturesRepository repo,
    required String token,
    String defaultPlate = 'ABC-123',
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ExpensesDialog(
        repo: repo,
        token: token,
        defaultPlate: defaultPlate,
      ),
    );
  }

  static void showPickupAndOptimizationDialog(
    BuildContext context, {
    required PlatformFeaturesRepository repo,
    required String token,
    required bool canRequestChange,
    required bool canApproveChanges,
    String routeId = 'f0000000-0000-0000-0000-000000000001',
    String defaultChild = '',
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _PickupAndOptDialog(
        repo: repo,
        token: token,
        canRequestChange: canRequestChange,
        canApproveChanges: canApproveChanges,
        routeId: routeId,
        defaultChild: defaultChild,
      ),
    );
  }
}

class _AnnouncementsDialog extends StatefulWidget {
  final PlatformFeaturesRepository repo;
  final String token;
  final bool canPublish;
  final String? routeId;

  const _AnnouncementsDialog({
    required this.repo,
    required this.token,
    required this.canPublish,
    this.routeId,
  });

  @override
  State<_AnnouncementsDialog> createState() => _AnnouncementsDialogState();
}

class _AnnouncementsDialogState extends State<_AnnouncementsDialog> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _priority = 'NORMAL';
  List<Map<String, Object?>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await widget.repo.getAnnouncements(widget.token);
    if (mounted) setState(() { _items = rows; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppStrings.tr('announcements_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.canPublish) ...[
                TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: AppStrings.tr('announcements_field_title'))),
                const SizedBox(height: 8),
                TextField(controller: _msgCtrl, maxLines: 2, decoration: InputDecoration(labelText: AppStrings.tr('announcements_field_message'))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(AppStrings.tr('priority_normal')),
                      selected: _priority == 'NORMAL',
                      onSelected: (_) => setState(() => _priority = 'NORMAL'),
                    ),
                    ChoiceChip(
                      label: Text(AppStrings.tr('priority_important')),
                      selected: _priority == 'IMPORTANT',
                      onSelected: (_) => setState(() => _priority = 'IMPORTANT'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) return;
                    await widget.repo.publishAnnouncement(
                      widget.token,
                      title: _titleCtrl.text,
                      message: _msgCtrl.text,
                      priority: _priority,
                      routeId: widget.routeId,
                    );
                    _titleCtrl.clear();
                    _msgCtrl.clear();
                    await _load();
                  },
                  child: Text(AppStrings.tr('announcements_btn_publish')),
                ),
                const Divider(),
              ],
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else if (_items.isEmpty)
                Text(AppStrings.tr('announcements_empty'))
              else
                ..._items.map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: a['priority'] == 'IMPORTANT' ? Colors.amber.shade50 : Colors.grey.shade50,
                      child: ListTile(
                        title: Text(a['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${a['message'] ?? ''}\n${a['author_name'] ?? ''}'),
                      ),
                    )),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.tr('btn_close')))],
    );
  }
}

class _ChatDialog extends StatefulWidget {
  final PlatformFeaturesRepository repo;
  final String token;
  final String userId;
  final String userName;
  final String userRole;
  final String? routeId;

  const _ChatDialog({
    required this.repo,
    required this.token,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.routeId,
  });

  @override
  State<_ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<_ChatDialog> {
  final _ctrl = TextEditingController();
  List<Map<String, Object?>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await widget.repo.getChatMessages(widget.token, routeId: widget.routeId);
    if (mounted) setState(() { _messages = rows; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppStrings.tr('chat_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else if (_messages.isEmpty)
                Text(AppStrings.tr('chat_empty'))
              else
                ..._messages.map((m) {
                  final mine = m['sender_user_id'] == widget.userId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mine ? AppTheme.primaryNavy.withValues(alpha: 0.08) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${m['sender_name'] ?? ''} (${m['sender_role'] ?? ''})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                        const SizedBox(height: 2),
                        Text(m['message']?.toString() ?? ''),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 8),
              TextField(controller: _ctrl, decoration: InputDecoration(labelText: AppStrings.tr('chat_hint'))),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
                onPressed: () async {
                  if (_ctrl.text.trim().isEmpty) return;
                  await widget.repo.sendChatMessage(
                    widget.token,
                    senderUserId: widget.userId,
                    senderName: widget.userName,
                    senderRole: widget.userRole,
                    message: _ctrl.text,
                    routeId: widget.routeId,
                  );
                  _ctrl.clear();
                  await _load();
                },
                child: Text(AppStrings.tr('chat_send_btn')),
              ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.tr('btn_close')))],
    );
  }
}

class _MaintenanceDialog extends StatefulWidget {
  final PlatformFeaturesRepository repo;
  final String token;
  final bool canAdd;
  final String defaultPlate;

  const _MaintenanceDialog({
    required this.repo,
    required this.token,
    required this.canAdd,
    required this.defaultPlate,
  });

  @override
  State<_MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<_MaintenanceDialog> {
  late final TextEditingController _plateCtrl = TextEditingController(text: widget.defaultPlate);
  final _typeCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  List<Map<String, Object?>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await widget.repo.getMaintenances(widget.token);
    if (mounted) setState(() => _items = rows);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppStrings.tr('maintenances_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.canAdd) ...[
                TextField(controller: _plateCtrl, decoration: InputDecoration(labelText: AppStrings.tr('field_vehicle_plate'))),
                TextField(controller: _typeCtrl, decoration: InputDecoration(labelText: AppStrings.tr('maintenances_field_type'))),
                TextField(controller: _shopCtrl, decoration: InputDecoration(labelText: AppStrings.tr('maintenances_field_workshop'))),
                TextField(controller: _costCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppStrings.tr('field_cost_pen'))),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (_typeCtrl.text.trim().isEmpty) return;
                    await widget.repo.addMaintenance(
                      widget.token,
                      plate: _plateCtrl.text,
                      type: _typeCtrl.text,
                      workshop: _shopCtrl.text,
                      cost: double.tryParse(_costCtrl.text) ?? 0,
                    );
                    _typeCtrl.clear();
                    _shopCtrl.clear();
                    _costCtrl.clear();
                    await _load();
                  },
                  child: Text(AppStrings.tr('maintenances_btn_add')),
                ),
                const Divider(),
              ],
              if (_items.isEmpty)
                Text(AppStrings.tr('maintenances_empty'))
              else
                ..._items.map((m) => ListTile(
                      dense: true,
                      title: Text('${m['vehicle_plate']} · ${m['maintenance_type']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${m['workshop']} · S/ ${m['cost']} · ${m['performed_at']}'),
                    )),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.tr('btn_close')))],
    );
  }
}

class _ExpensesDialog extends StatefulWidget {
  final PlatformFeaturesRepository repo;
  final String token;
  final String defaultPlate;

  const _ExpensesDialog({required this.repo, required this.token, required this.defaultPlate});

  @override
  State<_ExpensesDialog> createState() => _ExpensesDialogState();
}

class _ExpensesDialogState extends State<_ExpensesDialog> {
  late final TextEditingController _plateCtrl = TextEditingController(text: widget.defaultPlate);
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _cat = 'FUEL';
  List<Map<String, Object?>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await widget.repo.getExpenses(widget.token);
    if (mounted) setState(() => _items = rows);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppStrings.tr('expenses_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(label: Text(AppStrings.tr('expense_cat_fuel')), selected: _cat == 'FUEL', onSelected: (_) => setState(() => _cat = 'FUEL')),
                  ChoiceChip(label: Text(AppStrings.tr('expense_cat_toll')), selected: _cat == 'TOLL', onSelected: (_) => setState(() => _cat = 'TOLL')),
                  ChoiceChip(label: Text(AppStrings.tr('expense_cat_parking')), selected: _cat == 'PARKING', onSelected: (_) => setState(() => _cat = 'PARKING')),
                ],
              ),
              TextField(controller: _plateCtrl, decoration: InputDecoration(labelText: AppStrings.tr('field_vehicle_plate'))),
              TextField(controller: _descCtrl, decoration: InputDecoration(labelText: AppStrings.tr('field_description'))),
              TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppStrings.tr('field_cost_pen'))),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
                onPressed: () async {
                  final amt = double.tryParse(_amountCtrl.text) ?? 0;
                  if (amt <= 0) return;
                  await widget.repo.addExpense(widget.token, plate: _plateCtrl.text, category: _cat, description: _descCtrl.text, amount: amt);
                  _descCtrl.clear();
                  _amountCtrl.clear();
                  await _load();
                },
                child: Text(AppStrings.tr('expenses_btn_add')),
              ),
              const Divider(),
              if (_items.isEmpty)
                Text(AppStrings.tr('expenses_empty'))
              else
                ..._items.map((e) => ListTile(
                      dense: true,
                      title: Text('${e['category']} · ${e['vehicle_plate']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${e['description']} · S/ ${e['amount']}'),
                    )),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.tr('btn_close')))],
    );
  }
}

class _PickupAndOptDialog extends StatefulWidget {
  final PlatformFeaturesRepository repo;
  final String token;
  final bool canRequestChange;
  final bool canApproveChanges;
  final String routeId;
  final String defaultChild;

  const _PickupAndOptDialog({
    required this.repo,
    required this.token,
    required this.canRequestChange,
    required this.canApproveChanges,
    required this.routeId,
    required this.defaultChild,
  });

  @override
  State<_PickupAndOptDialog> createState() => _PickupAndOptDialogState();
}

class _PickupAndOptDialogState extends State<_PickupAndOptDialog> {
  late final TextEditingController _childCtrl = TextEditingController(text: widget.defaultChild);
  final _addrCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  List<Map<String, Object?>> _requests = [];
  Map<String, dynamic>? _optimized;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reqs = await widget.repo.getPickupChanges(widget.token);
    final opt = await widget.repo.getOptimizedStops(widget.token, widget.routeId);
    if (mounted) setState(() { _requests = reqs; _optimized = opt; });
  }

  @override
  Widget build(BuildContext context) {
    final stops = (_optimized?['stops'] as List<dynamic>?)?.whereType<Map<String, dynamic>>().toList() ?? [];
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppStrings.tr('pickup_opt_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.canRequestChange) ...[
                Text(AppStrings.tr('pickup_change_section'), style: const TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: _childCtrl, decoration: InputDecoration(labelText: AppStrings.tr('pickup_field_child'))),
                TextField(controller: _addrCtrl, decoration: InputDecoration(labelText: AppStrings.tr('pickup_field_address'))),
                TextField(controller: _reasonCtrl, decoration: InputDecoration(labelText: AppStrings.tr('pickup_field_reason'))),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (_childCtrl.text.trim().isEmpty || _addrCtrl.text.trim().isEmpty) return;
                    await widget.repo.requestPickupChange(
                      widget.token,
                      childName: _childCtrl.text,
                      newAddress: _addrCtrl.text,
                      reason: _reasonCtrl.text,
                      routeId: widget.routeId,
                    );
                    _addrCtrl.clear();
                    _reasonCtrl.clear();
                    await _load();
                  },
                  child: Text(AppStrings.tr('pickup_btn_submit')),
                ),
                const Divider(),
              ],
              if (_optimized != null) ...[
                Text(
                  AppStrings.trf('opt_stops_summary', {
                    'active': _optimized!['activeStopsCount'] ?? 0,
                    'total': _optimized!['totalOriginalStops'] ?? 0,
                    'absent': (_optimized!['absentStudents'] as List?)?.length ?? 0,
                  }),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 6),
                ...stops.map((s) => ListTile(
                      dense: true,
                      title: Text('#${s['reassignedOrder'] ?? '-'} · ${s['name']}'),
                      subtitle: Text('${s['status']}'),
                    )),
                const Divider(),
              ],
              ..._requests.map((r) => Card(
                    child: ListTile(
                      title: Text('${r['child_name']} · ${r['status']}'),
                      subtitle: Text('${r['new_address']}'),
                      trailing: (widget.canApproveChanges && r['status'] == 'PENDING')
                          ? IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () async {
                                await widget.repo.reviewPickupChange(widget.token, r['id'].toString(), 'APPROVED');
                                await _load();
                              },
                            )
                          : null,
                    ),
                  )),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.tr('btn_close')))],
    );
  }
}
