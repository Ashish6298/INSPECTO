import 'api_request.dart';
import 'api_response.dart';

/// Represents a single active request tab session in the Inspecto workspace.
class TabSession {
  final String id;
  String title;
  ApiRequest request;
  ApiResponse? response;
  bool isDirty;

  TabSession({
    required this.id,
    required this.title,
    required this.request,
    this.response,
    this.isDirty = false,
  });

  /// Factory to generate a default initial tab session
  factory TabSession.initial({
    String? id,
    String? title,
    ApiRequest? request,
  }) {
    final generatedId =
        id ?? 'tab_${DateTime.now().millisecondsSinceEpoch}_0';
    final initialRequest = request ??
        ApiRequest(
          id: 'req_$generatedId',
          method: HttpMethod.GET,
          url: '',
          headers: {},
          params: {},
        );

    return TabSession(
      id: generatedId,
      title: title ?? 'Untitled Request',
      request: initialRequest,
      response: null,
      isDirty: false,
    );
  }

  /// Returns a clean copy with updated properties
  TabSession copyWith({
    String? id,
    String? title,
    ApiRequest? request,
    ApiResponse? response,
    bool? isDirty,
    bool clearResponse = false,
  }) {
    return TabSession(
      id: id ?? this.id,
      title: title ?? this.title,
      request: request ?? this.request,
      response: clearResponse ? null : (response ?? this.response),
      isDirty: isDirty ?? this.isDirty,
    );
  }

  /// Formatted title with dirty indicator
  String get displayTitle {
    final base = title.trim().isEmpty ? 'Untitled Request' : title.trim();
    return isDirty ? '$base *' : base;
  }

  /// Request HTTP method helper
  HttpMethod get method => request.method;

  /// Request target URL helper
  String get url => request.url;
}
