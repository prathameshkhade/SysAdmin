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

  @override
  String toString() {
    return "$name ==> ${value ?? 'null'}\n";
  }
}
