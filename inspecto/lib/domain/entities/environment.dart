class EnvironmentVariable {
  final String key;
  final String value;
  final bool enabled;

  EnvironmentVariable({
    required this.key,
    required this.value,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enabled': enabled,
      };

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariable(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      enabled: json['enabled'] ?? true,
    );
  }
}

class Environment {
  final String id;
  final String name;
  final Map<String, String> variables;
  final List<EnvironmentVariable> variableList;
  final bool isActive;

  Environment({
    required this.id,
    required this.name,
    Map<String, String>? variables,
    List<EnvironmentVariable>? variableList,
    this.isActive = false,
  })  : variables = variables ??
            {
              for (final v in (variableList ?? []))
                if (v.enabled) v.key: v.value
            },
        variableList = variableList ??
            (variables ?? {})
                .entries
                .map((e) => EnvironmentVariable(key: e.key, value: e.value))
                .toList();
}
