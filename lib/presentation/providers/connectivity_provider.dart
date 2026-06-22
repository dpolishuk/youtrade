import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool isOnline(List<ConnectivityResult> results) =>
    results.isNotEmpty && !results.contains(ConnectivityResult.none);

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  final initialResult = await connectivity.checkConnectivity();
  yield isOnline(initialResult);

  await for (final result in connectivity.onConnectivityChanged) {
    yield isOnline(result);
  }
});

final isDemoModeProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return !(connectivityAsync.valueOrNull ?? true);
});
