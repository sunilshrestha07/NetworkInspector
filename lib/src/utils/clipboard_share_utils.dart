import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Thin wrapper around [Clipboard] and `share_plus` used by every "Copy" /
/// "Share" affordance in the inspector UI, so the confirmation SnackBar and
/// share-sheet invocation stay consistent in one place.
class ClipboardShareUtils {
  const ClipboardShareUtils._();

  /// Copies [text] to the clipboard and, if [context] is still mounted,
  /// shows a brief confirmation SnackBar labelled with [label].
  static Future<void> copy(
    BuildContext context,
    String text, {
    String label = 'Copied to clipboard',
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label), duration: const Duration(seconds: 1)),
    );
  }

  /// Opens the platform share sheet with [text] as plain-text content.
  static Future<void> share(String text, {String? subject}) {
    if (text.isEmpty) return Future.value();
    return Share.share(text, subject: subject);
  }
}
