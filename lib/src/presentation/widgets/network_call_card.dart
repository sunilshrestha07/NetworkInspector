import 'package:flutter/material.dart';

import '../../data/models/network_call.dart';
import '../../utils/byte_size_formatter.dart';
import 'method_badge.dart';
import 'status_badge.dart';

/// A Material 3 card summarizing one captured call for the list screen.
class NetworkCallCard extends StatelessWidget {
  const NetworkCallCard({
    super.key,
    required this.call,
    required this.onTap,
    required this.onLongPress,
  });

  final NetworkCall call;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayPath = call.path.isEmpty ? call.fullUrl : call.path;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MethodBadge(method: call.method),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: call.status, statusCode: call.statusCode),
                  if (call.pinned) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                call.fullUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetaChip(icon: Icons.access_time, label: _formatTime(call.startTime)),
                  const SizedBox(width: 12),
                  _MetaChip(
                    icon: Icons.timer_outlined,
                    label: call.duration?.toReadableDuration() ?? '···',
                  ),
                  const SizedBox(width: 12),
                  _MetaChip(
                    icon: Icons.arrow_downward,
                    label: call.responseSizeBytes.toReadableSize(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}
