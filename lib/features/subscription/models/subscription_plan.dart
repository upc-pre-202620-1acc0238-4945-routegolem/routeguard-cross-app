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
    return const [
      SubscriptionPlan(
        id: 'plan_basic',
        name: 'Básico',
        description: 'Monitoreo esencial para pequeñas operaciones de transporte.',
        priceSoles: 49.99,
        billingPeriod: 'mes',
        features: [
          'Hasta 2 rutas escolares concurrentes',
          'Hasta 2 conductores registrados',
          'Monitoreo telemétrico GPS en tiempo real',
          'App para padres con red de cuidadores autorizados',
        ],
        isPopular: false,
      ),
      SubscriptionPlan(
        id: 'plan_intermediate',
        name: 'Intermedio',
        description: 'La opción recomendada para empresas de movilidad en crecimiento.',
        priceSoles: 99.99,
        billingPeriod: 'mes',
        features: [
          'Hasta 5 rutas escolares concurrentes',
          'Hasta 5 conductores registrados',
          'Monitoreo telemétrico GPS en tiempo real',
          'App para padres con red de cuidadores autorizados',
        ],
        isPopular: true,
        badgeText: 'PLAN ACTUAL',
      ),
      SubscriptionPlan(
        id: 'plan_complete',
        name: 'Completo',
        description: 'Para instituciones educativas y flotas escolares de alta demanda.',
        priceSoles: 179.99,
        billingPeriod: 'mes',
        features: [
          'Hasta 15 rutas escolares concurrentes',
          'Hasta 15 conductores registrados',
          'Monitoreo telemétrico GPS en tiempo real',
          'App para padres con red de cuidadores autorizados',
          'Soporte telefónico y WhatsApp prioritario 24/7',
        ],
        isPopular: false,
      ),
    ];
  }
}
