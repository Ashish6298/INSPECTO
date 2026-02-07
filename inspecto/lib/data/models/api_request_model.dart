import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/api_request.dart';

part 'api_request_model.g.dart';

@JsonSerializable()
class ApiRequestModel extends ApiRequest {
  ApiRequestModel({
    required super.id,
    required super.method,
    required super.url,
    required super.headers,
    required super.params,
    super.body,
    super.bodyType,
  });

  factory ApiRequestModel.fromJson(Map<String, dynamic> json) =>
      _$ApiRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$ApiRequestModelToJson(this);

  factory ApiRequestModel.fromEntity(ApiRequest entity) {
    return ApiRequestModel(
      id: entity.id,
      method: entity.method,
      url: entity.url,
      headers: entity.headers,
      params: entity.params,
      body: entity.body,
      bodyType: entity.bodyType,
    );
  }
}
