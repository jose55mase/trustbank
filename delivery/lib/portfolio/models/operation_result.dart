/// Tipos de fallo para operaciones del portafolio.
enum FailureType {
  network,
  validation,
  authentication,
  storage,
  unknown,
}

/// Resultado de operaciones que pueden fallar.
sealed class OperationResult<T> {
  const OperationResult();
}

/// Resultado exitoso con datos.
class Success<T> extends OperationResult<T> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Success<T>) return false;
    return data == other.data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// Resultado fallido con mensaje y tipo de error.
class Failure<T> extends OperationResult<T> {
  final String message;
  final FailureType type;
  const Failure(this.message, this.type);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Failure<T>) return false;
    return message == other.message && type == other.type;
  }

  @override
  int get hashCode => Object.hash(message, type);
}
