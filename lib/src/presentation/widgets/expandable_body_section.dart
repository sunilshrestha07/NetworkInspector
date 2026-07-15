import 'package:flutter/material.dart';

import '../../utils/clipboard_share_utils.dart';

/// A collapsible detail-page section with a title, optional subtitle, a
/// Copy/Share action row (shown only when there's something to copy) and
/// arbitrary body content. Used for every Request/Response tab section:
/// Headers, Authorization, Cookies, Query/Path Params, Body, cURL, etc.
class ExpandableBodySection extends StatelessWidget {
  const ExpandableBodySection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.copyText,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Text copied/shared by the header actions. When null or empty, no
  /// Copy/Share buttons are shown for this section.
  final String? copyText;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final hasCopyText = copyText != null && copyText!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        childrenPadding: EdgeInsets.zero,
        children: [
          if (hasCopyText)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        ClipboardShareUtils.copy(context, copyText!, label: '$title copied'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                  TextButton.icon(
                    onPressed: () => ClipboardShareUtils.share(copyText!, subject: title),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );
  }
}
