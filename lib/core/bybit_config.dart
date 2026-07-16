import 'package:flutter_dotenv/flutter_dotenv.dart';

class BybitConfig {
  static String get apiKey {
    // --dart-define override takes precedence so real demo credentials never
    // need to live in a bundled asset.
    final dartDefine = const String.fromEnvironment(
      'BYBIT_DEMO_API_KEY',
      defaultValue: '',
    );
    if (dartDefine.isNotEmpty) return dartDefine;
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('BYBIT_DEMO_API_KEY') ?? '';
  }

  static String get apiSecret {
    final dartDefine = const String.fromEnvironment(
      'BYBIT_DEMO_API_SECRET',
      defaultValue: '',
    );
    if (dartDefine.isNotEmpty) return dartDefine;
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('BYBIT_DEMO_API_SECRET') ?? '';
  }

  static const String baseUrl = 'https://api-demo.bybit.com';
  static const String wsLinearUrl =
      'wss://stream-demo.bybit.com/v5/public/linear';
  static const String wsSpotUrl = 'wss://stream-demo.bybit.com/v5/public/spot';

  static bool get hasCredentials => apiKey.isNotEmpty && apiSecret.isNotEmpty;
}
