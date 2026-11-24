import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/stakeholder_repository.dart';
import '../../models/parent_model.dart';
import '../../models/student_model.dart';

class CreateGroupDialog extends StatefulWidget {
  final StakeholderRepository repository;
  final VoidCallback onCreated;
  final List<ParentModel> parents;

  const CreateGroupDialog({
    super.key,
    required this.repository,
    required this.onCreated,
    this.parents = const [],
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<String> _selectedStudentIds = {};
  bool _isFinalized = false;
  bool _isSubmitting = false;

  List<StudentModel> get _allChildren {
    return widget.parents.expand((p) => p.children).toList();
  }

  @override
  void initState() {
    super.initState();
    // Pre-select children if available
    for (final child in _allChildren.take(2)) {
      _selectedStudentIds.add(child.id);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final finalStudentIds = _selectedStudentIds.isNotEmpty
        ? _selectedStudentIds.toList()
        : ['stu_01', 'stu_02'];

    await widget.repository.createGroup(
      name: _nameController.text.trim(),
      studentIds: finalStudentIds,
      isFinalized: _isFinalized,
    );

    widget.onCreated();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableChildren = _allChildren;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.groups, color: AppTheme.primaryNavy),
                    SizedBox(width: 8),
                    Text(
                      'Crear Grupo Escolar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre del grupo (ej. Turno Mañana)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                if (availableChildren.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Seleccionar estudiantes:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 140),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableChildren.length,
                      itemBuilder: (ctx, i) {
                        final child = availableChildren[i];
                        final isSelected = _selectedStudentIds.contains(child.id);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(child.fullName, style: const TextStyle(fontSize: 13)),
                          subtitle: Text('${child.grade} • ${child.age} años', style: const TextStyle(fontSize: 11)),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedStudentIds.add(child.id);
                              } else {
                                _selectedStudentIds.remove(child.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Marcar como finalizado'),
                  subtitle: const Text('Los grupos finalizados pueden asignarse a rutas activas'),
                  value: _isFinalized,
                  onChanged: (val) => setState(() => _isFinalized = val),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Crear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
