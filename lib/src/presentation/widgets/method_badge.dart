import 'package:flutter/material.dart';

import '../../data/models/http_method.dart';

/// A small colored pill showing an HTTP method, colored consistently
/// across the whole inspector (list cards, detail app bar, bottom sheets).
class MethodBadge extends StatelessWidget {
  const MethodBadge({super.key, required this.method, this.dense = false});

  final HttpMethod method;

  /// Slightly smaller padding/text for tight spaces like the AppBar.
  final bool dense;

  static Color colorFor(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return const Color(0xFF2E7DFA);
      case HttpMethod.post:
        return const Color(0xFF2FA84F);
      case HttpMethod.put:
        return const Color(0xFFE8912D);
      case HttpMethod.patch:
        return const Color(0xFF9C5FE0);
      case HttpMethod.delete:
        return const Color(0xFFE1483F);
      case HttpMethod.head:
      case HttpMethod.options:
      case HttpMethod.unknown:
        return const Color(0xFF7A7F87);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(method);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        method.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: dense ? 10 : 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
