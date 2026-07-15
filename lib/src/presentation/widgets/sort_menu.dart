import 'package:flutter/material.dart';

import '../controllers/network_call_filter_controller.dart';

/// AppBar action opening a menu of [SortMode] options.
class SortMenu extends StatelessWidget {
  const SortMenu({super.key, required this.controller});

  final NetworkCallFilterController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return PopupMenuButton<SortMode>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort',
          initialValue: controller.sortMode,
          onSelected: controller.setSortMode,
          itemBuilder: (context) => [
            for (final mode in SortMode.values)
              PopupMenuItem<SortMode>(
                value: mode,
                child: Row(
                  children: [
                    Icon(
                      mode == controller.sortMode ? Icons.check : null,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(mode.label),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
