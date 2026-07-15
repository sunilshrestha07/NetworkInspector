/// HTTP methods recognized by the inspector, with a color/label mapping used
/// throughout the presentation layer.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options,
  unknown;

  /// Parses a raw method string (as it appears on [RequestOptions.method])
  /// into a [HttpMethod], case-insensitively, falling back to [unknown].
  factory HttpMethod.parse(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'GET':
        return HttpMethod.get;
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'PATCH':
        return HttpMethod.patch;
      case 'DELETE':
        return HttpMethod.delete;
      case 'HEAD':
        return HttpMethod.head;
      case 'OPTIONS':
        return HttpMethod.options;
      default:
        return HttpMethod.unknown;
    }
  }

  /// The uppercase wire representation, e.g. `GET`.
  String get label {
    switch (this) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
      case HttpMethod.head:
        return 'HEAD';
      case HttpMethod.options:
        return 'OPTIONS';
      case HttpMethod.unknown:
        return '?';
    }
  }
}
