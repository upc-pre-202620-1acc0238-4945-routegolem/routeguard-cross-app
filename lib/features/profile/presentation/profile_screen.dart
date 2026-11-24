import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../../subscription/presentation/subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  final SessionManager sessionManager;
  final VoidCallback onSignedOut;
  final VoidCallback? onLaunchTutorial;

  const ProfileScreen({
    super.key,
    required this.sessionManager,
    required this.onSignedOut,
    this.onLaunchTutorial,
  });

  void _showAvatarPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Foto de Perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecciona una opción para actualizar la imagen de tu cuenta:',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryNavy),
                  ),
                  title: const Text('Tomar foto con la cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Captura una nueva fotografía instantánea'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        await sessionManager.setAvatarPath(image.path);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Foto de perfil actualizada desde la cámara!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo acceder a la cámara: $e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Colors.teal),
                  ),
                  title: const Text('Elegir de la galería o archivos', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Selecciona una imagen guardada en tu dispositivo'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        await sessionManager.setAvatarPath(image.path);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Foto de perfil seleccionada de archivos exitosamente!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo acceder a los archivos: $e')),
                        );
                      }
                    }
                  },
                ),
                if (sessionManager.avatarPath != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text('Eliminar foto / Restablecer iniciales',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await sessionManager.setAvatarPath(null);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Foto de perfil eliminada.')),
                        );
                      }
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

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
    return ValueListenableBuilder<String>(
      valueListenable: SessionManager.activeRoleNotifier,
      builder: (context, activeRole, _) {
        final normalizedRole = SessionManager.normalizeRole(activeRole);
        final isAdmin = normalizedRole == 'ADMINISTRATOR';
        final isDriver = normalizedRole == 'DRIVER';

        final roleLabel = isAdmin
            ? AppStrings.tr('profile_role_admin')
            : isDriver
                ? AppStrings.tr('profile_role_driver')
                : AppStrings.tr('profile_role_parent');

        final roleColor = isAdmin
            ? Colors.indigo
            : isDriver
                ? Colors.orange
                : AppTheme.primaryNavy;

        final hasCustomName = sessionManager.fullName.isNotEmpty &&
            sessionManager.fullName != 'Usuario RouteGuard';

        final displayName = hasCustomName
            ? sessionManager.fullName
            : (isAdmin
                ? 'Carlos Mendoza (Admin)'
                : isDriver
                    ? 'Carlos Ramírez (Chofer)'
                    : 'Laura Gómez (Apoderada)');

        final initials = displayName
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
                          ValueListenableBuilder<String?>(
                            valueListenable: SessionManager.avatarPathNotifier,
                            builder: (context, avatarPath, _) {
                              final hasValidImage = avatarPath != null && File(avatarPath).existsSync();

                              return GestureDetector(
                                onTap: () => _showAvatarPickerSheet(context),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: roleColor.withValues(alpha: 0.12),
                                      backgroundImage: hasValidImage ? FileImage(File(avatarPath)) : null,
                                      child: hasValidImage
                                          ? null
                                          : Text(
                                              initials.isEmpty ? 'RG' : initials,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: roleColor,
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryNavy,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Text(
                            displayName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                          const Divider(height: 32),

                          // Metadata Rows
                          _buildProfileRow(
                            Icons.email_outlined,
                            AppStrings.tr('profile_email'),
                            sessionManager.email.isNotEmpty
                                ? sessionManager.email
                                : (isAdmin
                                    ? 'admin@routeguard.pe'
                                    : isDriver
                                        ? 'driver@routeguard.pe'
                                        : 'parent@routeguard.pe'),
                          ),
                          const SizedBox(height: 12),
                          _buildProfileRow(
                            Icons.location_on_outlined,
                            AppStrings.tr('profile_institution'),
                            'Colegio San Juan (${sessionManager.organizationId})',
                          ),
                          const SizedBox(height: 12),
                          _buildProfileRow(
                            isAdmin
                                ? Icons.domain
                                : isDriver
                                    ? Icons.directions_bus
                                    : Icons.child_care,
                            isAdmin
                                ? 'Organización gestora'
                                : isDriver
                                    ? 'Unidad móvil asignada'
                                    : AppStrings.tr('profile_student'),
                            isAdmin
                                ? 'Movilidades Escolares San Juan SAC'
                                : isDriver
                                    ? 'Mercedes-Benz Sprinter • ABC-789'
                                    : 'Mateo Gómez (Primaria - 4to B)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Authorized Caregivers Card for Parents (V-01 Doña Carmen recommendation)
                  if (!isAdmin && !isDriver) ...[
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1.5,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.shield_outlined, color: AppTheme.primaryNavy, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cuidadores Autorizados',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Red Familiar',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cuidadores autorizados para entrega, recepción y monitoreo en vivo con alertas:',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            _buildCaregiverTile('Carmen López de Aljovín', 'Abuela / Cuidadora principal', '987-123-456'),
                            const Divider(height: 12),
                            _buildCaregiverTile('Laura Gómez', 'Madre / Apoderada titular', '999-888-777'),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryNavy,
                                side: const BorderSide(color: AppTheme.primaryNavy),
                                minimumSize: const Size.fromHeight(38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.person_add, size: 16),
                              label: const Text('Agregar cuidador autorizado', style: TextStyle(fontSize: 12)),
                              onPressed: () => _showAddCaregiverDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Mode Switcher Card (Role Toggle for all 3 users: Parent, Driver, Admin)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.swap_horiz, color: AppTheme.primaryNavy),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.tr('driver_mode_toggle'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      isAdmin
                                          ? AppStrings.tr('driver_mode_admin')
                                          : isDriver
                                              ? AppStrings.tr('driver_mode_driver')
                                              : AppStrings.tr('driver_mode_parent'),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment<String>(
                                  value: 'PARENT',
                                  icon: Icon(Icons.family_restroom, size: 16),
                                  label: Text('Apoderado', style: TextStyle(fontSize: 11)),
                                ),
                                ButtonSegment<String>(
                                  value: 'DRIVER',
                                  icon: Icon(Icons.directions_bus, size: 16),
                                  label: Text('Conductor', style: TextStyle(fontSize: 11)),
                                ),
                                ButtonSegment<String>(
                                  value: 'ADMINISTRATOR',
                                  icon: Icon(Icons.admin_panel_settings, size: 16),
                                  label: Text('Admin / Dueño', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                              selected: {normalizedRole},
                              onSelectionChanged: (newSelection) async {
                                await sessionManager.setRole(newSelection.first);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Assistant Mascot Guide Launcher Card
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
                        child: const Icon(Icons.help_outline, color: AppTheme.primaryNavy),
                      ),
                      title: Text(
                        AppStrings.tr('profile_guide_action'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        AppStrings.tr('profile_guide_desc'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: onLaunchTutorial,
                    ),
                  ),
                  const SizedBox(height: 12),

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

                  // Sign Out Button
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

  Widget _buildCaregiverTile(String name, String relation, String phone) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
          child: const Icon(Icons.person, size: 16, color: AppTheme.primaryNavy),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('$relation · $phone', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
        const Icon(Icons.verified, size: 16, color: Colors.green),
      ],
    );
  }

  void _showAddCaregiverDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: AppTheme.primaryNavy),
            SizedBox(width: 8),
            Text('Nuevo Cuidador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del familiar / cuidador'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relationCtrl,
              decoration: const InputDecoration(labelText: 'Parentesco (ej. Abuela, Tío, Papá)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Número celular para alertas SMS/Push'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('¡Cuidador ${nameCtrl.text} agregado a la red familiar con acceso a alertas!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
