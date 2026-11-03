import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/features/auth/models/user_account.dart';

void main() {
  group('UserAccount Model Test', () {
    test('creates UserAccount from valid json', () {
      final json = {
        'id': 'usr-123',
        'fullName': 'Laura Gómez',
        'email': 'parent@routeguard.pe',
        'role': 'PARENT',
        'token': 'mock-jwt-token',
        'organizationId': 'org_school_01',
      };

      final account = UserAccount.fromJson(json);

      expect(account.id, 'usr-123');
      expect(account.fullName, 'Laura Gómez');
      expect(account.email, 'parent@routeguard.pe');
      expect(account.role, 'PARENT');
      expect(account.token, 'mock-jwt-token');
      expect(account.organizationId, 'org_school_01');
    });

    test('serializes UserAccount to json correctly', () {
      final account = UserAccount(
        id: 'usr-123',
        fullName: 'Laura Gómez',
        email: 'parent@routeguard.pe',
        role: 'PARENT',
        token: 'mock-jwt-token',
        organizationId: 'org_school_01',
      );

      final json = account.toJson();

      expect(json['id'], 'usr-123');
      expect(json['fullName'], 'Laura Gómez');
      expect(json['role'], 'PARENT');
    });
  });
}
