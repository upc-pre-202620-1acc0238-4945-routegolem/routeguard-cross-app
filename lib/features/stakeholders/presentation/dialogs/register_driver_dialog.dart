import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/stakeholder_repository.dart';

class RegisterDriverDialog extends StatefulWidget {
  final StakeholderRepository repository;
  final VoidCallback onRegistered;

  const RegisterDriverDialog({
    super.key,
    required this.repository,
    required this.onRegistered,
  });

  @override
  State<RegisterDriverDialog> createState() => _RegisterDriverDialogState();
}

class _RegisterDriverDialogState extends State<RegisterDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  Map<String, String>? _generatedCredentials;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await widget.repository.registerDriver(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      email: _emailController.text.trim(),
    );

    widget.onRegistered();

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _generatedCredentials = {
          'email': _emailController.text.trim(),
          'tempPassword': 'RG${DateTime.now().millisecond}#2026',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: _generatedCredentials != null
              ? _buildCredentialsView()
              : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.badge, color: AppTheme.primaryNavy),
              SizedBox(width: 8),
              Text(
                'Registrar Conductor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: 'Nombres', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _licenseController,
            decoration: const InputDecoration(labelText: 'N.º de Licencia', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
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
    );
  }

  Widget _buildCredentialsView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 48),
        const SizedBox(height: 12),
        const Text(
          '¡Conductor Registrado!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Credenciales de Acceso Provisionales:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Usuario: ${_generatedCredentials!['email']}'),
              Text('Contraseña temporal: ${_generatedCredentials!['tempPassword']}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context),
          child: const Text('Listo'),
        ),
      ],
    );
  }
}
