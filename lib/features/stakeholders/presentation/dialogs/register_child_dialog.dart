import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/stakeholder_repository.dart';
import '../../models/parent_model.dart';

class RegisterChildDialog extends StatefulWidget {
  final StakeholderRepository repository;
  final List<ParentModel> parents;
  final VoidCallback onRegistered;

  const RegisterChildDialog({
    super.key,
    required this.repository,
    required this.parents,
    required this.onRegistered,
  });

  @override
  State<RegisterChildDialog> createState() => _RegisterChildDialogState();
}

class _RegisterChildDialogState extends State<RegisterChildDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '8');
  final _pickupController = TextEditingController(text: 'Av. Javier Prado Este 2450');
  final _dropoffController = TextEditingController(text: 'Colegio San Juan');

  String? _selectedParentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.parents.isNotEmpty) {
      _selectedParentId = widget.parents.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParentId == null && widget.parents.isNotEmpty) {
      _selectedParentId = widget.parents.first.id;
    }

    setState(() => _isSubmitting = true);

    await widget.repository.registerChild(
      parentId: _selectedParentId ?? 'par_01',
      fullName: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 8,
      pickupAddress: _pickupController.text.trim(),
      dropoffAddress: _dropoffController.text.trim(),
    );

    widget.onRegistered();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Icon(Icons.child_care, color: AppTheme.primaryNavy),
                    SizedBox(width: 8),
                    Text(
                      'Registrar Estudiante',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.parents.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedParentId,
                    decoration: const InputDecoration(labelText: 'Apoderado responsable', border: OutlineInputBorder()),
                    items: widget.parents.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.fullName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedParentId = val);
                    },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre y Apellidos del alumno', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Edad (años)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pickupController,
                  decoration: const InputDecoration(labelText: 'Dirección de recojo', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dropoffController,
                  decoration: const InputDecoration(labelText: 'Dirección de destino escolar', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
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
                          : const Text('Registrar'),
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
