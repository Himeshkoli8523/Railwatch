import 'package:cctv/app/app_providers.dart';
import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/core/widgets/common_widgets.dart';
import 'package:cctv/features/dashboard/domain/entities/bucket_item.dart';
import 'package:cctv/features/dashboard/domain/entities/report_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _range = '24h';

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(dashboardSummaryProvider(_range));
    final buckets = ref.watch(bucketsProvider);
    final reports = ref.watch(reportsProvider('all'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Time-range selector ──
        Row(
          children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: 6),
            const Text('Time range:'),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '1h', label: Text('1h')),
                ButtonSegment(value: '24h', label: Text('24h')),
                ButtonSegment(value: '7d', label: Text('7d')),
              ],
              selected: {_range},
              onSelectionChanged: (v) => setState(() => _range = v.first),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Top stat cards ──
        summary.when(
          loading: () => _StatCardRow(
            children: [
              _SkeletonStatCard(),
              _SkeletonStatCard(),
              _SkeletonStatCard(),
              _SkeletonStatCard(),
            ],
          ),
          error: (e, _) => _ErrorCard(message: 'Could not load summary.'),
          data: (data) => _StatCardRow(
            children: [
              _StatCard(
                icon: Icons.notifications_active_outlined,
                label: 'Active Alerts',
                value: data.activeAlerts,
                color: Colors.red.shade400,
              ),
              _StatCard(
                icon: Icons.videocam_outlined,
                label: 'Cameras Online',
                value: data.camerasOnline,
                color: Colors.green.shade500,
              ),
              _StatCard(
                icon: Icons.warning_amber_outlined,
                label: 'Defects Today',
                value: data.defectsToday,
                color: Colors.orange.shade400,
              ),
              _StatCard(
                icon: Icons.speed_outlined,
                label: 'Ingestion Rate',
                value: data.ingestionRate,
                color: Colors.blue.shade400,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Buckets ──
        _SectionHeader(
          icon: Icons.storage_outlined,
          title: 'Buckets',
          action: TextButton.icon(
            onPressed: () => ref.invalidate(bucketsProvider),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 8),
        buckets.when(
          loading: () => Column(
            children: List.generate(2, (_) => const _SkeletonBucketCard()),
          ),
          error: (e, _) => _ErrorCard(message: 'Could not load buckets.'),
          data: (items) => items.isEmpty
              ? const EmptyState(message: 'No buckets found.')
              : Column(
                  children: items.map((b) => _BucketCard(bucket: b)).toList(),
                ),
        ),
        const SizedBox(height: 24),

        // ── Recent Reports ──
        _SectionHeader(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Recent Reports',
          action: TextButton.icon(
            onPressed: () => ref.invalidate(reportsProvider('all')),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 8),
        reports.when(
          loading: () => Column(
            children: List.generate(3, (_) => const _SkeletonReportCard()),
          ),
          error: (e, _) => _ErrorCard(message: 'Could not load reports.'),
          data: (items) => items.isEmpty
              ? const EmptyState(message: 'No reports found.')
              : Column(
                  children: items.map((r) => _ReportCard(report: r)).toList(),
                ),
        ),
        const SizedBox(height: 24),

        // ── Quick Actions ──
        const _SectionHeader(icon: Icons.bolt_outlined, title: 'Quick Actions'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => ref.invalidate(bucketsProvider),
              icon: const Icon(Icons.storage_outlined),
              label: const Text('Get Buckets'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('List Videos'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.stream_outlined),
              label: const Text('Stream Video'),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ============================================================
// Helpers / Sub-widgets
// ============================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

// ── Stat cards ──────────────────────────────────────────────

class _StatCardRow extends StatelessWidget {
  const _StatCardRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 600 ? 4 : 2;
        final ratio = constraints.maxWidth > 600 ? 1.5 : 1.3;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          children: children,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonStatCard extends StatelessWidget {
  const _SkeletonStatCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 36, height: 36),
            Spacer(),
            SkeletonBox(width: 80, height: 22),
            SizedBox(height: 6),
            SkeletonBox(width: 100, height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Bucket cards ────────────────────────────────────────────

class _BucketCard extends StatelessWidget {
  const _BucketCard({required this.bucket});
  final BucketItem bucket;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel, statusIcon) = switch (bucket.status) {
      BucketStatus.active => (
        Colors.green,
        'Active',
        Icons.check_circle_outline,
      ),
      BucketStatus.syncing => (Colors.orange, 'Syncing', Icons.sync_outlined),
      BucketStatus.error => (Colors.red, 'Error', Icons.error_outline),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Storage icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.storage_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Name + metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bucket.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bucket.videoCount} videos  •  ${bucket.sizeGb.toStringAsFixed(1)} GB',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // Status chip
            Chip(
              avatar: Icon(statusIcon, size: 14, color: statusColor),
              label: Text(statusLabel),
              labelStyle: TextStyle(fontSize: 11, color: statusColor),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBucketCard extends StatelessWidget {
  const _SkeletonBucketCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SkeletonBox(width: 42, height: 42),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 100, height: 11),
                ],
              ),
            ),
            SkeletonBox(width: 70, height: 28),
          ],
        ),
      ),
    );
  }
}

// ── Report cards ────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final ReportItem report;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (report.status) {
      ReportStatus.ready => (Colors.green, 'Ready'),
      ReportStatus.processing => (Colors.orange, 'Processing'),
      ReportStatus.failed => (Colors.red, 'Failed'),
    };

    final ago = _formatAgo(report.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // PDF icon with severity color
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _severityColor(report.severity).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                color: _severityColor(report.severity),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.videoName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        report.bucketName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      Text(
                        '  ·  $ago',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: severity badge + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SeverityBadge(severity: report.severity),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(Severity s) => switch (s) {
    Severity.critical => Colors.red,
    Severity.high => Colors.deepOrange,
    Severity.medium => Colors.orange,
    Severity.low => Colors.green,
  };

  String _formatAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SkeletonReportCard extends StatelessWidget {
  const _SkeletonReportCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SkeletonBox(width: 42, height: 42),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 180, height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 11),
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 60, height: 22),
                SizedBox(height: 6),
                SkeletonBox(width: 50, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
