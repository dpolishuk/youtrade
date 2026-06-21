import 'failures.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  });

  Result<R> map<R>(R Function(T value) mapper);

  Result<R> flatMap<R>(Result<R> Function(T value) mapper);

  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  );
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => success(value);

  @override
  Result<R> map<R>(R Function(T value) mapper) => Success(mapper(value));

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) => mapper(value);

  @override
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) => onSuccess(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => failure(this.failure);

  @override
  Result<R> map<R>(R Function(T value) mapper) => Err<R>(failure);

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) => Err<R>(failure);

  @override
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) => onFailure(failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Err<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failure($failure)';
}
