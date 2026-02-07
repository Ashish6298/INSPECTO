import '../entities/api_request.dart';
import '../entities/api_response.dart';

abstract class ApiRepository {
  Future<ApiResponse> executeRequest(ApiRequest request);
}
