/// Represents the economy configuration for a guild/server.
///
/// Contains settings for zombie kill rewards, melee weapon classification,
/// and whether the economy system is enabled.
class EconomyConfigModel {
  final int coinsPerZombieKill;
  final List<String> meleeWeapons;
  final bool enabled;

  const EconomyConfigModel({
    required this.coinsPerZombieKill,
    required this.meleeWeapons,
    required this.enabled,
  });

  factory EconomyConfigModel.fromJson(Map<String, dynamic> json) {
    return EconomyConfigModel(
      coinsPerZombieKill: json['coinsPerZombieKill'] as int? ?? 10,
      meleeWeapons: (json['meleeWeapons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'coinsPerZombieKill': coinsPerZombieKill,
        'meleeWeapons': meleeWeapons,
        'enabled': enabled,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EconomyConfigModel &&
          runtimeType == other.runtimeType &&
          coinsPerZombieKill == other.coinsPerZombieKill &&
          _listEquals(meleeWeapons, other.meleeWeapons) &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(
        coinsPerZombieKill,
        Object.hashAll(meleeWeapons),
        enabled,
      );

  @override
  String toString() => 'EconomyConfigModel('
      'coinsPerZombieKill: $coinsPerZombieKill, '
      'meleeWeapons: $meleeWeapons, '
      'enabled: $enabled)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
