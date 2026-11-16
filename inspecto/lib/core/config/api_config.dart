import '.env.dart';

class ApiConfig {
  // Set to true for local development (10.0.2.2)
  // Set to false for production (Vercel)
  static const bool useLocal = false;

  static String get baseUrl => useLocal ? Env.localUrl : Env.productionUrl;
}
