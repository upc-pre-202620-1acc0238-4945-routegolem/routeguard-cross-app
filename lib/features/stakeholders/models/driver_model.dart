class DriverModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String licenseNumber;
  final String vehiclePlate;
  final String status;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    this.vehiclePlate = 'ABC-789',
    this.status = 'ACTIVE',
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      fullName: json['fullName'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      email: json['email'] ?? json['Email'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'] ?? json['PhoneNumber'] ?? '',
      licenseNumber: json['licenseNumber'] ?? json['LicenseNumber'] ?? '',
      vehiclePlate: json['vehiclePlate'] ?? json['VehiclePlate'] ?? 'ABC-789',
      status: json['status'] ?? (json['available'] == false ? 'INACTIVE' : 'ACTIVE'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'vehiclePlate': vehiclePlate,
      'status': status,
    };
  }
}
