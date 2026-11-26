import 'package:flutter/material.dart';
import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

/// Shared US-12 dialog to inspect and verify vehicle SOAT, driver license,
/// and technical inspection compliance dates.
Future<void> showVehicleDocsDialog(
  BuildContext context, {
  required String driverName,
  required String vehiclePlate,
  required String licenseNumber,
  String licenseCategory = 'A-IIIa',
  String soatPolicy = 'POL-LP-908412',
  String soatExpiry = '12/2026',
  String licenseExpiry = '08/2028',
  String techExpiry = '06/2027',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _VehicleDocsDialog(
      driverName: driverName,
      vehiclePlate: vehiclePlate,
      licenseNumber: licenseNumber,
      licenseCategory: licenseCategory,
      soatPolicy: soatPolicy,
      soatExpiry: soatExpiry,
      licenseExpiry: licenseExpiry,
      techExpiry: techExpiry,
    ),
  );
}

class _VehicleDocsDialog extends StatefulWidget {
  final String driverName;
  final String vehiclePlate;
  final String licenseNumber;
  final String licenseCategory;
  final String soatPolicy;
  final String soatExpiry;
  final String licenseExpiry;
  final String techExpiry;

  const _VehicleDocsDialog({
    required this.driverName,
    required this.vehiclePlate,
    required this.licenseNumber,
    required this.licenseCategory,
    required this.soatPolicy,
    required this.soatExpiry,
    required this.licenseExpiry,
    required this.techExpiry,
  });

  @override
  State<_VehicleDocsDialog> createState() => _VehicleDocsDialogState();
}

class _VehicleDocsDialogState extends State<_VehicleDocsDialog> {
  static const Color _emerald = Color(0xFF10B981);
  bool _verifiedNow = false;
  bool _isAllValid = true;

  bool _isExpiryValid(String mmYyyy) {
    final parts = mmYyyy.split('/');
    if (parts.length != 2) return true;
    final month = int.tryParse(parts[0]) ?? 12;
    final year = int.tryParse(parts[1]) ?? 2026;
    final lastDayOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    return !lastDayOfMonth.isBefore(DateTime.now());
  }

  void _runVerificationCheck() {
    final valid = _isExpiryValid(widget.soatExpiry) &&
        _isExpiryValid(widget.licenseExpiry) &&
        _isExpiryValid(widget.techExpiry);
    setState(() {
      _verifiedNow = true;
      _isAllValid = valid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final soatValid = _isExpiryValid(widget.soatExpiry);
    final licValid = _isExpiryValid(widget.licenseExpiry);
    final techValid = _isExpiryValid(widget.techExpiry);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user, color: AppTheme.primaryNavy, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.tr('docs_dialog_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryNavy),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, color: AppTheme.primaryNavy, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          '${AppStrings.tr('tracking_vehicle_plate_label')}: ${widget.vehiclePlate}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildDocCard(
              icon: Icons.health_and_safety_outlined,
              title: AppStrings.tr('docs_soat_title'),
              subtitle: '${AppStrings.tr('docs_policy_label')}: ${widget.soatPolicy} · La Positiva',
              expiryText: AppStrings.trf('docs_valid_until', {'date': widget.soatExpiry}),
              isValid: soatValid,
            ),
            const SizedBox(height: 8),
            _buildDocCard(
              icon: Icons.badge_outlined,
              title: '${AppStrings.tr('docs_license_title')} (${widget.licenseCategory})',
              subtitle: '${AppStrings.tr('docs_license_number')}: ${widget.licenseNumber}',
              expiryText: AppStrings.trf('docs_valid_until', {'date': widget.licenseExpiry}),
              isValid: licValid,
            ),
            const SizedBox(height: 8),
            _buildDocCard(
              icon: Icons.build_circle_outlined,
              title: AppStrings.tr('docs_tech_review_title'),
              subtitle: 'CITV-MTC · Cert. RT-2026-4419',
              expiryText: AppStrings.trf('docs_valid_until', {'date': widget.techExpiry}),
              isValid: techValid,
            ),
            if (_verifiedNow) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isAllValid ? _emerald : AppTheme.errorColor).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_isAllValid ? _emerald : AppTheme.errorColor).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAllValid ? Icons.check_circle : Icons.error_outline,
                      color: _isAllValid ? const Color(0xFF047857) : AppTheme.errorColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isAllValid
                            ? AppStrings.tr('docs_verified_ok_msg')
                            : AppStrings.tr('docs_verified_expired_msg'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isAllValid ? const Color(0xFF047857) : AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.tr('common_close')),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _emerald,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.fact_check_outlined, size: 16),
          label: Text(
            AppStrings.tr('docs_verify_now_btn'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          onPressed: _runVerificationCheck,
        ),
      ],
    );
  }

  Widget _buildDocCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String expiryText,
    required bool isValid,
  }) {
    final badgeColor = isValid ? const Color(0xFF047857) : AppTheme.errorColor;
    final badgeBg = isValid ? const Color(0xFF10B981).withValues(alpha: 0.12) : AppTheme.errorContainer;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryNavy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(expiryText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isValid ? AppStrings.tr('docs_status_valid') : AppStrings.tr('docs_status_expired'),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }
}
