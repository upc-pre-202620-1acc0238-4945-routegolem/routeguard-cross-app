import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/driver_model.dart';
import '../models/parent_model.dart';
import '../models/student_group_model.dart';
import '../models/student_model.dart';

class StakeholderRepository {
  final http.Client _client;

  // Local state cache so new registrations immediately appear in the UI
  static final List<DriverModel> _mockDrivers = [
    DriverModel(
      id: 'drv_01',
      fullName: 'Carlos Ramírez',
      email: 'driver@routeguard.pe',
      phone: '+51 987 654 321',
      licenseNumber: 'Q-12345678',
      vehiclePlate: 'ABC-789',
    ),
    DriverModel(
      id: 'drv_02',
      fullName: 'Luis Johnny Salazar',
      email: 'luis.salazar@routeguard.pe',
      phone: '+51 912 345 678',
      licenseNumber: 'Q-87654321',
      vehiclePlate: 'DEF-456',
    ),
  ];

  static final List<ParentModel> _mockParents = [
    ParentModel(
      id: 'par_01',
      fullName: 'Laura Gómez',
      email: 'parent@routeguard.pe',
      phone: '+51 999 111 222',
      children: [
        StudentModel(
          id: 'stu_01',
          fullName: 'Mateo Gómez',
          age: 9,
          grade: '4to Primaria',
          pickupAddress: 'Av. Javier Prado Este 2450',
          dropoffAddress: 'Colegio San Juan',
        ),
      ],
    ),
    ParentModel(
      id: 'par_02',
      fullName: 'Roberto Nery',
      email: 'roberto.nery@routeguard.pe',
      phone: '+51 998 887 766',
      children: [
        StudentModel(
          id: 'stu_02',
          fullName: 'Luciana Nery',
          age: 10,
          grade: '5to Primaria',
          pickupAddress: 'Calle Las Flores 320',
          dropoffAddress: 'Colegio San Juan',
        ),
        StudentModel(
          id: 'stu_03',
          fullName: 'Joaquín Nery',
          age: 7,
          grade: '2do Primaria',
          pickupAddress: 'Calle Las Flores 320',
          dropoffAddress: 'Colegio San Juan',
        ),
      ],
    ),
  ];

  static final List<StudentGroupModel> _mockGroups = [
    StudentGroupModel(
      id: 'grp_01',
      name: 'Grupo Primaria Sur',
      isFinalized: true,
      studentIds: ['stu_01', 'stu_02'],
    ),
    StudentGroupModel(
      id: 'grp_02',
      name: 'Grupo Mañana Miraflores',
      isFinalized: false,
      studentIds: ['stu_03'],
    ),
  ];

  StakeholderRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<DriverModel>> getDrivers([String token = '']) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DriverModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return List.unmodifiable(_mockDrivers);
  }

  Future<List<ParentModel>> getParents([String token = '']) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.parentsEndpoint}');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ParentModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return List.unmodifiable(_mockParents);
  }

  Future<List<StudentGroupModel>> getGroups([String token = '']) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.studentGroupsEndpoint}');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StudentGroupModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return List.unmodifiable(_mockGroups);
  }

  Future<DriverModel> registerDriver({
    required String firstName,
    required String lastName,
    required String phone,
    required String licenseNumber,
    required String email,
    String token = '',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phone,
          'licenseNumber': licenseNumber,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final driver = DriverModel.fromJson(data);
        _mockDrivers.add(driver);
        return driver;
      }
    } catch (_) {}

    final newDriver = DriverModel(
      id: 'drv_${DateTime.now().millisecondsSinceEpoch}',
      fullName: '$firstName $lastName'.trim(),
      email: email,
      phone: phone,
      licenseNumber: licenseNumber,
    );
    _mockDrivers.add(newDriver);
    return newDriver;
  }

  Future<ParentModel> registerParent({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String token = '',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.parentsEndpoint}');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phone,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final parent = ParentModel.fromJson(data);
        _mockParents.add(parent);
        return parent;
      }
    } catch (_) {}

    final newParent = ParentModel(
      id: 'par_${DateTime.now().millisecondsSinceEpoch}',
      fullName: '$firstName $lastName'.trim(),
      email: email,
      phone: phone,
      children: [],
    );
    _mockParents.add(newParent);
    return newParent;
  }

  Future<StudentModel> registerChild({
    required String parentId,
    required String fullName,
    required int age,
    String pickupAddress = '',
    String dropoffAddress = '',
    String token = '',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.parentsEndpoint}/$parentId/children');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName,
          'age': age,
          'pickupAddress': pickupAddress,
          'dropoffAddress': dropoffAddress,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final student = StudentModel.fromJson(data);
        _attachChildToParent(parentId, student);
        return student;
      }
    } catch (_) {}

    final newStudent = StudentModel(
      id: 'stu_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      age: age,
      pickupAddress: pickupAddress.isEmpty ? 'Av. Javier Prado 2450' : pickupAddress,
      dropoffAddress: dropoffAddress.isEmpty ? 'Colegio San Juan' : dropoffAddress,
    );

    _attachChildToParent(parentId, newStudent);
    return newStudent;
  }

  void _attachChildToParent(String parentId, StudentModel newStudent) {
    final parentIndex = _mockParents.indexWhere((p) => p.id == parentId);
    if (parentIndex != -1) {
      final parent = _mockParents[parentIndex];
      _mockParents[parentIndex] = ParentModel(
        id: parent.id,
        fullName: parent.fullName,
        email: parent.email,
        phone: parent.phone,
        children: [...parent.children, newStudent],
      );
    } else if (_mockParents.isNotEmpty) {
      final first = _mockParents.first;
      _mockParents[0] = ParentModel(
        id: first.id,
        fullName: first.fullName,
        email: first.email,
        phone: first.phone,
        children: [...first.children, newStudent],
      );
    }
  }

  Future<StudentGroupModel> createGroup({
    required String name,
    required List<String> studentIds,
    bool isFinalized = false,
    String token = '',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.studentGroupsEndpoint}');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'childIds': studentIds,
          'isFinalized': isFinalized,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final group = StudentGroupModel.fromJson(data);
        _mockGroups.add(group);
        return group;
      }
    } catch (_) {}

    final newGroup = StudentGroupModel(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isFinalized: isFinalized,
      studentIds: studentIds,
    );
    _mockGroups.add(newGroup);
    return newGroup;
  }
}
