import 'package:cctv/shared/models/app_models.dart';
import 'package:cctv/shared/state/global_providers.dart';
import 'package:cctv/shared/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final List<AlertItem> _feed = [];
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    ref.listen(alertsFeedProvider, (_, next) {
      final alert = next.value;
      if (alert == null) return;
      setState(() {
        _feed.insert(0, alert);
        if (_feed.length > 100) _feed.removeLast();
      });
    });

    final connection = ref.watch(connectionProvider);
    final visible = _feed
        .where((item) => _filter == 'all' || item.severity.name == _filter)
        .toList();

    return Column(
      children: [
        if (connection.isReconnecting)
          Material(
            color: Colors.blue.shade50,
            child: ListTile(
              minTileHeight: 44,
              title: const Text('Reconnecting to alert stream...'),
              trailing: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DropdownButton<String>(
                value: _filter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) => setState(() => _filter = value ?? 'all'),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  ref.read(connectionProvider.notifier).setReconnecting(true);
                  await Future<void>.delayed(const Duration(seconds: 2));
                  ref.read(connectionProvider.notifier).setReconnecting(false);
                },
                child: const Text('Reconnect'),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const EmptyState(
                  message: 'No alerts yet. Stream is waiting for messages.',
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        minTileHeight: 64,
                        leading: Semantics(
                          label: 'Alert snapshot',
                          child: Image.network(
                            item.snapshotUrl,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(item.detectionType)),
                            SeverityBadge(severity: item.severity),
                          ],
                        ),
                        subtitle: Text(
                          'Confidence ${(item.confidence * 100).toStringAsFixed(1)}% • ${item.timestamp.toLocal()}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Dedup ${item.dedupGroup}'),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () => _openDetail(item),
                              child: const Text('Details'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openDetail(AlertItem alert) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alert ${alert.id}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Image.network(
                alert.snapshotUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 140,
                  child: Icon(Icons.broken_image),
                ),
              ),
              const SizedBox(height: 8),
              Text('Recommended: inspect wagon and acknowledge if verified.'),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: () async {
                      await ref
                          .read(mockApiProvider)
                          .acknowledgeAlert(alert.id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text('Acknowledge'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/video',
                        arguments: 'V-001',
                      );
                    },
                    child: const Text('View Video'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
