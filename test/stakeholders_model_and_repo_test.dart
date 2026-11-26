import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:routeguard_cross_app/features/stakeholders/data/stakeholder_repository.dart';
import 'package:routeguard_cross_app/features/stakeholders/models/driver_model.dart';
import 'package:routeguard_cross_app/features/stakeholders/models/parent_model.dart';
import 'package:routeguard_cross_app/features/stakeholders/models/student_group_model.dart';
import 'package:routeguard_cross_app/features/stakeholders/models/student_model.dart';

void main() {
  group('Stakeholder Models & Repository Tests', () {
    test('DriverModel JSON serialization and deserialization', () {
      final json = {
        'id': 'drv_99',
        'fullName': 'Alejandro Toledo',
        'email': 'at@routeguard.pe',
        'phone': '987654321',
        'licenseNumber': 'Q-99887766',
        'vehiclePlate': 'XYZ-999',
        'status': 'ACTIVE',
      };

      final driver = DriverModel.fromJson(json);
      expect(driver.id, 'drv_99');
      expect(driver.fullName, 'Alejandro Toledo');
      expect(driver.vehiclePlate, 'XYZ-999');

      final serialized = driver.toJson();
      expect(serialized['licenseNumber'], 'Q-99887766');
    });

    test('StudentModel JSON fallback and parsing', () {
      final json = {
        'id': 'stu_88',
        'firstName': 'Lucas',
        'lastName': 'Paz',
        'age': 9,
      };

      final student = StudentModel.fromJson(json);
      expect(student.fullName, 'Lucas Paz');
      expect(student.age, 9);
      expect(student.pickupAddress, 'Av. Javier Prado 2450');
      expect(student.dropoffAddress, 'Colegio San Juan');
    });

    test('ParentModel with children JSON serialization', () {
      final json = {
        'id': 'par_77',
        'fullName': 'María Delgado',
        'email': 'maria@delgado.pe',
        'phone': '911222333',
        'children': [
          {'id': 'stu_01', 'fullName': 'Joaquín Delgado', 'age': 8},
        ],
      };

      final parent = ParentModel.fromJson(json);
      expect(parent.fullName, 'María Delgado');
      expect(parent.children.length, 1);
      expect(parent.children.first.fullName, 'Joaquín Delgado');

      final serialized = parent.toJson();
      expect((serialized['children'] as List).length, 1);
    });

    test('StudentGroupModel JSON serialization and backend childIds parsing', () {
      final json = {
        'id': 'grp_55',
        'name': 'Grupo B Miraflores',
        'isFinalized': true,
        'studentIds': ['stu_01', 'stu_02'],
      };

      final group = StudentGroupModel.fromJson(json);
      expect(group.name, 'Grupo B Miraflores');
      expect(group.isFinalized, isTrue);
      expect(group.studentIds.length, 2);

      // Backend childIds format
      final backendGroup = StudentGroupModel.fromJson({
        'id': 'grp_backend_99',
        'name': 'Grupo C Surco',
        'childIds': ['c-1', 'c-2', 'c-3'],
        'isFinalized': true,
      });
      expect(backendGroup.studentIds.length, 3);
      expect(backendGroup.studentIds.first, 'c-1');
    });

    test('DriverModel and ParentModel parse backend phoneNumber', () {
      final driver = DriverModel.fromJson({
        'id': 'drv_bk',
        'firstName': 'Carlos',
        'lastName': 'Ramírez',
        'email': 'carlos@routeguard.pe',
        'phoneNumber': '+51 987 654 321',
        'licenseNumber': 'Q-12345678',
        'available': true,
      });
      expect(driver.phone, '+51 987 654 321');
      expect(driver.fullName, 'Carlos Ramírez');
      expect(driver.status, 'ACTIVE');

      final parent = ParentModel.fromJson({
        'id': 'par_bk',
        'firstName': 'Laura',
        'lastName': 'Gómez',
        'email': 'laura@routeguard.pe',
        'phoneNumber': '+51 999 111 222',
        'children': [],
      });
      expect(parent.phone, '+51 999 111 222');
      expect(parent.fullName, 'Laura Gómez');
    });

    test('StakeholderRepository CRUD operations in offline fallback mode', () async {
      final repo = StakeholderRepository(
        client: MockClient((_) async => http.Response('offline', 503)),
      );

      final drivers = await repo.getDrivers();
      expect(drivers.length, greaterThanOrEqualTo(2));

      final parents = await repo.getParents();
      expect(parents.length, greaterThanOrEqualTo(2));

      final groups = await repo.getGroups();
      expect(groups.length, greaterThanOrEqualTo(2));

      // Register new driver
      final newDrv = await repo.registerDriver(
        firstName: 'Raúl',
        lastName: 'Gómez',
        phone: '955443322',
        licenseNumber: 'Q-55667788',
        email: 'raul.gomez@routeguard.pe',
      );
      expect(newDrv.fullName, 'Raúl Gómez');
      final updatedDrivers = await repo.getDrivers();
      expect(updatedDrivers.any((d) => d.id == newDrv.id), isTrue);

      // Register new parent & child
      final newParent = await repo.registerParent(
        firstName: 'Elena',
        lastName: 'Mori',
        phone: '933221100',
        email: 'elena.mori@gmail.com',
      );
      expect(newParent.fullName, 'Elena Mori');

      final newStudent = await repo.registerChild(
        parentId: newParent.id,
        fullName: 'Thiago Mori',
        age: 7,
      );
      expect(newStudent.fullName, 'Thiago Mori');

      // Create group
      final newGroup = await repo.createGroup(
        name: 'Grupo Tardes',
        studentIds: [newStudent.id],
        isFinalized: false,
      );
      expect(newGroup.name, 'Grupo Tardes');
      expect(newGroup.isFinalized, isFalse);
    });
  });
}
