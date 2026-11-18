import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/entities/api_response.dart';
import '../../domain/entities/execution_engine.dart';
import '../../domain/entities/variable_extractor.dart';
import '../../domain/repositories/api_repository.dart';
import '../../data/repositories/api_repository_impl.dart';
import '../../data/datasources/sse_stream_data_source.dart';
import 'environment_provider.dart';

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
  List<VariableExtractor> _extractors = [];
  ExecutionEngine _executionEngine = ExecutionEngine.direct;
  bool _isStreaming = false;
  bool _isStreamMode = false;
  String _streamedText = '';
  String _rawStreamLog = '';
  int _streamChunks = 0;
  int _streamElapsedMs = 0;
  StreamSubscription<SseEvent>? _streamSubscription;
  Timer? _streamTimer;
  SseStreamDataSource? sseDataSource;

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
  List<VariableExtractor> get extractors => _extractors;
  ExecutionEngine get executionEngine => _executionEngine;
  bool get isStreaming => _isStreaming;
  bool get isStreamMode => _isStreamMode;
  String get streamedText => _streamedText;
  String get rawStreamLog => _rawStreamLog;
  int get streamChunks => _streamChunks;
  int get streamElapsedMs => _streamElapsedMs;
  ApiResponse? get response => _response;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  // Setters
  void setStreamMode(bool enabled) {
    _isStreamMode = enabled;
    notifyListeners();
  }

  void setExecutionEngine(ExecutionEngine engine) {
    _executionEngine = engine;
    notifyListeners();
  }

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

  void addExtractor(VariableExtractor extractor) {
    _extractors.add(extractor);
    notifyListeners();
  }

  void updateExtractor(int index, VariableExtractor extractor) {
    if (index >= 0 && index < _extractors.length) {
      _extractors[index] = extractor;
      notifyListeners();
    }
  }

  void removeExtractor(int index) {
    if (index >= 0 && index < _extractors.length) {
      _extractors.removeAt(index);
      notifyListeners();
    }
  }

  void setExtractors(List<VariableExtractor> extractors) {
    _extractors = List.from(extractors);
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
    _extractors = [];
    _response = null;
    _isLoading = false;
    _isRefreshing = false;
    notifyListeners();
  }

  void loadRequest(ApiRequest request) {
    _method = request.method;
    _url = request.url;
    _headers = Map<String, String>.from(request.headers);
    _params = Map<String, String>.from(request.params);
    _body = request.body;
    _bodyType = request.bodyType ?? 'none';
    _bodySubType = request.bodySubType ?? 'json';
    _authType = request.authType ?? 'none';
    _authDetails = Map<String, dynamic>.from(request.authDetails ?? {});
    _extractors = List.from(request.extractors ?? []);
    _response = null;
    _isLoading = false;
    _isRefreshing = false;
    notifyListeners();
  }

  ApiRequest getCurrentRequest({String? id}) {
    return ApiRequest(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      method: _method,
      url: _url,
      headers: Map<String, String>.from(_headers),
      params: Map<String, String>.from(_params),
      body: _body,
      bodyType: _bodyType,
      bodySubType: _bodySubType,
      authType: _authType,
      authDetails: Map<String, dynamic>.from(_authDetails),
      extractors: List.from(_extractors),
    );
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

  bool _isEventStreamRequest() {
    for (final entry in _headers.entries) {
      if (entry.key.toLowerCase() == 'accept' &&
          entry.value.toLowerCase().contains('text/event-stream')) {
        return true;
      }
    }
    return false;
  }

  Future<void> sendRequest({
    EnvironmentProvider? environmentProvider,
    Function(ApiRequest request, ApiResponse response)? onResponseReceived,
    Function(String variableName, String value)? onVariableExtracted,
  }) async {
    if (_isStreamMode || _isEventStreamRequest()) {
      return sendStreamRequest(
        environmentProvider: environmentProvider,
        onResponseReceived: onResponseReceived,
        onVariableExtracted: onVariableExtracted,
      );
    }

    _isLoading = true;
    _response = null;
    notifyListeners();

    ApiRequest? executedRequest;
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
        extractors: List.from(_extractors),
      );
      executedRequest = request;

      final activeEnv = environmentProvider?.activeEnvironment;
      _response = await (apiRepository as ApiRepositoryImpl)
          .executeWithEnvironment(
        request,
        _environmentId ?? activeEnv?.id,
        engine: _executionEngine,
        environmentVariables: activeEnv?.variables,
      );

      // Evaluate post-response variable extractors if request succeeded
      if (_response != null &&
          _response!.statusCode >= 200 &&
          _response!.statusCode < 300 &&
          environmentProvider != null &&
          environmentProvider.activeEnvironment != null) {
        for (final extractor in _extractors) {
          if (extractor.enabled &&
              extractor.targetVariable.trim().isNotEmpty &&
              extractor.pathOrKey.trim().isNotEmpty) {
            final extracted =
                VariableExtractor.extractFromResponse(extractor, _response!);
            if (extracted != null && extracted.isNotEmpty) {
              final cleanKey = extractor.targetVariable
                  .replaceAll(RegExp(r'[{}]'), '')
                  .trim();
              await environmentProvider.updateVariable(
                environmentProvider.activeEnvironment!.id,
                cleanKey,
                extracted,
              );
              onVariableExtracted?.call(cleanKey, extracted);
            }
          }
        }
      }
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
      if (executedRequest != null && _response != null) {
        onResponseReceived?.call(executedRequest, _response!);
      }
    }
  }

  Future<void> sendStreamRequest({
    EnvironmentProvider? environmentProvider,
    Function(ApiRequest request, ApiResponse response)? onResponseReceived,
    Function(String variableName, String value)? onVariableExtracted,
  }) async {
    _isLoading = true;
    _isStreaming = true;
    _response = null;
    _streamedText = '';
    _rawStreamLog = '';
    _streamChunks = 0;
    _streamElapsedMs = 0;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _streamElapsedMs = stopwatch.elapsedMilliseconds;
      notifyListeners();
    });

    ApiRequest? executedRequest;
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
        extractors: List.from(_extractors),
      );
      executedRequest = request;

      _isLoading = false;
      notifyListeners();

      final sseSource = sseDataSource ?? SseStreamDataSource();
      final activeEnv = environmentProvider?.activeEnvironment;

      final stream = sseSource.streamRequest(
        request,
        environmentVariables: activeEnv?.variables,
      );

      final completer = Completer<void>();
      _streamSubscription = stream.listen(
        (event) {
          _streamChunks++;
          final delta = SseStreamDataSource.extractLlmDelta(event.data);
          _streamedText += delta;
          _rawStreamLog +=
              'event: ${event.event ?? "message"}\ndata: ${event.data}\n\n';
          notifyListeners();
          if (event.isDone) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        onError: (err) {
          _rawStreamLog += '\n[Stream Error]: $err\n';
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future;
    } catch (e) {
      _rawStreamLog += '\n[Request Error]: $e\n';
    } finally {
      stopwatch.stop();
      _streamElapsedMs = stopwatch.elapsedMilliseconds;
      _streamTimer?.cancel();
      _streamTimer = null;
      _streamSubscription?.cancel();
      _streamSubscription = null;
      _isStreaming = false;

      _response = ApiResponse(
        statusCode: 200,
        body: _streamedText.isNotEmpty ? _streamedText : _rawStreamLog,
        headers: {'content-type': 'text/event-stream'},
        responseTimeMs: _streamElapsedMs,
        responseSize: _streamedText.length,
      );
      _isLoading = false;
      notifyListeners();

      if (executedRequest != null && _response != null) {
        onResponseReceived?.call(executedRequest, _response!);
      }
    }
  }

  void stopStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamTimer?.cancel();
    _streamTimer = null;
    _isStreaming = false;

    _response ??= ApiResponse(
      statusCode: 200,
      body: _streamedText.isNotEmpty ? _streamedText : _rawStreamLog,
      headers: {'content-type': 'text/event-stream'},
      responseTimeMs: _streamElapsedMs,
      responseSize: _streamedText.length,
    );
    notifyListeners();
  }
}
