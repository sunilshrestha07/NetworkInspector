import 'package:flutter/material.dart';

import '../controllers/network_call_filter_controller.dart';
import '../controllers/network_call_store.dart';
import '../widgets/call_action_bottom_sheet.dart';
import '../widgets/network_call_card.dart';
import '../widgets/search_and_filter_bar.dart';
import '../widgets/sort_menu.dart';
import 'network_call_detail_screen.dart';

/// The inspector's home screen: search, method/status filters, sort, and a
/// lazily-built list of captured calls. This is the screen
/// `NetworkInspector.open()` pushes.
class NetworkCallListScreen extends StatefulWidget {
  const NetworkCallListScreen({super.key});

  @override
  State<NetworkCallListScreen> createState() => _NetworkCallListScreenState();
}

class _NetworkCallListScreenState extends State<NetworkCallListScreen> {
  late final NetworkCallStore _store = NetworkCallStore.fromConfig();
  late final NetworkCallFilterController _filters = NetworkCallFilterController();
  late final Listenable _listenable = Listenable.merge([_store, _filters]);

  @override
  void dispose() {
    _store.dispose();
    _filters.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Inspector'),
        actions: [
          SortMenu(controller: _filters),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: Column(
        children: [
          SearchAndFilterBar(controller: _filters),
          const Divider(height: 1),
          Expanded(
            child: AnimatedBuilder(
              animation: _listenable,
              builder: (context, _) {
                final allCalls = _store.calls;
                if (allCalls.isEmpty) {
                  return const _EmptyState(
                    message:
                        'No requests captured yet.\nUse the app — every Dio call will show up here.',
                  );
                }

                final filteredCalls = _filters.apply(allCalls);
                if (filteredCalls.isEmpty) {
                  return const _EmptyState(
                    message: 'No requests match your search or filters.',
                  );
                }

                return ListView.builder(
                  itemCount: filteredCalls.length,
                  itemBuilder: (context, index) {
                    final call = filteredCalls[index];
                    return NetworkCallCard(
                      key: ValueKey(call.id),
                      call: call,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              NetworkCallDetailScreen(callId: call.id, store: _store),
                        ),
                      ),
                      onLongPress: () =>
                          CallActionBottomSheet.show(context, call: call, store: _store),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all requests?'),
        content: const Text('This removes every captured request from this session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) _store.clearAll();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_tethering,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
