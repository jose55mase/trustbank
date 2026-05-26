/// Estado de autenticación del panel administrativo del portafolio.
class PortfolioAuthState {
  final bool isAuthenticated;
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final String? redirectAfterLogin;

  const PortfolioAuthState({
    this.isAuthenticated = false,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.redirectAfterLogin,
  });

  /// Indica si la cuenta está actualmente bloqueada.
  bool get isLockedOut =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  PortfolioAuthState copyWith({
    bool? isAuthenticated,
    int? failedAttempts,
    DateTime? lockoutUntil,
    String? redirectAfterLogin,
  }) {
    return PortfolioAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      redirectAfterLogin: redirectAfterLogin ?? this.redirectAfterLogin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAuthenticated': isAuthenticated,
      'failedAttempts': failedAttempts,
      'lockoutUntil': lockoutUntil?.toIso8601String(),
      'redirectAfterLogin': redirectAfterLogin,
    };
  }

  factory PortfolioAuthState.fromJson(Map<String, dynamic> json) {
    return PortfolioAuthState(
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      failedAttempts: json['failedAttempts'] as int? ?? 0,
      lockoutUntil: json['lockoutUntil'] != null
          ? DateTime.parse(json['lockoutUntil'] as String)
          : null,
      redirectAfterLogin: json['redirectAfterLogin'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PortfolioAuthState) return false;
    return isAuthenticated == other.isAuthenticated &&
        failedAttempts == other.failedAttempts &&
        lockoutUntil == other.lockoutUntil &&
        redirectAfterLogin == other.redirectAfterLogin;
  }

  @override
  int get hashCode =>
      Object.hash(isAuthenticated, failedAttempts, lockoutUntil, redirectAfterLogin);
}
