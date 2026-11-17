import '../../domain/entities/api_request.dart';
import '../../domain/entities/api_response.dart';
import '../../domain/entities/execution_engine.dart';
import '../../domain/repositories/api_repository.dart';
import '../datasources/api_remote_data_source.dart';
import '../datasources/api_direct_data_source.dart';
import '../models/api_request_model.dart';

class ApiRepositoryImpl implements ApiRepository {
  final ApiRemoteDataSource remoteDataSource;
  final ApiDirectDataSource directDataSource;

  ApiRepositoryImpl({
    required this.remoteDataSource,
    ApiDirectDataSource? directDataSource,
  }) : directDataSource = directDataSource ?? ApiDirectDataSource();

  @override
  Future<ApiResponse> executeRequest(ApiRequest request) async {
    final model = ApiRequestModel.fromEntity(request);
    return await directDataSource.executeRequest(model);
  }

  Future<ApiResponse> executeWithEnvironment(
    ApiRequest request,
    String? environmentId, {
    ExecutionEngine engine = ExecutionEngine.direct,
    Map<String, String>? environmentVariables,
  }) async {
    final model = ApiRequestModel.fromEntity(request);
    if (engine == ExecutionEngine.direct) {
      return await directDataSource.executeRequest(
        model,
        environmentVariables: environmentVariables,
      );
    }
    return await remoteDataSource.executeRequest(model, environmentId);
  }
}
