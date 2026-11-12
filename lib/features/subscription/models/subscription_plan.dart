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
        name: 'Plan Básico',
        description: 'Monitoreo esencial para 1 estudiante.',
        priceSoles: 49.00,
        billingPeriod: 'mes',
        features: [
          'GPS en vivo durante el recorrido escolar',
          'Notificaciones de abordaje y llegada',
          '1 estudiante vinculado',
          'Soporte por correo electrónico',
        ],
        isPopular: false,
      ),
      SubscriptionPlan(
        id: 'plan_family',
        name: 'Plan Familiar',
        description: 'La opción recomendada para familias con varios hijos.',
        priceSoles: 89.00,
        billingPeriod: 'mes',
        features: [
          'Monitoreo GPS en tiempo real prioritario',
          'Hasta 3 estudiantes vinculados',
          'Alertas instantáneas de velocidad y contingencias',
          'Geofencing de proximidad (500m)',
          'Soporte telefónico y WhatsApp prioritario',
        ],
        isPopular: true,
        badgeText: 'MÁS POPULAR',
      ),
      SubscriptionPlan(
        id: 'plan_premium',
        name: 'Plan Institucional',
        description: 'Para colegios y empresas de transporte escolar.',
        priceSoles: 199.00,
        billingPeriod: 'mes',
        features: [
          'Estudiantes ilimitados por movilidad',
          'Reportes mensuales de puntualidad y asistencia',
          'Panel web y móvil sincronizado',
          'Pasarela de pagos Stripe automatizada',
          'Soporte dedicado 24/7',
        ],
        isPopular: false,
      ),
    ];
  }
}
