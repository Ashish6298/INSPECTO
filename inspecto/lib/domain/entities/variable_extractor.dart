import 'dart:convert';
import 'api_response.dart';

enum ExtractorSource {
  responseBody,
  responseHeader,
}

class VariableExtractor {
  final String id;
  final ExtractorSource source;
  final String pathOrKey; // e.g. "data.token" or "Authorization"
  final String targetVariable; // e.g. "authToken"
  final bool enabled;

  VariableExtractor({
    required this.id,
    required this.source,
    required this.pathOrKey,
    required this.targetVariable,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.name,
        'pathOrKey': pathOrKey,
        'targetVariable': targetVariable,
        'enabled': enabled,
      };

  factory VariableExtractor.fromJson(Map<String, dynamic> json) {
    return VariableExtractor(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      source: json['source'] == 'responseHeader'
          ? ExtractorSource.responseHeader
          : ExtractorSource.responseBody,
      pathOrKey: json['pathOrKey'] as String? ?? '',
      targetVariable: json['targetVariable'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  VariableExtractor copyWith({
    String? id,
    ExtractorSource? source,
    String? pathOrKey,
    String? targetVariable,
    bool? enabled,
  }) {
    return VariableExtractor(
      id: id ?? this.id,
      source: source ?? this.source,
      pathOrKey: pathOrKey ?? this.pathOrKey,
      targetVariable: targetVariable ?? this.targetVariable,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Extracts the target value from [ApiResponse] based on extractor configuration.
  static String? extractFromResponse(
      VariableExtractor extractor, ApiResponse response) {
    if (!extractor.enabled ||
        extractor.pathOrKey.trim().isEmpty ||
        extractor.targetVariable.trim().isEmpty) {
      return null;
    }

    if (extractor.source == ExtractorSource.responseHeader) {
      final targetHeader = extractor.pathOrKey.trim().toLowerCase();
      for (final entry in response.headers.entries) {
        if (entry.key.toLowerCase() == targetHeader) {
          final val = entry.value.trim();
          // If header starts with 'Bearer ', extract the token part if needed
          if (val.toLowerCase().startsWith('bearer ') && val.length > 7) {
            return val.substring(7).trim();
          }
          return val;
        }
      }
      return null;
    }

    // Default: Response Body (JSONPath / dot-notation)
    if (response.body.trim().isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(response.body);
      final dynamic extracted = _extractByPath(decoded, extractor.pathOrKey.trim());
      if (extracted == null) return null;

      if (extracted is String) return extracted;
      if (extracted is num || extracted is bool) return extracted.toString();
      // If it's a map or list, encode to json string
      return jsonEncode(extracted);
    } catch (_) {
      return null;
    }
  }

  static dynamic _extractByPath(dynamic current, String path) {
    if (path.isEmpty || current == null) return current;

    // Normalize array notation like "items[0].id" to "items.0.id"
    final normalizedPath =
        path.replaceAllMapped(RegExp(r'\[(\d+)\]'), (m) => '.${m.group(1)}');
    final segments =
        normalizedPath.split('.').where((s) => s.isNotEmpty).toList();

    dynamic cursor = current;
    for (final segment in segments) {
      if (cursor == null) return null;

      if (cursor is Map) {
        if (cursor.containsKey(segment)) {
          cursor = cursor[segment];
        } else {
          // Case-insensitive key lookup fallback
          dynamic match;
          for (final entry in cursor.entries) {
            if (entry.key.toString().toLowerCase() == segment.toLowerCase()) {
              match = entry.value;
              break;
            }
          }
          if (match != null) {
            cursor = match;
          } else {
            return null;
          }
        }
      } else if (cursor is List) {
        final index = int.tryParse(segment);
        if (index != null && index >= 0 && index < cursor.length) {
          cursor = cursor[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    return cursor;
  }
}
