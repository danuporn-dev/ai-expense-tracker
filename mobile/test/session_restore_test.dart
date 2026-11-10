import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_wallet_ai/core/api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  setUp(() => FlutterSecureStorage.setMockInitialValues({'access_token': 'saved-token'}));

  for (final failure in ['network', 'timeout', '500', '502', 'invalid JSON']) {
    test('restore preserves token after $failure and can retry', () async {
      bool recovered = false;
      final client = ApiClient(client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer saved-token');
        if (recovered) return http.Response(jsonEncode({'user': {'id': 1, 'name': 'Test'}}), 200);
        if (failure == 'network') throw http.ClientException('offline');
        if (failure == 'timeout') throw TimeoutException('timeout');
        if (failure == 'invalid JSON') return http.Response('<html>error</html>', 200);
        return http.Response('<html>unavailable</html>', int.parse(failure));
      }));
      await client.restore();
      expect(client.ready, isTrue);
      expect(client.restoreError, isNotNull);
      expect(client.token, 'saved-token');
      expect(await storage.read(key: 'access_token'), 'saved-token');
      recovered = true;
      await client.restore();
      expect(client.restoreError, isNull);
      expect(client.isLoggedIn, isTrue);
      client.dispose();
    });
  }

  test('expired session clears token even when 401 body is not JSON', () async {
    final client = ApiClient(client: MockClient((_) async => http.Response('Unauthorized', 401)));
    await client.restore();
    expect(client.ready, isTrue);
    expect(client.restoreError, isNull);
    expect(client.isLoggedIn, isFalse);
    expect(client.token, isNull);
    expect(await storage.read(key: 'access_token'), isNull);
    client.dispose();
  });
}
