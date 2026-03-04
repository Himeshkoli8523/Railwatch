class BucketItem {
  const BucketItem({
    required this.name,
    required this.videoCount,
    required this.sizeGb,
    required this.lastUpdated,
    required this.status,
  });

  final String name;
  final int videoCount;
  final double sizeGb;
  final DateTime lastUpdated;
  final BucketStatus status;
}

enum BucketStatus { active, syncing, error }
