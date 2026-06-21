import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../../../core/failures.dart';
import '../../../../core/result.dart';
import '../../../../domain/auth/exchange_connection_checker.dart';
import '../../../../domain/auth/exchange_credentials.dart';
import '../../../../domain/entities/venue.dart';

final class ExchangeConnectionCheckerImpl implements ExchangeConnectionChecker {
  ExchangeConnectionCheckerImpl({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<Result<bool>> check(ExchangeCredentials credentials) async {
    return switch (credentials.venue) {
      Venue.binance => _checkBinance(credentials),
      Venue.bybit => _checkBybit(credentials),
      Venue.okx || Venue.coinbase => const Err<bool>(
        UnsupportedFeatureFailure(
          'Credential test',
          '${credentials.venue.displayName} connection test',
        ),
      ),
    };
  }

  Future<Result<bool>> _checkBinance(ExchangeCredentials credentials) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      const recvWindow = '5000';
      final query = 'timestamp=$timestamp&recvWindow=$recvWindow';
      final signature = _hmacSha256(query, credentials.secret);
      final uri = Uri.parse(
        'https://api.binance.com/api/v3/account?$query&signature=$signature',
      );

      final response = await _httpClient.get(
        uri,
        headers: {'X-MBX-APIKEY': credentials.apiKey},
      );

      if (response.statusCode == 200) {
        return const Success(true);
      }

      return Err<bool>(
        NetworkFailure('Binance connection failed: ${response.statusCode}'),
      );
    } on FormatException catch (e) {
      return Err<bool>(ParseFailure('Binance response parse failed: $e'));
    } on Exception catch (e) {
      return Err<bool>(NetworkFailure('Binance connection request failed: $e'));
    }
  }

  Future<Result<bool>> _checkBybit(ExchangeCredentials credentials) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      const recvWindow = '5000';
      const query = 'accountType=UNIFIED';
      final payload = '$timestamp${credentials.apiKey}$recvWindow$query';
      final signature = _hmacSha256(payload, credentials.secret);

      final uri = Uri.parse(
        'https://api.bybit.com/v5/account/wallet-balance?$query',
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          'X-BAPI-API-KEY': credentials.apiKey,
          'X-BAPI-TIMESTAMP': timestamp,
          'X-BAPI-SIGN': signature,
          'X-BAPI-RECV-WINDOW': recvWindow,
        },
      );

      if (response.statusCode == 200) {
        return const Success(true);
      }

      return Err<bool>(
        NetworkFailure('Bybit connection failed: ${response.statusCode}'),
      );
    } on FormatException catch (e) {
      return Err<bool>(ParseFailure('Bybit response parse failed: $e'));
    } on Exception catch (e) {
      return Err<bool>(NetworkFailure('Bybit connection request failed: $e'));
    }
  }

  String _hmacSha256(String data, String key) {
    final bytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(bytes);
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
