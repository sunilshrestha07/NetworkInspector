import 'package:flutter/material.dart';

import '../../data/models/network_call_status.dart';

/// A small colored pill showing a call's status: green for success, red for
/// error, orange for redirects, grey for pending/cancelled.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.statusCode,
    this.dense = false,
  });

  final NetworkCallStatus status;
  final int? statusCode;
  final bool dense;

  static Color colorFor(NetworkCallStatus status) {
    switch (status) {
      case NetworkCallStatus.success:
        return const Color(0xFF2FA84F);
      case NetworkCallStatus.redirect:
        return const Color(0xFFE8912D);
      case NetworkCallStatus.clientError:
      case NetworkCallStatus.serverError:
      case NetworkCallStatus.error:
        return const Color(0xFFE1483F);
      case NetworkCallStatus.pending:
      case NetworkCallStatus.cancelled:
        return const Color(0xFF7A7F87);
    }
  }

  String get _label {
    if (status == NetworkCallStatus.pending) return '···';
    if (status == NetworkCallStatus.cancelled) return 'CANCELLED';
    return statusCode?.toString() ?? status.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
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
        _label,
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
