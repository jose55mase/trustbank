import 'package:flutter/foundation.dart';

import 'dayz_type_flags.dart';

/// Represents a single item type entry from types.xml.
class DayzType {
  final String name;
  final int nominal;
  final int lifetime;
  final int restock;
  final int min;
  final int quantmin;
  final int quantmax;
  final int cost;
  final DayzTypeFlags flags;
  final String? category;
  final List<String> usages;
  final List<String> values;
  final List<String> tags;

  const DayzType({
    required this.name,
    required this.nominal,
    required this.lifetime,
    required this.restock,
    required this.min,
    required this.quantmin,
    required this.quantmax,
    required this.cost,
    required this.flags,
    this.category,
    this.usages = const [],
    this.values = const [],
    this.tags = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayzType &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          nominal == other.nominal &&
          lifetime == other.lifetime &&
          restock == other.restock &&
          min == other.min &&
          quantmin == other.quantmin &&
          quantmax == other.quantmax &&
          cost == other.cost &&
          flags == other.flags &&
          category == other.category &&
          listEquals(usages, other.usages) &&
          listEquals(values, other.values) &&
          listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        name,
        nominal,
        lifetime,
        restock,
        min,
        quantmin,
        quantmax,
        cost,
        flags,
        category,
        Object.hashAll(usages),
        Object.hashAll(values),
        Object.hashAll(tags),
      );

  DayzType copyWith({
    String? name,
    int? nominal,
    int? lifetime,
    int? restock,
    int? min,
    int? quantmin,
    int? quantmax,
    int? cost,
    DayzTypeFlags? flags,
    Object? category = _unset,
    List<String>? usages,
    List<String>? values,
    List<String>? tags,
  }) {
    return DayzType(
      name: name ?? this.name,
      nominal: nominal ?? this.nominal,
      lifetime: lifetime ?? this.lifetime,
      restock: restock ?? this.restock,
      min: min ?? this.min,
      quantmin: quantmin ?? this.quantmin,
      quantmax: quantmax ?? this.quantmax,
      cost: cost ?? this.cost,
      flags: flags ?? this.flags,
      category: category == _unset ? this.category : category as String?,
      usages: usages ?? this.usages,
      values: values ?? this.values,
      tags: tags ?? this.tags,
    );
  }

  static const Object _unset = Object();

  @override
  String toString() => 'DayzType(name: $name, nominal: $nominal, '
      'lifetime: $lifetime, restock: $restock, min: $min, '
      'quantmin: $quantmin, quantmax: $quantmax, cost: $cost, '
      'flags: $flags, category: $category, '
      'usages: $usages, values: $values, tags: $tags)';
}
