import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../../subscription/presentation/subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  final SessionManager sessionManager;
  final VoidCallback onSignedOut;

  const ProfileScreen({
    super.key,
    required this.sessionManager,
    required this.onSignedOut,
  });

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppStrings.tr('profile_sign_out_confirm_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppStrings.tr('profile_sign_out_confirm_msg'),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('profile_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 40),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await sessionManager.clearSession();
              onSignedOut();
            },
            child: Text(AppStrings.tr('profile_sign_out')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = sessionManager.fullName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppStrings.currentLanguage,
      builder: (context, currentLang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.tr('profile_title')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Identity Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.12),
                        child: Text(
                          initials.isEmpty ? 'RG' : initials,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        sessionManager.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppStrings.tr('profile_role_parent'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      const Divider(height: 32),

                      // Metadata Rows
                      _buildProfileRow(
                        Icons.email_outlined,
                        AppStrings.tr('profile_email'),
                        sessionManager.email,
                      ),
                      const SizedBox(height: 12),
                      _buildProfileRow(
                        Icons.location_on_outlined,
                        AppStrings.tr('profile_institution'),
                        'Colegio San Juan (org_school_01)',
                      ),
                      const SizedBox(height: 12),
                      _buildProfileRow(
                        Icons.child_care,
                        AppStrings.tr('profile_student'),
                        'Mateo Gómez (Primaria - 4to B)',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Language Switcher Card (i18n)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.language, color: AppTheme.primaryTeal),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.tr('language_card_title'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                currentLang == AppLanguage.spanish ? 'Español (ES)' : 'English (EN)',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SegmentedButton<AppLanguage>(
                        segments: const [
                          ButtonSegment<AppLanguage>(
                            value: AppLanguage.spanish,
                            label: Text('ES', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ButtonSegment<AppLanguage>(
                            value: AppLanguage.english,
                            label: Text('EN', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        selected: {currentLang},
                        onSelectionChanged: (newSelection) {
                          AppStrings.setLanguage(newSelection.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Subscription Card (Stripe integration)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1.5,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.workspace_premium, color: AppTheme.primaryNavy),
                  ),
                  title: Text(
                    AppStrings.tr('subscription_card_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    AppStrings.tr('subscription_card_subtitle'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // App Info
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: AppTheme.primaryNavy),
                  title: Text(
                    AppStrings.tr('profile_app_version'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Text(
                    'RouteGuard Multiplataforma v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out Button (Nielsen Heuristic #4)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.exit_to_app),
                label: Text(
                  AppStrings.tr('profile_sign_out'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _confirmSignOut(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryNavy, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
