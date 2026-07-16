import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/bybit_config.dart';

void main() {
  group('BybitConfig', () {
    setUp(() {
      dotenv.testLoad(fileInput: '');
    });

    test('loads api key from dotenv', () {
      dotenv.env['BYBIT_DEMO_API_KEY'] = 'TESTKEY123';
      expect(BybitConfig.apiKey, 'TESTKEY123');
    });

    test('loads api secret from dotenv', () {
      dotenv.env['BYBIT_DEMO_API_SECRET'] = 'TESTSECRET456';
      expect(BybitConfig.apiSecret, 'TESTSECRET456');
    });

    test('returns empty strings when env not loaded', () {
      expect(BybitConfig.apiKey, isEmpty);
      expect(BybitConfig.apiSecret, isEmpty);
      expect(BybitConfig.hasCredentials, isFalse);
    });

    test('base url is demo endpoint', () {
      expect(BybitConfig.baseUrl, 'https://api-demo.bybit.com');
    });

    test('ws linear url is demo stream', () {
      expect(
        BybitConfig.wsLinearUrl,
        'wss://stream-demo.bybit.com/v5/public/linear',
      );
    });

    test('hasCredentials is true when both key and secret are set', () {
      dotenv.env['BYBIT_DEMO_API_KEY'] = 'TESTKEY123';
      dotenv.env['BYBIT_DEMO_API_SECRET'] = 'TESTSECRET456';
      expect(BybitConfig.hasCredentials, isTrue);
    });
  });
}
