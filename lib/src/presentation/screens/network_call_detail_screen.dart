import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/models/network_call.dart';
import '../../data/models/request_body_kind.dart';
import '../../utils/byte_size_formatter.dart';
import '../../utils/clipboard_share_utils.dart';
import '../../utils/curl_generator.dart';
import '../controllers/network_call_store.dart';
import '../widgets/expandable_body_section.dart';
import '../widgets/json_body_view.dart';
import '../widgets/method_badge.dart';
import '../widgets/status_badge.dart';

/// Chucker-style detail page: AppBar with method/status badges plus copy
/// and share, and three tabs — Overview, Request, Response.
class NetworkCallDetailScreen extends StatefulWidget {
  const NetworkCallDetailScreen({super.key, required this.callId, required this.store});

  final String callId;
  final NetworkCallStore store;

  @override
  State<NetworkCallDetailScreen> createState() => _NetworkCallDetailScreenState();
}

class _NetworkCallDetailScreenState extends State<NetworkCallDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        NetworkCall? call;
        for (final candidate in widget.store.calls) {
          if (candidate.id == widget.callId) {
            call = candidate;
            break;
          }
        }

        if (call == null) {
          // The call was deleted (or the log evicted it) while this screen
          // was open — back out rather than show a stale/blank page.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final curl = CurlGenerator.generate(call);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MethodBadge(method: call.method, dense: true),
                const SizedBox(width: 8),
                StatusBadge(status: call.status, statusCode: call.statusCode, dense: true),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy cURL',
                onPressed: () => ClipboardShareUtils.copy(context, curl, label: 'cURL copied'),
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: 'Share',
                onPressed: () => ClipboardShareUtils.share(curl, subject: call!.fullUrl),
              ),
            ],
            bottom: TabBar(controller: _tabController, tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ]),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(call: call),
              _RequestTab(call: call),
              _ResponseTab(call: call),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.call});

  final NetworkCall call;

  @override
  Widget build(BuildContext context) {
    final duration = call.duration;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row(context, 'Full URL', call.fullUrl),
        _row(context, 'Method', call.method.label),
        _row(context, 'Status', call.status.name),
        _row(context, 'Status code', call.statusCode?.toString() ?? '—'),
        _row(context, 'Success', call.status.isSuccess ? 'Yes' : 'No'),
        _row(context, 'Duration', duration?.toReadableDuration() ?? 'Pending'),
        _row(context, 'Request size', call.requestSizeBytes.toReadableSize()),
        _row(context, 'Response size', call.responseSizeBytes.toReadableSize()),
        _row(context, 'Started at', call.startTime.toIso8601String()),
        _row(context, 'Completed at', call.endTime?.toIso8601String() ?? '—'),
        _row(context, 'Request ID', call.id),
        _row(context, 'Protocol', call.protocolVersion ?? 'N/A (not exposed by Dio)'),
        _row(context, 'Pinned', call.pinned ? 'Yes' : 'No'),
        if (call.error != null) _row(context, 'Error', '${call.error}'),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  const _RequestTab({required this.call});

  final NetworkCall call;

  @override
  Widget build(BuildContext context) {
    final headersText = _formatMap(call.requestHeaders);
    final cookiesText = _formatMap(call.requestCookies);
    final queryText = _formatMap(
      call.queryParams.map((key, value) => MapEntry(key, '$value')),
    );
    final pathParamsText = _formatMap(call.pathParams);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ExpandableBodySection(
          title: 'Request Headers',
          copyText: headersText,
          initiallyExpanded: true,
          child: Text(headersText.isEmpty ? 'No headers' : headersText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        ExpandableBodySection(
          title: 'Authorization',
          copyText: call.authorizationHeader,
          child: Text(call.authorizationHeader ?? 'No Authorization header',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        ExpandableBodySection(
          title: 'Cookies',
          copyText: cookiesText,
          child: Text(cookiesText.isEmpty ? 'No cookies' : cookiesText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        ExpandableBodySection(
          title: 'Query Parameters',
          copyText: queryText,
          child: Text(queryText.isEmpty ? 'No query parameters' : queryText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        ExpandableBodySection(
          title: 'Path Parameters',
          copyText: pathParamsText,
          child: Text(pathParamsText.isEmpty ? 'No path parameters' : pathParamsText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        if (call.requestBodyKind == RequestBodyKind.multipart ||
            call.requestBodyKind == RequestBodyKind.formUrlEncoded)
          ExpandableBodySection(
            title: call.requestBodyKind == RequestBodyKind.multipart
                ? 'Multipart Form Data'
                : 'Form Fields',
            copyText: _bodyText(call.requestBody),
            child: JsonBodyView(data: call.requestBody),
          ),
        if (call.requestBodyKind == RequestBodyKind.json ||
            call.requestBodyKind == RequestBodyKind.text)
          ExpandableBodySection(
            title: 'JSON Body',
            copyText: _bodyText(call.requestBody),
            initiallyExpanded: true,
            child: JsonBodyView(data: call.requestBody),
          ),
        ExpandableBodySection(
          title: 'Raw Body',
          copyText: _bodyText(call.requestBody),
          child: Text(_bodyText(call.requestBody).isEmpty ? 'No body' : _bodyText(call.requestBody),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        ExpandableBodySection(
          title: 'cURL',
          copyText: CurlGenerator.generate(call),
          child: SelectableText(
            CurlGenerator.generate(call),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _ResponseTab extends StatelessWidget {
  const _ResponseTab({required this.call});

  final NetworkCall call;

  @override
  Widget build(BuildContext context) {
    final headersText = _formatMap(call.responseHeaders);
    final cookiesText = _formatMap(call.responseCookies);
    final contentType = call.responseHeaders.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase() == 'content-type',
          orElse: () => const MapEntry('', ''),
        )
        .value;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ExpandableBodySection(
          title: 'Response Headers',
          copyText: headersText,
          initiallyExpanded: true,
          child: Text(headersText.isEmpty ? 'No headers' : headersText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        ExpandableBodySection(
          title: 'Cookies',
          copyText: cookiesText,
          child: Text(cookiesText.isEmpty ? 'No cookies' : cookiesText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        ExpandableBodySection(
          title: 'Content-Type',
          copyText: contentType,
          child: Text(contentType.isEmpty ? 'Unknown' : contentType,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        ExpandableBodySection(
          title: 'Pretty Response',
          copyText: _bodyText(call.responseBody),
          initiallyExpanded: true,
          child: JsonBodyView(data: call.responseBody),
        ),
        ExpandableBodySection(
          title: 'Raw Response',
          copyText: _bodyText(call.responseBody),
          child: Text(
            _bodyText(call.responseBody).isEmpty ? 'No body' : _bodyText(call.responseBody),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
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
