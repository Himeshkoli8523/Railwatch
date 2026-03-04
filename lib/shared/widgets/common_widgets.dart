import 'package:cctv/shared/models/app_models.dart';
import 'package:flutter/material.dart';

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});

  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      Severity.critical => Colors.red,
      Severity.high => Colors.orange,
      Severity.medium => Colors.blue,
      Severity.low => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 8});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.lastSync,
    required this.onSyncQueueTap,
  });

  final DateTime? lastSync;
  final VoidCallback onSyncQueueTap;

  @override
  Widget build(BuildContext context) {
    final timestamp =
        lastSync?.toLocal().toIso8601String().substring(11, 19) ?? '--:--:--';
    return Material(
      color: Colors.amber.shade100,
      child: ListTile(
        minTileHeight: 44,
        title: const Text('Offline. Read-only fallback enabled.'),
        subtitle: Text('Last sync: $timestamp'),
        trailing: TextButton(
          onPressed: onSyncQueueTap,
          child: const Text('Sync queue'),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
