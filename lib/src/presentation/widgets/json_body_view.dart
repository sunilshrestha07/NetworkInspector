import 'dart:convert';

import 'package:flutter/material.dart';

/// Pretty-printed, monospaced, selectable rendering of a request/response
/// body. Accepts already-decoded data (Map/List), a raw JSON string, or
/// plain text — falls back to `toString()` for anything else.
///
/// This is a plain-text pretty-printer (no syntax highlighting, line
/// numbers, or in-body search yet) — see the package README for the
/// Phase 2 roadmap.
class JsonBodyView extends StatelessWidget {
  const JsonBodyView({super.key, required this.data});

  final Object? data;

  String get _prettyText {
    if (data == null) return '';
    if (data is String) {
      final raw = data as String;
      try {
        final decoded = jsonDecode(raw);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return raw;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _prettyText;
    if (text.isEmpty) {
      return Text(
        'No body',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return SelectableText(
      text,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
    );
  }
}
