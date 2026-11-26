import '../../../core/localization/app_strings.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double priceSoles;
  final String billingPeriod;
  final List<String> features;
  final bool isPopular;
  final String badgeText;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceSoles,
    required this.billingPeriod,
    required this.features,
    this.isPopular = false,
    this.badgeText = '',
  });

  static List<SubscriptionPlan> getAvailablePlans() {
    return [
      SubscriptionPlan(
        id: 'plan_basic',
        name: AppStrings.tr('plans_basic_name'),
        description: AppStrings.tr('plans_basic_desc'),
        priceSoles: 49.99,
        billingPeriod: AppStrings.tr('plans_billing_period_month'),
        features: [
          AppStrings.tr('plans_basic_feat_1'),
          AppStrings.tr('plans_basic_feat_2'),
          AppStrings.tr('plans_basic_feat_3'),
          AppStrings.tr('plans_basic_feat_4'),
        ],
        isPopular: false,
      ),
      SubscriptionPlan(
        id: 'plan_intermediate',
        name: AppStrings.tr('plans_inter_name'),
        description: AppStrings.tr('plans_inter_desc'),
        priceSoles: 99.99,
        billingPeriod: AppStrings.tr('plans_billing_period_month'),
        features: [
          AppStrings.tr('plans_inter_feat_1'),
          AppStrings.tr('plans_inter_feat_2'),
          AppStrings.tr('plans_inter_feat_3'),
          AppStrings.tr('plans_inter_feat_4'),
        ],
        isPopular: true,
        badgeText: AppStrings.tr('plans_current_badge_upper'),
      ),
      SubscriptionPlan(
        id: 'plan_complete',
        name: AppStrings.tr('plans_complete_name'),
        description: AppStrings.tr('plans_complete_desc'),
        priceSoles: 179.99,
        billingPeriod: AppStrings.tr('plans_billing_period_month'),
        features: [
          AppStrings.tr('plans_complete_feat_1'),
          AppStrings.tr('plans_complete_feat_2'),
          AppStrings.tr('plans_complete_feat_3'),
          AppStrings.tr('plans_complete_feat_4'),
          AppStrings.tr('plans_complete_feat_5'),
        ],
        isPopular: false,
      ),
    ];
  }
}
