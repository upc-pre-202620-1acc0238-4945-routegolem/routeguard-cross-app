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
    return UserAccount(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? json['name'] ?? 'Usuario RouteGuard',
      email: json['email'] ?? '',
      role: (json['role'] ?? 'PARENT').toString().toUpperCase(),
      token: json['token'] ?? '',
      organizationId: json['organizationId']?.toString() ?? 'org_school_01',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'token': token,
      'organizationId': organizationId,
    };
  }
}
