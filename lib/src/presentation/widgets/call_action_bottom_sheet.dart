import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';

import '../../data/models/network_call.dart';
import '../../interceptor/network_inspector_interceptor.dart';
import '../../utils/clipboard_share_utils.dart';
import '../../utils/curl_generator.dart';
import '../controllers/network_call_store.dart';

/// Long-press action sheet for a single [NetworkCall], matching Chucker's
/// long-press menu: copy actions, share, retry, pin and delete are fully
/// wired; Edit-and-Resend, Favorite and Export are shown but disabled as a
/// documented Phase 2 follow-up.
class CallActionBottomSheet extends StatelessWidget {
  const CallActionBottomSheet({
    super.key,
    required this.call,
    required this.store,
  });

  final NetworkCall call;
  final NetworkCallStore store;

  static Future<void> show(
    BuildContext context, {
    required NetworkCall call,
    required NetworkCallStore store,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CallActionBottomSheet(call: call, store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.link,
            label: 'Copy URL',
            onTap: () => _copy(context, call.fullUrl, 'URL copied'),
          ),
          _ActionTile(
            icon: Icons.list_alt,
            label: 'Copy Headers',
            onTap: () => _copy(context, _formatMap(call.requestHeaders), 'Headers copied'),
          ),
          _ActionTile(
            icon: Icons.upload,
            label: 'Copy Request Body',
            onTap: () => _copy(context, _bodyText(call.requestBody), 'Request body copied'),
          ),
          _ActionTile(
            icon: Icons.download,
            label: 'Copy Response Body',
            onTap: () => _copy(context, _bodyText(call.responseBody), 'Response body copied'),
          ),
          _ActionTile(
            icon: Icons.receipt_long,
            label: 'Copy Response Headers',
            onTap: () =>
                _copy(context, _formatMap(call.responseHeaders), 'Response headers copied'),
          ),
          _ActionTile(
            icon: Icons.terminal,
            label: 'Copy cURL',
            onTap: () => _copy(context, CurlGenerator.generate(call), 'cURL copied'),
          ),
          _ActionTile(
            icon: Icons.ios_share,
            label: 'Share Request',
            onTap: () {
              Navigator.of(context).pop();
              ClipboardShareUtils.share(CurlGenerator.generate(call), subject: call.fullUrl);
            },
          ),
          _ActionTile(
            icon: Icons.replay,
            label: 'Retry Request',
            onTap: () => _retry(context),
          ),
          _ActionTile(
            icon: call.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: call.pinned ? 'Unpin Request' : 'Pin Request',
            onTap: () {
              store.togglePinned(call);
              Navigator.of(context).pop();
            },
          ),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete Request',
            destructive: true,
            onTap: () {
              store.delete(call.id);
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 24),
          const _ActionTile(
            icon: Icons.edit_note,
            label: 'Edit and Resend',
            subtitle: 'Coming in a future update',
            enabled: false,
          ),
          const _ActionTile(
            icon: Icons.favorite_border,
            label: 'Favorite Request',
            subtitle: 'Coming in a future update',
            enabled: false,
          ),
          const _ActionTile(
            icon: Icons.folder_zip_outlined,
            label: 'Export Request',
            subtitle: 'Coming in a future update',
            enabled: false,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text, String label) async {
    Navigator.of(context).pop();
    if (text.isEmpty) return;
    await ClipboardShareUtils.copy(context, text, label: label);
  }

  Future<void> _retry(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retry request?'),
        content: Text(
          'This sends a real ${call.method.label} request to:\n${call.fullUrl}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    Navigator.of(context).pop();

    // A fresh client, not the app's authenticated Dio instance: retrying
    // should reproduce exactly the headers/body already captured rather
    // than picking up whatever the app's auth interceptor would inject
    // for a *new* request. Attaching the inspector interceptor here means
    // the retried call still shows up as a new entry in the log.
    final client = dio.Dio()..interceptors.add(NetworkInspectorInterceptor());
    unawaited(_sendRetry(client));
  }

  Future<void> _sendRetry(dio.Dio client) async {
    try {
      await client.request<dynamic>(
        call.fullUrl,
        data: call.requestBody,
        options: dio.Options(method: call.method.label, headers: call.requestHeaders),
      );
    } catch (_) {
      // The result (success or failure) is already visible as a new entry
      // in the inspector log via the interceptor attached above.
    }
  }

  String _formatMap(Map<String, String> map) {
    if (map.isEmpty) return '';
    return map.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n');
  }

  String _bodyText(Object? body) {
    if (body == null) return '';
    if (body is String) return body;
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.subtitle,
    this.destructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: enabled ? onTap : null,
    );
  }
}
