class StudentGroupModel {
  final String id;
  final String name;
  final bool isFinalized;
  final List<String> studentIds;

  StudentGroupModel({
    required this.id,
    required this.name,
    this.isFinalized = false,
    this.studentIds = const [],
  });

  factory StudentGroupModel.fromJson(Map<String, dynamic> json) {
    final rawIds = (json['studentIds'] ?? json['childIds'] ?? json['ChildIds']) as List<dynamic>? ?? [];
    return StudentGroupModel(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      name: json['name'] ?? json['Name'] ?? 'Grupo Escolar',
      isFinalized: json['isFinalized'] ?? json['IsFinalized'] ?? false,
      studentIds: rawIds.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isFinalized': isFinalized,
      'studentIds': studentIds,
    };
  }
}
