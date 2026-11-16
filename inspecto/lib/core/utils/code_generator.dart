import 'dart:convert';
import '../../domain/entities/api_request.dart';

enum CodeLanguage {
  curl,
  dartHttp,
  dartDio,
  jsFetch,
  nodeAxios,
  pythonRequests,
  pythonHttpx,
  go,
}

class CodeGenerator {
  static String generate(ApiRequest request, CodeLanguage language) {
    switch (language) {
      case CodeLanguage.curl:
        return _generateCurl(request);
      case CodeLanguage.dartHttp:
        return _generateDartHttp(request);
      case CodeLanguage.dartDio:
        return _generateDartDio(request);
      case CodeLanguage.jsFetch:
        return _generateJsFetch(request);
      case CodeLanguage.nodeAxios:
        return _generateNodeAxios(request);
      case CodeLanguage.pythonRequests:
        return _generatePythonRequests(request);
      case CodeLanguage.pythonHttpx:
        return _generatePythonHttpx(request);
      case CodeLanguage.go:
        return _generateGo(request);
    }
  }

  static Map<String, String> _buildEffectiveHeaders(ApiRequest request) {
    final headers = Map<String, String>.from(request.headers);
    if (request.authType == 'bearer' &&
        request.authDetails?['token'] != null &&
        request.authDetails!['token'].toString().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${request.authDetails!['token']}';
    } else if (request.authType == 'basic' &&
        request.authDetails?['username'] != null) {
      final user = request.authDetails!['username'];
      final pass = request.authDetails!['password'] ?? '';
      final encoded = base64Encode(utf8.encode('$user:$pass'));
      headers['Authorization'] = 'Basic $encoded';
    }
    if (request.bodyType == 'json' && !headers.containsKey('Content-Type')) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  static String _buildFullUrl(ApiRequest request) {
    if (request.params.isEmpty) return request.url;
    final uri = Uri.tryParse(request.url);
    if (uri == null) return request.url;

    final queryMap = Map<String, String>.from(uri.queryParameters);
    queryMap.addAll(request.params);
    return uri.replace(queryParameters: queryMap).toString();
  }

  static String _generateCurl(ApiRequest request) {
    final buffer = StringBuffer('curl -X ${request.method.name}');
    final url = _buildFullUrl(request);
    buffer.write(" '$url'");

    final headers = _buildEffectiveHeaders(request);
    headers.forEach((key, value) {
      buffer.write(" \\\n  -H '$key: $value'");
    });

    if (request.body != null && request.body!.isNotEmpty) {
      final escaped = request.body!.replaceAll("'", r"'\''");
      buffer.write(" \\\n  -d '$escaped'");
    }

    return buffer.toString();
  }

  static String _generateDartHttp(ApiRequest request) {
    final url = _buildFullUrl(request);
    final headers = _buildEffectiveHeaders(request);
    final method = request.method.name.toLowerCase();

    final buffer = StringBuffer();
    buffer.writeln("import 'dart:convert';");
    buffer.writeln("import 'package:http/http.dart' as http;\n");
    buffer.writeln("void main() async {");
    buffer.writeln("  final url = Uri.parse('$url');");

    if (headers.isNotEmpty) {
      buffer.writeln("  final headers = {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("  };\n");
    }

    if (request.body != null && request.body!.isNotEmpty) {
      buffer.writeln("  final body = '''${request.body}''';\n");
    }

    final headersParam = headers.isNotEmpty ? ", headers: headers" : "";
    final bodyParam = (request.body != null && request.body!.isNotEmpty)
        ? ", body: body"
        : "";

    if (['get', 'post', 'put', 'delete', 'patch'].contains(method)) {
      if (method == 'get' || method == 'delete') {
        buffer.writeln(
            "  final response = await http.$method(url$headersParam);");
      } else {
        buffer.writeln(
            "  final response = await http.$method(url$headersParam$bodyParam);");
      }
    } else {
      buffer.writeln(
          "  final request = http.Request('${request.method.name}', url);");
      if (headers.isNotEmpty) {
        buffer.writeln("  request.headers.addAll(headers);");
      }
      if (request.body != null && request.body!.isNotEmpty) {
        buffer.writeln("  request.body = body;");
      }
      buffer.writeln(
          "  final streamedResponse = await request.send();");
      buffer.writeln(
          "  final response = await http.Response.fromStream(streamedResponse);");
    }

    buffer.writeln("\n  print('Status: \${response.statusCode}');");
    buffer.writeln("  print('Body: \${response.body}');");
    buffer.writeln("}");
    return buffer.toString();
  }

  static String _generateDartDio(ApiRequest request) {
    final url = _buildFullUrl(request);
    final headers = _buildEffectiveHeaders(request);
    final method = request.method.name.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln("import 'package:dio/dio.dart';\n");
    buffer.writeln("void main() async {");
    buffer.writeln("  final dio = Dio();");

    buffer.writeln("  final options = Options(");
    buffer.writeln("    method: '$method',");
    if (headers.isNotEmpty) {
      buffer.writeln("    headers: {");
      headers.forEach((k, v) => buffer.writeln("      '$k': '$v',"));
      buffer.writeln("    },");
    }
    buffer.writeln("  );\n");

    final dataParam = (request.body != null && request.body!.isNotEmpty)
        ? ", data: '''${request.body}'''"
        : "";

    buffer.writeln("  try {");
    buffer.writeln("    final response = await dio.request(");
    buffer.writeln("      '$url',");
    buffer.writeln("      options: options$dataParam,");
    buffer.writeln("    );");
    buffer.writeln("    print(response.data);");
    buffer.writeln("  } catch (e) {");
    buffer.writeln("    print('Error: \$e');");
    buffer.writeln("  }");
    buffer.writeln("}");
    return buffer.toString();
  }

  static String _generateJsFetch(ApiRequest request) {
    final url = _buildFullUrl(request);
    final headers = _buildEffectiveHeaders(request);
    final method = request.method.name;

    final buffer = StringBuffer();
    buffer.writeln("const url = '$url';");
    buffer.writeln("const options = {");
    buffer.writeln("  method: '$method',");

    if (headers.isNotEmpty) {
      buffer.writeln("  headers: {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("  },");
    }

    if (request.body != null && request.body!.isNotEmpty) {
      buffer.writeln("  body: JSON.stringify(${request.body}),");
    }
    buffer.writeln("};\n");

    buffer.writeln("try {");
    buffer.writeln("  const response = await fetch(url, options);");
    buffer.writeln("  const data = await response.json();");
    buffer.writeln("  console.log(data);");
    buffer.writeln("} catch (error) {");
    buffer.writeln("  console.error('Fetch error:', error);");
    buffer.writeln("}");
    return buffer.toString();
  }

  static String _generateNodeAxios(ApiRequest request) {
    final url = _buildFullUrl(request);
    final headers = _buildEffectiveHeaders(request);
    final method = request.method.name.toLowerCase();

    final buffer = StringBuffer();
    buffer.writeln("const axios = require('axios');\n");
    buffer.writeln("const config = {");
    buffer.writeln("  method: '$method',");
    buffer.writeln("  url: '$url',");

    if (headers.isNotEmpty) {
      buffer.writeln("  headers: {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("  },");
    }

    if (request.body != null && request.body!.isNotEmpty) {
      buffer.writeln("  data: ${request.body},");
    }
    buffer.writeln("};\n");

    buffer.writeln("axios(config)");
    buffer.writeln("  .then(response => console.log(JSON.stringify(response.data)))");
    buffer.writeln("  .catch(error => console.error(error));");
    return buffer.toString();
  }

  static String _generatePythonRequests(ApiRequest request) {
    final url = _buildFullUrl(request);
    final headers = _buildEffectiveHeaders(request);
    final method = request.method.name.lowerCase();

    final buffer = StringBuffer();
    buffer.writeln("import requests\n");
    buffer.writeln("url = '$url'");

    if (headers.isNotEmpty) {
      buffer.writeln("headers = {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("}");
    } else {
      buffer.writeln("headers = {}");
    }

    if (request.body != null && request.body!.isNotEmpty) {
      buffer.writeln("payload = '''${request.body}'''");
      buffer.writeln(
          "\nresponse = requests.$method(url, headers=headers, data=payload)");
    } else {
      buffer.writeln("\nresponse = requests.$method(url, headers=headers)");
    }

    buffer.writeln("print(response.status_code)");
    buffer.writeln("print(response.text)");
    return buffer.toString();
  }

  static String _generatePythonHttpx(ApiRequest request) {
    final url = _buildFullUrl(request);
    final headers = _buildEffectiveHeaders(request);
    final method = request.method.name.lowerCase();

    final buffer = StringBuffer();
    buffer.writeln("import httpx\n");
    buffer.writeln("url = '$url'");

    if (headers.isNotEmpty) {
      buffer.writeln("headers = {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("}");
    } else {
      buffer.writeln("headers = {}");
    }

    final dataArg = (request.body != null && request.body!.isNotEmpty)
        ? ", content='''${request.body}'''"
        : "";

    buffer.writeln("with httpx.Client() as client:");
    buffer.writeln(
        "    response = client.$method(url, headers=headers$dataArg)");
    buffer.writeln("    print(response.status_code)");
    buffer.writeln("    print(response.text)");
    return buffer.toString();
  }

  static String _generateGo(ApiRequest request) {
    final url = _buildFullUrl(request);
    final headers = _buildEffectiveHeaders(request);
    final method = request.method.name.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln("package main\n");
    buffer.writeln("import (");
    buffer.writeln('\t"fmt"');
    buffer.writeln('\t"io"');
    buffer.writeln('\t"net/http"');
    if (request.body != null && request.body!.isNotEmpty) {
      buffer.writeln('\t"strings"');
    }
    buffer.writeln(")\n");
    buffer.writeln("func main() {");
    buffer.writeln('\turl := "$url"');

    if (request.body != null && request.body!.isNotEmpty) {
      final escaped = request.body!.replaceAll('`', '` + "`" + `');
      buffer.writeln('\tpayload := strings.NewReader(`$escaped`)');
      buffer.writeln('\treq, err := http.NewRequest("$method", url, payload)');
    } else {
      buffer.writeln('\treq, err := http.NewRequest("$method", url, nil)');
    }

    buffer.writeln("\tif err != nil {");
    buffer.writeln("\t\tpanic(err)");
    buffer.writeln("\t}\n");

    headers.forEach((k, v) => buffer.writeln('\treq.Header.Add("$k", "$v")'));

    buffer.writeln("\n\tres, err := http.DefaultClient.Do(req)");
    buffer.writeln("\tif err != nil {");
    buffer.writeln("\t\tpanic(err)");
    buffer.writeln("\t}");
    buffer.writeln("\tdefer res.Body.Close()\n");
    buffer.writeln("\tbody, _ := io.ReadAll(res.Body)");
    buffer.writeln("\tfmt.Println(res.Status)");
    buffer.writeln("\tfmt.Println(string(body))");
    buffer.writeln("}");
    return buffer.toString();
  }
}

extension on String {
  String lowerCase() => toLowerCase();
}
