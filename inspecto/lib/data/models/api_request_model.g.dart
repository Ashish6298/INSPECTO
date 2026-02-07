// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiRequestModel _$ApiRequestModelFromJson(Map<String, dynamic> json) =>
    ApiRequestModel(
      id: json['id'] as String,
      method: $enumDecode(_$HttpMethodEnumMap, json['method']),
      url: json['url'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
      params: Map<String, String>.from(json['params'] as Map),
      body: json['body'] as String?,
      bodyType: json['bodyType'] as String? ?? 'none',
    );

Map<String, dynamic> _$ApiRequestModelToJson(ApiRequestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'method': _$HttpMethodEnumMap[instance.method]!,
      'url': instance.url,
      'headers': instance.headers,
      'params': instance.params,
      'body': instance.body,
      'bodyType': instance.bodyType,
    };

const _$HttpMethodEnumMap = {
  HttpMethod.GET: 'GET',
  HttpMethod.POST: 'POST',
  HttpMethod.PUT: 'PUT',
  HttpMethod.DELETE: 'DELETE',
  HttpMethod.PATCH: 'PATCH',
};
