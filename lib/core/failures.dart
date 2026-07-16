abstract class Failure {
  const Failure();

  String get message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure(this.message);

  @override
  final String message;
}

final class ParseFailure extends Failure {
  const ParseFailure(this.message);

  @override
  final String message;
}

final class UnsupportedFeatureFailure extends Failure {
  const UnsupportedFeatureFailure(this.venue, this.feature);

  final String venue;
  final String feature;

  @override
  String get message => '$feature is not supported by $venue';
}

final class UnknownFailure extends Failure {
  const UnknownFailure(this.message, {this.error});

  @override
  final String message;
  final Object? error;
}
