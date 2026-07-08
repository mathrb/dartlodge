import 'dart:typed_data';

/// Network-metering signal for the OTA download gate (#715). Kept as a tiny
/// interface so the service can be unit-tested with a fake instead of the real
/// `connectivity_plus` plugin (which needs a platform channel).
abstract class ConnectivityPort {
  /// True when the device is on an unmetered connection (wifi/ethernet) — the
  /// only condition under which a silent background model download is allowed.
  Future<bool> isUnmetered();
}

/// The minimal HTTPS surface the OTA pipeline needs: fetch the manifest text and
/// download the model bytes. Abstracted so tests inject canned responses instead
/// of hitting the network; the production impl uses `dart:io HttpClient`.
abstract class ModelHttpClient {
  /// GET [url] and return the body as a string (the manifest JSON).
  Future<String> getString(Uri url);

  /// GET [url] and return the raw bytes (the model binary), following redirects.
  Future<Uint8List> getBytes(Uri url);
}
