import 'api_request.dart';

class Collection {
  final String id;
  final String name;
  final List<ApiRequest> requests;

  Collection({
    required this.id,
    required this.name,
    required this.requests,
  });
}
