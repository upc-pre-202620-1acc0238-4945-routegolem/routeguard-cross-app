import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/features/subscription/models/subscription_plan.dart';

void main() {
  group('SubscriptionPlan Model Tests', () {
    test('getAvailablePlans returns the 3 standard RouteGuard tiers', () {
      final plans = SubscriptionPlan.getAvailablePlans();

      expect(plans.length, 3);
      expect(plans[0].id, 'plan_basic');
      expect(plans[1].id, 'plan_intermediate');
      expect(plans[2].id, 'plan_complete');
    });

    test('prices and billing periods match official institutional rates', () {
      final plans = SubscriptionPlan.getAvailablePlans();

      final basic = plans.firstWhere((p) => p.id == 'plan_basic');
      final intermediate = plans.firstWhere((p) => p.id == 'plan_intermediate');
      final complete = plans.firstWhere((p) => p.id == 'plan_complete');

      expect(basic.priceSoles, 49.99);
      expect(intermediate.priceSoles, 99.99);
      expect(complete.priceSoles, 179.99);

      expect(basic.billingPeriod, 'mes');
      expect(intermediate.billingPeriod, 'mes');
      expect(complete.billingPeriod, 'mes');
    });

    test('intermediate plan is marked as popular with badge', () {
      final plans = SubscriptionPlan.getAvailablePlans();
      final intermediate = plans.firstWhere((p) => p.id == 'plan_intermediate');

      expect(intermediate.isPopular, isTrue);
      expect(intermediate.badgeText, 'PLAN ACTUAL');
    });

    test('all plans include non-empty core features', () {
      final plans = SubscriptionPlan.getAvailablePlans();

      for (final plan in plans) {
        expect(plan.features, isNotEmpty);
        expect(plan.name, isNotEmpty);
        expect(plan.description, isNotEmpty);
      }
    });
  });
}
