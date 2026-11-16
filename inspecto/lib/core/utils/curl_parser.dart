import '../../domain/entities/api_request.dart';

class CurlParser {
  /// Parses a raw cURL command into an [ApiRequest].
  static ApiRequest parse(String rawCurl) {
    if (rawCurl.trim().isEmpty) {
      throw const FormatException('cURL command is empty');
    }

    // 1. Remove line continuations and normalize whitespace
    String sanitized = rawCurl
        .replaceAll(RegExp(r'\\\r?\n'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Remove leading 'curl ' if present
    if (sanitized.toLowerCase().startsWith('curl ')) {
      sanitized = sanitized.substring(5).trim();
    }

    // 2. Tokenize command arguments respecting quotes
    final List<String> tokens = _tokenize(sanitized);

    HttpMethod? explicitMethod;
    String url = '';
    final Map<String, String> headers = {};
    final Map<String, String> params = {};
    final List<String> dataChunks = [];
    String authType = 'none';
    Map<String, dynamic> authDetails = {};

    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];

      if (token == '-X' || token == '--request') {
        if (i + 1 < tokens.length) {
          final methodStr = tokens[++i].toUpperCase();
          explicitMethod = _parseMethod(methodStr);
        }
      } else if (token == '-H' || token == '--header') {
        if (i + 1 < tokens.length) {
          final headerLine = tokens[++i];
          final separatorIndex = headerLine.indexOf(':');
          if (separatorIndex != -1) {
            final key = headerLine.substring(0, separatorIndex).trim();
            final value = headerLine.substring(separatorIndex + 1).trim();
            headers[key] = value;

            // Check if Authorization header is present
            if (key.toLowerCase() == 'authorization') {
              if (value.toLowerCase().startsWith('bearer ')) {
                authType = 'bearer';
                authDetails = {'token': value.substring(7).trim()};
              } else if (value.toLowerCase().startsWith('basic ')) {
                authType = 'basic';
                authDetails = {'encoded': value.substring(6).trim()};
              }
            }
          }
        }
      } else if (token == '-d' ||
          token == '--data' ||
          token == '--data-raw' ||
          token == '--data-binary' ||
          token == '--data-ascii' ||
          token == '--data-urlencode') {
        if (i + 1 < tokens.length) {
          dataChunks.add(tokens[++i]);
        }
      } else if (token == '-u' || token == '--user') {
        if (i + 1 < tokens.length) {
          final credentials = tokens[++i];
          final parts = credentials.split(':');
          authType = 'basic';
          authDetails = {
            'username': parts[0],
            'password': parts.length > 1 ? parts.sublist(1).join(':') : '',
          };
        }
      } else if (token == '--url') {
        if (i + 1 < tokens.length) {
          url = tokens[++i];
        }
      } else if (!token.startsWith('-') && url.isEmpty) {
        url = token;
      }
      i++;
    }

    // Clean quotes from URL if any
    url = _stripQuotes(url);

    // Parse query parameters from URL if present
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasQuery) {
      uri.queryParameters.forEach((key, value) {
        params[key] = value;
      });
      // Keep base URL without query in url or keep full url
    }

    // Determine body and method
    String? body;
    String bodyType = 'none';
    String bodySubType = 'json';

    if (dataChunks.isNotEmpty) {
      body = dataChunks.join('&');
      final contentType = headers.entries
          .firstWhere(
            (e) => e.key.toLowerCase() == 'content-type',
            orElse: () => const MapEntry('', ''),
          )
          .value
          .toLowerCase();

      if (contentType.contains('application/json') ||
          (body.trim().startsWith('{') && body.trim().endsWith('}')) ||
          (body.trim().startsWith('[') && body.trim().endsWith(']'))) {
        bodyType = 'json';
        bodySubType = 'json';
      } else if (contentType.contains('application/x-www-form-urlencoded')) {
        bodyType = 'x-www-form-urlencoded';
      } else {
        bodyType = 'raw';
        bodySubType = 'text';
      }
    }

    final HttpMethod method = explicitMethod ??
        (dataChunks.isNotEmpty ? HttpMethod.POST : HttpMethod.GET);

    return ApiRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      url: url,
      headers: headers,
      params: params,
      body: body,
      bodyType: bodyType,
      bodySubType: bodySubType,
      authType: authType,
      authDetails: authDetails,
    );
  }

  static HttpMethod _parseMethod(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return HttpMethod.POST;
      case 'PUT':
        return HttpMethod.PUT;
      case 'DELETE':
        return HttpMethod.DELETE;
      case 'PATCH':
        return HttpMethod.PATCH;
      case 'GET':
      default:
        return HttpMethod.GET;
    }
  }

  static String _stripQuotes(String str) {
    if ((str.startsWith('"') && str.endsWith('"')) ||
        (str.startsWith("'") && str.endsWith("'"))) {
      return str.substring(1, str.length - 1);
    }
    return str;
  }

  static List<String> _tokenize(String input) {
    final List<String> tokens = [];
    final StringBuffer current = StringBuffer();
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    bool escaped = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (escaped) {
        current.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\' && !inSingleQuote) {
        escaped = true;
        continue;
      }

      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        continue;
      }

      if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      if (char == ' ' && !inSingleQuote && !inDoubleQuote) {
        if (current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
        }
        continue;
      }

      current.write(char);
    }

    if (current.isNotEmpty) {
      tokens.add(current.toString());
    }

    return tokens;
  }
}
