/// Coarse classification of a request body's encoding, used to decide how to
/// render it in the UI and how to reproduce it in a generated cURL command.
enum RequestBodyKind {
  json,
  formUrlEncoded,
  multipart,
  binary,
  text,
  none;

  /// Best-effort classification from a Dio `Content-Type` header value and
  /// the runtime type of the request data.
  static RequestBodyKind classify({required String? contentType, required Object? data}) {
    if (data == null) return RequestBodyKind.none;

    final normalizedContentType = contentType?.toLowerCase() ?? '';
    if (normalizedContentType.contains('multipart/form-data')) {
      return RequestBodyKind.multipart;
    }
    if (normalizedContentType.contains('application/x-www-form-urlencoded')) {
      return RequestBodyKind.formUrlEncoded;
    }
    if (normalizedContentType.contains('application/json')) {
      return RequestBodyKind.json;
    }
    if (data is List<int>) {
      return RequestBodyKind.binary;
    }
    if (data is Map || data is List) {
      return RequestBodyKind.json;
    }
    if (data is String) {
      return RequestBodyKind.text;
    }
    return RequestBodyKind.binary;
  }
}
