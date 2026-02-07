import '../entities/environment.dart';

abstract class EnvironmentRepository {
  Future<List<Environment>> getEnvironments();
  Future<void> saveEnvironment(Environment environment);
  Future<void> deleteEnvironment(String id);
}
