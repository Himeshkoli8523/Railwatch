import 'package:cctv/shared/models/app_models.dart';
import 'package:cctv/shared/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _range = '24h';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _SummaryCard(title: 'Active Alerts', value: '21'),
            _SummaryCard(title: 'Cameras Online', value: '148/152'),
            _SummaryCard(title: 'Defects Today', value: '9'),
            _SummaryCard(title: 'Video Ingestion', value: '182 MB/s'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Time range:'),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _range,
              items: const [
                DropdownMenuItem(value: '1h', child: Text('1h')),
                DropdownMenuItem(value: '24h', child: Text('24h')),
                DropdownMenuItem(value: '7d', child: Text('7d')),
              ],
              onChanged: (value) => setState(() => _range = value ?? '24h'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Recent critical alerts'),
        const SizedBox(height: 8),
        ...List.generate(
          3,
          (index) => ListTile(
            minTileHeight: 44,
            leading: const Icon(Icons.warning_amber_rounded),
            title: Text('Critical detection #$index'),
            subtitle: const Text('Camera C-17 • Wagon W-3'),
            trailing: const SeverityBadge(severity: Severity.critical),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Quick actions'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text('Live Feed'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Export'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  12,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: (index % 5 + 2) * 3,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
