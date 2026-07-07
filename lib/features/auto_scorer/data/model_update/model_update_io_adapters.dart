import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_ports.dart';

/// [ConnectivityPort] backed by `connectivity_plus` (#715). Treats wifi and
/// ethernet as unmetered; mobile/none/bluetooth/vpn/other are metered (or no
/// connection), so a background download is skipped.
class ConnectivityPlusPort implements ConnectivityPort {
  final Connectivity _connectivity;

  ConnectivityPlusPort([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> isUnmetered() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }
}

/// [ModelHttpClient] backed by `dart:io HttpClient` (#715) — no http/dio dep.
/// Follows redirects (GitHub release → CDN), enforces HTTPS + a 200 status, and
/// applies a timeout so a hung download can never wedge the launch check.
class HttpClientModelHttp implements ModelHttpClient {
  final Duration timeout;

  const HttpClientModelHttp({this.timeout = const Duration(seconds: 30)});

  @override
  Future<String> getString(Uri url) =>
      _withResponse(url, (r) => r.transform(utf8.decoder).join());

  @override
  Future<Uint8List> getBytes(Uri url) => _withResponse(url, (r) async {
        final builder = BytesBuilder(copy: false);
        await for (final chunk in r) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      });

  /// Runs one HTTPS GET and feeds the response to [consume], always closing the
  /// client afterwards (success or failure) so no connection leaks.
  Future<T> _withResponse<T>(
      Uri url, Future<T> Function(HttpClientResponse) consume) async {
    if (url.scheme != 'https') {
      throw const HttpException('Refusing non-HTTPS model URL');
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(url).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Unexpected status ${response.statusCode}', uri: url);
      }
      return await consume(response);
    } finally {
      client.close(force: true);
    }
  }
}
