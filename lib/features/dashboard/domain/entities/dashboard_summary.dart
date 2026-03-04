class DashboardSummary {
  const DashboardSummary({
    required this.activeAlerts,
    required this.camerasOnline,
    required this.defectsToday,
    required this.ingestionRate,
  });

  final String activeAlerts;
  final String camerasOnline;
  final String defectsToday;
  final String ingestionRate;
}
