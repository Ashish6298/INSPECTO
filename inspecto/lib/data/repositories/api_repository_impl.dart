import '../../domain/entities/api_request.dart';
import '../../domain/entities/api_response.dart';
import '../../domain/repositories/api_repository.dart';
import '../datasources/api_remote_data_source.dart';
import '../models/api_request_model.dart';

class ApiRepositoryImpl implements ApiRepository {
  final ApiRemoteDataSource remoteDataSource;

  ApiRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse> executeRequest(ApiRequest request) async {
    final model = ApiRequestModel.fromEntity(request);
    // For now, null environmentId. Will be handled by EnvironmentProvider.
    return await remoteDataSource.executeRequest(model, null);
  }

  // Overloaded version or modified interface might be needed for environmentId
  Future<ApiResponse> executeWithEnvironment(
      ApiRequest request, String? environmentId) async {
    final model = ApiRequestModel.fromEntity(request);
    return await remoteDataSource.executeRequest(model, environmentId);
  }
}
