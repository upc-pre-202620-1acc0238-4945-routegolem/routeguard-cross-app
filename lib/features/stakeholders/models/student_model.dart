class StudentModel {
  final String id;
  final String fullName;
  final int age;
  final String grade;
  final String pickupAddress;
  final String dropoffAddress;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.age,
    this.grade = 'Primaria',
    this.pickupAddress = 'Av. Javier Prado 2450',
    this.dropoffAddress = 'Colegio San Juan',
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '10') ?? 10,
      grade: json['grade'] ?? 'Primaria',
      pickupAddress: json['pickupAddress'] ?? 'Av. Javier Prado 2450',
      dropoffAddress: json['dropoffAddress'] ?? 'Colegio San Juan',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'grade': grade,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
    };
  }
}
