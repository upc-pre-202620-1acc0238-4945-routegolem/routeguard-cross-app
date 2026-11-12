import 'package:flutter_test/flutter_test.dart';
import 'package:routeguard_cross_app/features/subscription/models/subscription_plan.dart';

void main() {
  group('SubscriptionPlan Model Tests', () {
    test('getAvailablePlans returns the 3 standard RouteGuard tiers', () {
      final plans = SubscriptionPlan.getAvailablePlans();

      expect(plans.length, 3);
      expect(plans[0].id, 'plan_basic');
      expect(plans[1].id, 'plan_family');
      expect(plans[2].id, 'plan_premium');
    });

    test('prices and billing periods match official institutional rates', () {
      final plans = SubscriptionPlan.getAvailablePlans();

      final basic = plans.firstWhere((p) => p.id == 'plan_basic');
      final family = plans.firstWhere((p) => p.id == 'plan_family');
      final premium = plans.firstWhere((p) => p.id == 'plan_premium');

      expect(basic.priceSoles, 49.00);
      expect(family.priceSoles, 89.00);
      expect(premium.priceSoles, 199.00);

      expect(basic.billingPeriod, 'mes');
      expect(family.billingPeriod, 'mes');
      expect(premium.billingPeriod, 'mes');
    });

    test('family plan is marked as popular with badge', () {
      final plans = SubscriptionPlan.getAvailablePlans();
      final family = plans.firstWhere((p) => p.id == 'plan_family');

      expect(family.isPopular, isTrue);
      expect(family.badgeText, 'MÁS POPULAR');
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
