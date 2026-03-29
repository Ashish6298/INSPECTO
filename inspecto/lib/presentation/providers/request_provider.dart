import 'package:flutter/material.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/entities/api_response.dart';
import '../../domain/repositories/api_repository.dart';
import '../../data/repositories/api_repository_impl.dart';

class RequestProvider with ChangeNotifier {
  final ApiRepository apiRepository;

  RequestProvider({required this.apiRepository});

  HttpMethod _method = HttpMethod.GET;
  String _url = '';
  Map<String, String> _headers = {};
  Map<String, String> _params = {};
  String? _body;
  String _bodyType = 'none';
  String _bodySubType = 'json';
  String _authType = 'none';
  Map<String, dynamic> _authDetails = {};

  ApiResponse? _response;
  bool _isLoading = false;
  bool _isRefreshing = false;

  // Getters
  HttpMethod get method => _method;
  String get url => _url;
  Map<String, String> get headers => _headers;
  Map<String, String> get params => _params;
  String? get body => _body;
  String get bodyType => _bodyType;
  String get bodySubType => _bodySubType;
  String get authType => _authType;
  Map<String, dynamic> get authDetails => _authDetails;
  ApiResponse? get response => _response;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  // Setters
  void setMethod(HttpMethod method) {
    _method = method;
    notifyListeners();
  }

  void setUrl(String url) {
    _url = url;
    notifyListeners();
  }

  void updateHeader(String key, String value) {
    if (value.isEmpty) {
      _headers.remove(key);
    } else {
      _headers[key] = value;
    }
    notifyListeners();
  }

  void setHeaders(Map<String, String> headers) {
    _headers = Map.from(headers);
    notifyListeners();
  }

  void updateParam(String key, String value) {
    if (value.isEmpty) {
      _params.remove(key);
    } else {
      _params[key] = value;
    }
    notifyListeners();
  }

  void setParams(Map<String, String> params) {
    _params = Map.from(params);
    notifyListeners();
  }

  void setBody(String? body) {
    _body = body;
    notifyListeners();
  }

  void setBodyType(String type) {
    _bodyType = type;
    if (type == 'json' || type == 'graphql') {
      _bodySubType = 'json';
    }
    notifyListeners();
  }

  void setBodySubType(String subType) {
    _bodySubType = subType;
    notifyListeners();
  }

  void setAuthType(String type) {
    _authType = type;
    _authDetails = {}; // Reset details when type changes
    notifyListeners();
  }

  void updateAuthDetail(String key, dynamic value) {
    _authDetails[key] = value;
    notifyListeners();
  }

  String? _environmentId;

  String? get environmentId => _environmentId;

  void setEnvironmentId(String? id) {
    _environmentId = id;
    notifyListeners();
  }

  void clearRequest() {
    _method = HttpMethod.GET;
    _url = '';
    _headers = {};
    _params = {};
    _body = null;
    _bodyType = 'none';
    _bodySubType = 'json';
    _authType = 'none';
    _authDetails = {};
    _response = null;
    _isLoading = false;
    _isRefreshing = false;
    notifyListeners();
  }

  bool validateUrl() {
    if (_url.isEmpty) return false;
    // Simple regex check for http/https
    final urlPattern = RegExp(r"^(https?:\/\/|{{.*?}}).+$");
    return urlPattern.hasMatch(_url);
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    // Simulate a brief refresh delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 1200));
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> sendRequest() async {
    _isLoading = true;
    _response = null;
    notifyListeners();

    try {
      final request = ApiRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        method: _method,
        url: _url,
        headers: _headers,
        params: _params,
        body: _body,
        bodyType: _bodyType,
        bodySubType: _bodySubType,
        authType: _authType,
        authDetails: _authDetails,
      );

      _response = await (apiRepository as ApiRepositoryImpl)
          .executeWithEnvironment(request, _environmentId);
    } catch (e) {
      _response = ApiResponse(
        statusCode: 500,
        body: 'Error: ${e.toString()}',
        headers: {},
        responseTimeMs: 0,
        responseSize: 0,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
