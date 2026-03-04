enum CameraStatus { online, offline, error }

class Camera {
  const Camera({
    required this.id,
    required this.zoneId,
    required this.name,
    required this.status,
    required this.streamUrl,
    required this.videoCount,
  });

  final String id;
  final String zoneId;
  final String name;
  final CameraStatus status;
  final String streamUrl;
  final int videoCount;
}
