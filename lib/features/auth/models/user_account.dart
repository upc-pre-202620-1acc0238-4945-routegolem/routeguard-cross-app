import '../../../core/utils/session_manager.dart';

class UserAccount {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String token;
  final String organizationId;

  UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
    required this.organizationId,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] ?? json['roleTier'] ?? json['RoleTier'])?.toString() ?? 'PARENT';
    final firstName = (json['firstName'] ?? json['FirstName'] ?? '').toString().trim();
    final lastName = (json['lastName'] ?? json['LastName'] ?? '').toString().trim();
    final combinedName = '$firstName $lastName'.trim();

    return UserAccount(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      fullName: json['fullName'] ??
          (combinedName.isNotEmpty ? combinedName : null) ??
          json['name'] ??
          'Usuario RouteGuard',
      email: json['email'] ?? json['Email'] ?? '',
      role: SessionManager.normalizeRole(rawRole),
      token: json['token'] ?? json['Token'] ?? '',
      organizationId: (json['organizationId'] ?? json['OrganizationId'])?.toString() ?? 'org_school_01',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'roleTier': role,
      'token': token,
      'organizationId': organizationId,
    };
  }
}
