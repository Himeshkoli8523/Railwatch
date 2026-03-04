class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.division,
    required this.camerasCount,
    required this.onlineCameras,
  });

  final String id;
  final String name;
  final String division;
  final int camerasCount;
  final int onlineCameras;
}
