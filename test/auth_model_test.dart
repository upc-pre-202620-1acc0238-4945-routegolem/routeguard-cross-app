import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/core/utils/session_manager.dart';
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

    test('creates UserAccount from backend AuthenticatedUserResource (roleTier, firstName, lastName)', () {
      final backendJson = {
        'id': 'usr-admin-99',
        'firstName': 'Carlos',
        'lastName': 'Mendoza',
        'email': 'admin@routeguard.pe',
        'roleTier': 'ADMINISTRATOR',
        'token': 'real-jwt-admin-token',
        'organizationId': 'org_school_01',
      };

      final account = UserAccount.fromJson(backendJson);

      expect(account.id, 'usr-admin-99');
      expect(account.fullName, 'Carlos Mendoza');
      expect(account.email, 'admin@routeguard.pe');
      expect(account.role, 'ADMINISTRATOR');
      expect(account.token, 'real-jwt-admin-token');
      expect(account.organizationId, 'org_school_01');
    });

    test('SessionManager role normalization handles case-insensitivity and shortcuts', () {
      expect(SessionManager.normalizeRole('admin'), 'ADMINISTRATOR');
      expect(SessionManager.normalizeRole('ADMINISTRATOR'), 'ADMINISTRATOR');
      expect(SessionManager.normalizeRole('driver'), 'DRIVER');
      expect(SessionManager.normalizeRole('DRIVER'), 'DRIVER');
      expect(SessionManager.normalizeRole('parent'), 'PARENT');
      expect(SessionManager.normalizeRole('PARENT'), 'PARENT');
      expect(SessionManager.normalizeRole('unknown_role'), 'PARENT');
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
