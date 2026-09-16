import '../errors/app_failure.dart';

/// Minimal Result type so service calls can return either a value or a
/// typed failure without exceptions leaking into UI code.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => this is Success<T> ? (this as Success<T>).value : null;
  AppFailure? get failureOrNull =>
      this is Failure<T> ? (this as Failure<T>).failure : null;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.value);
    if (self is Failure<T>) return failure(self.failure);
    throw StateError('Unknown Result subtype');
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}
