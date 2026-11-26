import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
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
            children: [
              const Icon(Icons.badge, color: AppTheme.primaryNavy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.tr('driver_reg_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: AppStrings.tr('driver_reg_firstname'),
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? AppStrings.tr('common_required_field') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: AppStrings.tr('driver_reg_lastname'),
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? AppStrings.tr('common_required_field') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: AppStrings.tr('driver_reg_phone'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.isEmpty) ? AppStrings.tr('common_required_field') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _licenseController,
            decoration: InputDecoration(
              labelText: AppStrings.tr('driver_reg_license'),
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? AppStrings.tr('common_required_field') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: AppStrings.tr('driver_reg_email'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? AppStrings.tr('common_invalid_email') : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.tr('common_cancel')),
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
                    : Text(AppStrings.tr('common_register')),
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
        Text(
          AppStrings.tr('driver_reg_success'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              Text(
                AppStrings.tr('driver_reg_credentials_title'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(AppStrings.trf('driver_reg_user_prefix', {'email': _generatedCredentials!['email'] ?? ''})),
              Text(AppStrings.trf('driver_reg_temp_pass_prefix', {'password': _generatedCredentials!['tempPassword'] ?? ''})),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.tr('common_done')),
        ),
      ],
    );
  }
}
