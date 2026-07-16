import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';

void main() {
  group('Result', () {
    test('map transforms success value', () {
      const Result<int> result = Success(2);
      final Result<String> mapped = result.map((v) => 'value: $v');
      expect(mapped, const Success<String>('value: 2'));
    });

    test('map preserves failure', () {
      const failure = NetworkFailure('no connection');
      const Result<int> result = Err<int>(failure);
      final Result<String> mapped = result.map((v) => 'value: $v');
      expect(mapped, const Err<String>(failure));
    });

    test('flatMap short-circuits on failure', () {
      const failure = ParseFailure('invalid json');
      const Result<int> result = Err<int>(failure);
      final Result<int> chained = result.flatMap((v) => Success(v * 2));
      expect(chained, const Err<int>(failure));
    });

    test('flatMap chains success values', () {
      const Result<int> result = Success(3);
      final Result<int> chained = result.flatMap((v) => Success(v * 2));
      expect(chained, const Success<int>(6));
    });

    test('fold returns left on failure', () {
      const failure = UnsupportedFeatureFailure('venue', 'ws trades');
      const Result<int> result = Err<int>(failure);
      final String value = result.fold(
        (f) => 'failed: ${f.message}',
        (v) => 'success: $v',
      );
      expect(value, 'failed: ws trades is not supported by venue');
    });

    test('fold returns right on success', () {
      const Result<int> result = Success(42);
      final String value = result.fold(
        (f) => 'failed: ${f.message}',
        (v) => 'success: $v',
      );
      expect(value, 'success: 42');
    });

    test('when invokes success branch with the exact typed value', () {
      const Result<int> result = Success(42);
      final value = result.when(
        success: (v) => 'ok:$v',
        failure: (f) => 'err:${f.message}',
      );
      expect(value, 'ok:42');
    });

    test('when invokes failure branch with the exact typed failure', () {
      const failure = NetworkFailure('offline');
      const Result<int> result = Err(failure);
      final value = result.when(
        success: (v) => 'ok:$v',
        failure: (f) => 'err:${f.message}',
      );
      expect(value, 'err:offline');
    });

    test('when preserves generic type through both branches', () {
      const Result<String> result = Success('data');
      final int value = result.when(
        success: (s) => s.length,
        failure: (_) => -1,
      );
      expect(value, 4);
    });
  });
}
