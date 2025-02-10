class EnvVariable {
  final String name;
  final String? value;
  final bool isGlobal;

  const EnvVariable({
    required this.name,
    required this.value,
    required this.isGlobal,
  });

  factory EnvVariable.fromString(String envString, bool isGlobal) {
    final parts = envString.split('=');
    return EnvVariable(
      name: parts[0].trim(),
      value: (parts.length > 1) ? parts[1].replaceAll('"', '').trim() : null,
      isGlobal: isGlobal,
    );
  }

  // Validation for variable name
  static bool isValidName(String name) {
    final validNameRegExp = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    return validNameRegExp.hasMatch(name) && name.length <= 255;
  }

  // Validation for variable value
  static bool isValidValue(String value) {
    return value.length <= 4096;  // Example length check
  }

  @override
  String toString() {
    return "$name ==> ${value ?? 'null'}\n";
  }
}
