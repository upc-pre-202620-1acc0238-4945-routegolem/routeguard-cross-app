import 'student_model.dart';

class ParentModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final List<StudentModel> children;

  ParentModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.children = const [],
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = (json['children'] ?? json['Children']) as List<dynamic>? ?? [];
    return ParentModel(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      fullName: json['fullName'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      email: json['email'] ?? json['Email'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'] ?? json['PhoneNumber'] ?? '',
      children: rawChildren
          .map((c) => StudentModel.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}
