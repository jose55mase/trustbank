/// Represents a global variable entry from globals.xml.
///
/// [type] is 0 for integer, 1 for decimal.
class GlobalVariable {
  final String name;
  final int type;
  final String value;

  const GlobalVariable({
    required this.name,
    required this.type,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlobalVariable &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          value == other.value;

  @override
  int get hashCode => Object.hash(name, type, value);

  @override
  String toString() =>
      'GlobalVariable(name: $name, type: $type, value: $value)';
}
