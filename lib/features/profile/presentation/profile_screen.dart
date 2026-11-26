import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/platform_features_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../../subscription/presentation/subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  final SessionManager sessionManager;
  final VoidCallback onSignedOut;
  final VoidCallback? onLaunchTutorial;

  const ProfileScreen({
    super.key,
    required this.sessionManager,
    required this.onSignedOut,
    this.onLaunchTutorial,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PlatformFeaturesRepository _platformRepo = PlatformFeaturesRepository();
  String? _photoData;
  List<Map<String, Object?>> _caregivers = [];
  String _unitSummary = 'Mercedes-Benz Sprinter 416 • ABC-123';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final token = widget.sessionManager.token ?? '';
    final uid = widget.sessionManager.userId ?? 'default';
    try {
      final photo = await _platformRepo.loadMyPhoto(token, uid);
      final docs = await _platformRepo.loadPrimaryVehicleDocs(token);
      final isParent = widget.sessionManager.isParent;
      final caregivers = isParent ? await _platformRepo.getCaregivers(token) : <Map<String, Object?>>[];
      final tickets = await _platformRepo.getSupportTickets(token);
      if (tickets.isNotEmpty) {
        SessionManager.supportTicketsNotifier.value = tickets;
      }
      if (!mounted) return;
      final model = docs['model']?.toString() ?? 'Mercedes-Benz Sprinter 416';
      final plate = docs['plate']?.toString() ?? 'ABC-123';
      setState(() {
        _photoData = photo;
        _caregivers = caregivers;
        _unitSummary = '$model • $plate';
      });
    } catch (_) {}
  }

  Uint8List? _decodePhotoBytes(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final base64Str = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

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
                Text(
                  AppStrings.tr('profile_avatar_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tr('profile_avatar_subtitle'),
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
                  title: Text(AppStrings.tr('profile_avatar_camera'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(AppStrings.tr('profile_avatar_camera_desc')),
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
                        final bytes = await image.readAsBytes();
                        final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        await widget.sessionManager.setAvatarPath(image.path);
                        if (mounted) setState(() => _photoData = dataUri);
                        unawaited(_platformRepo.saveMyPhoto(
                          widget.sessionManager.token ?? '',
                          widget.sessionManager.userId ?? 'default',
                          dataUri,
                        ));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.tr('profile_avatar_camera_success')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.trf('profile_avatar_camera_error', {'error': '$e'})),
                          ),
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
                  title: Text(AppStrings.tr('profile_avatar_gallery'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(AppStrings.tr('profile_avatar_gallery_desc')),
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
                        final bytes = await image.readAsBytes();
                        final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        await widget.sessionManager.setAvatarPath(image.path);
                        if (mounted) setState(() => _photoData = dataUri);
                        unawaited(_platformRepo.saveMyPhoto(
                          widget.sessionManager.token ?? '',
                          widget.sessionManager.userId ?? 'default',
                          dataUri,
                        ));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.tr('profile_avatar_gallery_success')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.trf('profile_avatar_gallery_error', {'error': '$e'})),
                          ),
                        );
                      }
                    }
                  },
                ),
                if (widget.sessionManager.avatarPath != null || _photoData != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: Text(
                      AppStrings.tr('profile_avatar_remove'),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (mounted) setState(() => _photoData = null);
                      await widget.sessionManager.setAvatarPath(null);
                      unawaited(_platformRepo.saveMyPhoto(
                        widget.sessionManager.token ?? '',
                        widget.sessionManager.userId ?? 'default',
                        null,
                      ));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppStrings.tr('profile_avatar_removed'))),
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
              await widget.sessionManager.clearSession();
              widget.onSignedOut();
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

        final hasCustomName = widget.sessionManager.fullName.isNotEmpty &&
            widget.sessionManager.fullName != AppStrings.tr('profile_default_user');

        final displayName = hasCustomName
            ? widget.sessionManager.fullName
            : (isAdmin
                ? AppStrings.tr('profile_demo_admin_name')
                : isDriver
                    ? AppStrings.tr('profile_demo_driver_name')
                    : AppStrings.tr('profile_demo_parent_name'));

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
                              final photoBytes = _decodePhotoBytes(_photoData);
                              final hasFile = avatarPath != null && File(avatarPath).existsSync();
                              final hasValidImage = photoBytes != null || hasFile;
                              final ImageProvider? imageProvider = photoBytes != null
                                  ? MemoryImage(photoBytes)
                                  : (hasFile ? FileImage(File(avatarPath)) : null);

                              return GestureDetector(
                                onTap: () => _showAvatarPickerSheet(context),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: roleColor.withValues(alpha: 0.12),
                                      backgroundImage: imageProvider,
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
                            widget.sessionManager.email.isNotEmpty
                                ? widget.sessionManager.email
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
                            'Colegio San Juan (${widget.sessionManager.organizationId})',
                          ),
                          const SizedBox(height: 12),
                          _buildProfileRow(
                            isAdmin
                                ? Icons.domain
                                : isDriver
                                    ? Icons.directions_bus
                                    : Icons.child_care,
                            isAdmin
                                ? AppStrings.tr('profile_org_manager_label')
                                : isDriver
                                    ? AppStrings.tr('profile_assigned_unit_label')
                                    : AppStrings.tr('profile_student'),
                            isAdmin
                                ? 'Movilidades Escolares San Juan SAC'
                                : isDriver
                                    ? _unitSummary
                                    : 'Mateo Nery · Luciana Nery',
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
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.shield_outlined, color: AppTheme.primaryNavy, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AppStrings.tr('profile_caregivers_title'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppStrings.tr('profile_caregivers_badge'),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.tr('profile_caregivers_desc'),
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            if (_caregivers.isEmpty)
                              Text(
                                AppStrings.tr('profile_caregivers_empty'),
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              )
                            else
                              ..._caregivers.map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildCaregiverTile(
                                    c['id']?.toString() ?? '',
                                    c['full_name']?.toString() ?? '',
                                    c['relationship']?.toString() ?? '',
                                    c['phone_number']?.toString() ?? '',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryNavy,
                                side: const BorderSide(color: AppTheme.primaryNavy),
                                minimumSize: const Size.fromHeight(38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.person_add, size: 16),
                              label: Text(
                                AppStrings.tr('profile_caregivers_add_btn'),
                                style: const TextStyle(fontSize: 12),
                              ),
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
                              segments: [
                                ButtonSegment<String>(
                                  value: 'PARENT',
                                  icon: const Icon(Icons.family_restroom, size: 16),
                                  label: Text(AppStrings.tr('role_seg_parent'), style: const TextStyle(fontSize: 11)),
                                ),
                                ButtonSegment<String>(
                                  value: 'DRIVER',
                                  icon: const Icon(Icons.directions_bus, size: 16),
                                  label: Text(AppStrings.tr('role_seg_driver'), style: const TextStyle(fontSize: 11)),
                                ),
                                ButtonSegment<String>(
                                  value: 'ADMINISTRATOR',
                                  icon: const Icon(Icons.admin_panel_settings, size: 16),
                                  label: Text(AppStrings.tr('role_seg_admin'), style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                              selected: {normalizedRole},
                              onSelectionChanged: (newSelection) async {
                                await widget.sessionManager.setRole(newSelection.first);
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
                      onTap: widget.onLaunchTutorial,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Help & Support Card (US-18 FAQ & US-23 Support Ticket)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1.5,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.support_agent, color: Color(0xFF047857)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.tr('support_card_title'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      AppStrings.tr('support_card_subtitle'),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryNavy,
                                    side: const BorderSide(color: AppTheme.primaryNavy),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: const Icon(Icons.quiz_outlined, size: 16),
                                  label: Text(
                                    AppStrings.tr('support_faq_btn'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _showFaqDialog(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryNavy,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 42),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  ),
                                  icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                                  label: Text(
                                    AppStrings.tr('support_ticket_btn'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _showSupportTicketDialog(context),
                                ),
                              ),
                            ],
                          ),
                          ValueListenableBuilder<List<SupportTicketEntry>>(
                            valueListenable: SessionManager.supportTicketsNotifier,
                            builder: (context, tickets, _) {
                              if (tickets.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.tr('support_recent_tickets_label'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...tickets.take(3).map(
                                          (t) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    t.ticketId,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF047857),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${AppStrings.tr(t.categoryKey)} · ${t.subject}',
                                                    style: const TextStyle(fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  AppStrings.tr('support_ticket_status_submitted'),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
                          Expanded(
                            child: Row(
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.tr('language_card_title'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        currentLang == AppLanguage.spanish ? 'Español (ES)' : 'English (EN)',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                            onSelectionChanged: (newSelection) async {
                              await widget.sessionManager.setLanguage(newSelection.first);
                              unawaited(_platformRepo.syncLanguage(
                                widget.sessionManager.token ?? '',
                                AppStrings.languageCode,
                              ));
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
                      trailing: Text(
                        AppStrings.tr('profile_app_version_val'),
                        style: const TextStyle(
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

  Widget _buildCaregiverTile(String id, String name, String relation, String phone) {
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
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: () async {
            await _platformRepo.deleteCaregiver(widget.sessionManager.token ?? '', id);
            await _loadProfileData();
          },
        ),
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
        title: Row(
          children: [
            const Icon(Icons.person_add, color: AppTheme.primaryNavy),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('profile_caregiver_dialog_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: AppStrings.tr('profile_caregiver_name_label')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relationCtrl,
              decoration: InputDecoration(labelText: AppStrings.tr('profile_caregiver_relation_label')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: AppStrings.tr('profile_caregiver_phone_label')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('common_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await _platformRepo.addCaregiver(
                widget.sessionManager.token ?? '',
                name,
                relationCtrl.text.trim(),
                phoneCtrl.text.trim(),
              );
              await _loadProfileData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppStrings.trf('profile_caregiver_added_msg', {'name': name}),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(AppStrings.tr('common_save')),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    final faqPairs = const [
      ('support_faq_q1', 'support_faq_a1'),
      ('support_faq_q2', 'support_faq_a2'),
      ('support_faq_q3', 'support_faq_a3'),
      ('support_faq_q4', 'support_faq_a4'),
      ('support_faq_q5', 'support_faq_a5'),
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.quiz_outlined, color: AppTheme.primaryNavy),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.tr('support_faq_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryNavy),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: faqPairs.map((pair) {
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 10),
                  title: Text(
                    AppStrings.tr(pair.$1),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.tr(pair.$2),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('common_close')),
          ),
        ],
      ),
    );
  }

  void _showSupportTicketDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SupportTicketDialog(
        sessionManager: widget.sessionManager,
        platformRepo: _platformRepo,
        onCreated: (entry) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.trf('support_ticket_created_snack', {'id': entry.ticketId})),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _SupportTicketDialog extends StatefulWidget {
  final SessionManager sessionManager;
  final PlatformFeaturesRepository platformRepo;
  final ValueChanged<SupportTicketEntry> onCreated;

  const _SupportTicketDialog({
    required this.sessionManager,
    required this.platformRepo,
    required this.onCreated,
  });

  @override
  State<_SupportTicketDialog> createState() => _SupportTicketDialogState();
}

class _SupportTicketDialogState extends State<_SupportTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedCategory = 'support_cat_gps';

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final entry = await widget.platformRepo.createSupportTicket(
      widget.sessionManager.token ?? '',
      category: _selectedCategory,
      subject: _subjectCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
    );
    SessionManager.supportTicketsNotifier.value = [
      entry,
      ...SessionManager.supportTicketsNotifier.value.where((t) => t.ticketId != entry.ticketId),
    ];
    if (mounted) {
      Navigator.pop(context);
      widget.onCreated(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = [
      'support_cat_gps',
      'support_cat_route',
      'support_cat_billing',
      'support_cat_account',
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined, color: AppTheme.primaryNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.tr('support_ticket_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryNavy),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AppStrings.tr('support_ticket_category_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: categories
                    .map((key) => DropdownMenuItem(value: key, child: Text(AppStrings.tr(key))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.tr('support_ticket_subject_label'),
                  hintText: AppStrings.tr('support_ticket_subject_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? AppStrings.tr('common_required_field') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: AppStrings.tr('support_ticket_message_label'),
                  hintText: AppStrings.tr('support_ticket_message_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? AppStrings.tr('common_required_field') : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.tr('common_cancel')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
          ),
          onPressed: _submit,
          child: Text(AppStrings.tr('support_ticket_submit_btn')),
        ),
      ],
    );
  }
}
