import 'package:flutter/material.dart';

import '../../data/models/http_method.dart';
import '../controllers/network_call_filter_controller.dart';

/// The list screen's search field plus method/status filter chip rows,
/// rebuilding only itself (not the whole screen) when filter criteria
/// change, via a scoped [AnimatedBuilder] on [controller].
class SearchAndFilterBar extends StatelessWidget {
  const SearchAndFilterBar({super.key, required this.controller});

  final NetworkCallFilterController controller;

  static const _methods = [
    HttpMethod.get,
    HttpMethod.post,
    HttpMethod.put,
    HttpMethod.patch,
    HttpMethod.delete,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SearchBar(
                hintText: 'Search URL, body, headers, method, status…',
                leading: const Icon(Icons.search),
                trailing: [
                  if (controller.searchText.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: () => controller.setSearchText(''),
                    ),
                ],
                onChanged: controller.setSearchText,
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final method in _methods)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(method.label),
                        selected: controller.methodFilters.contains(method),
                        onSelected: (_) => controller.toggleMethod(method),
                      ),
                    ),
                  const VerticalDivider(width: 16, indent: 6, endIndent: 6),
                  for (final status in StatusFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(status.label),
                        selected: controller.statusFilters.contains(status),
                        onSelected: (_) => controller.toggleStatus(status),
                      ),
                    ),
                  if (controller.hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ActionChip(
                        avatar: const Icon(Icons.close, size: 16),
                        label: const Text('Clear'),
                        onPressed: controller.clearFilters,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}
