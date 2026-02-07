import 'package:flutter/material.dart';
import '../../domain/entities/environment.dart';
import '../../domain/repositories/environment_repository.dart';

class EnvironmentProvider with ChangeNotifier {
  final EnvironmentRepository repository;

  EnvironmentProvider({required this.repository});

  List<Environment> _environments = [];
  Environment? _activeEnvironment;

  List<Environment> get environments => _environments;
  Environment? get activeEnvironment => _activeEnvironment;

  Future<void> loadEnvironments() async {
    _environments = await repository.getEnvironments();
    notifyListeners();
  }

  void setActiveEnvironment(Environment? environment) {
    _activeEnvironment = environment;
    notifyListeners();
  }

  Future<void> addEnvironment(String name) async {
    final newEnv = Environment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      variables: {},
    );
    await repository.saveEnvironment(newEnv);
    await loadEnvironments();
  }

  Future<void> updateVariable(String envId, String key, String value) async {
    final envIndex = _environments.indexWhere((e) => e.id == envId);
    if (envIndex != -1) {
      final env = _environments[envIndex];
      final newVariables = Map<String, String>.from(env.variables);
      if (value.isEmpty) {
        newVariables.remove(key);
      } else {
        newVariables[key] = value;
      }

      final updatedEnv = Environment(
        id: env.id,
        name: env.name,
        variables: newVariables,
      );

      await repository.saveEnvironment(updatedEnv);
      await loadEnvironments();

      if (_activeEnvironment?.id == envId) {
        _activeEnvironment = updatedEnv;
        notifyListeners();
      }
    }
  }
}
