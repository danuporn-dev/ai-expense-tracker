import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Android emulator: 10.0.2.2 | Chrome: localhost | Real phone: YOUR_PC_LAN_IP
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2/mobileapp_backend/backend/api/index.php',
);

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class ApiClient extends ChangeNotifier {
  ApiClient({http.Client? client, FlutterSecureStorage? storage})
    : _http = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();
  final http.Client _http;
  final FlutterSecureStorage _storage;
  String? token;
  Map<String, dynamic>? user;
  bool ready = false;
  String? restoreError;
  bool get isLoggedIn => token != null && user != null;

  @override
  void dispose() {
    _http.close();
    super.dispose();
  }

  Future<void> restore() async {
    ready = false;
    restoreError = null;
    notifyListeners();
    try {
      token = await _storage.read(key: 'access_token');
      if (token != null) {
        final response = await request('auth/me');
        user = Map<String, dynamic>.from(response['user']);
      }
    } on ApiException catch (e) {
      if (e.status == 401) {
        token = null;
        user = null;
        await _storage.delete(key: 'access_token');
      } else {
        restoreError = 'โหลดบัญชีไม่ได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';
      }
    } catch (_) {
      restoreError = 'โหลดบัญชีไม่ได้ กรุณาลองอีกครั้ง';
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Uri _uri(String route, [Map<String, String>? params]) => Uri.parse(
    apiBaseUrl,
  ).replace(queryParameters: {'route': route, ...?params});

  Future<Map<String, dynamic>> request(
    String route, {
    String method = 'GET',
    Map<String, String>? query,
    Map<String, dynamic>? data,
  }) async {
    final uri = _uri(route, query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      late http.Response result;
      final b = jsonEncode(data ?? <String, dynamic>{});
      switch (method) {
        case 'POST':
          result = await _http
              .post(uri, headers: headers, body: b)
              .timeout(const Duration(seconds: 25));
        case 'PUT':
          result = await _http
              .put(uri, headers: headers, body: b)
              .timeout(const Duration(seconds: 25));
        case 'DELETE':
          result = await _http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 25));
        default:
          result = await _http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 25));
      }
      dynamic decoded;
      try {
        decoded = jsonDecode(result.body);
      } catch (_) {
        throw ApiException('เซิร์ฟเวอร์ตอบกลับไม่ถูกต้อง', result.statusCode);
      }
      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw ApiException(
          decoded is Map
              ? '${decoded['error'] ?? 'เกิดข้อผิดพลาด'}'
              : 'เกิดข้อผิดพลาด',
          result.statusCode,
        );
      }
      if (decoded is! Map<String, dynamic>)
        throw ApiException('ข้อมูลตอบกลับไม่ถูกต้อง');
      return decoded;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบ XAMPP และ API_BASE_URL',
      );
    }
  }

  Future<Map<String, dynamic>> scanReceipt(XFile picture) async {
    final uri = _uri('ai/scan');
    try {
      final req = http.MultipartRequest('POST', uri);
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      final bytes = await picture.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: picture.name),
      );
      final stream = await _http.send(req).timeout(const Duration(seconds: 65));
      final result = await http.Response.fromStream(stream);
      final decoded = jsonDecode(result.body);
      if (decoded is! Map<String, dynamic>)
        throw ApiException('AI ส่งข้อมูลไม่ถูกต้อง');
      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw ApiException(
          '${decoded['error'] ?? 'สแกนไม่สำเร็จ'}',
          result.statusCode,
        );
      }
      return decoded;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('สแกนไม่ได้ ตรวจสอบเครือข่าย / การตั้งค่า AI API');
    }
  }

  Future<Uint8List> receiptImage(int id) async {
    final res = await _http.get(
      _uri('receipts/image', {'id': '$id'}),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw ApiException('โหลดรูปบิลไม่ได้');
    return res.bodyBytes;
  }

  Future<void> payInstallment(
    int paymentId,
    String paidDate, {
    XFile? proof,
  }) async {
    if (proof == null) {
      await request(
        'installments/pay',
        method: 'POST',
        data: {'payment_id': paymentId, 'paid_date': paidDate},
      );
      return;
    }
    try {
      final bytes = await proof.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        throw ApiException('หลักฐานต้องไม่เกิน 2 MB');
      }
      final req = http.MultipartRequest('POST', _uri('installments/pay'));
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.fields.addAll({'payment_id': '$paymentId', 'paid_date': paidDate});
      req.files.add(
        http.MultipartFile.fromBytes('proof', bytes, filename: proof.name),
      );
      final response = await http.Response.fromStream(
        await _http.send(req).timeout(const Duration(seconds: 25)),
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw ApiException('เซิร์ฟเวอร์ตอบกลับไม่ถูกต้อง');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          '${decoded['error'] ?? 'บันทึกไม่สำเร็จ'}',
          response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('บันทึกไม่ได้ ตรวจสอบการเชื่อมต่อเซิร์ฟเวอร์');
    }
  }

  Future<Uint8List> installmentProof(int paymentId) async {
    try {
      final response = await _http
          .get(
            _uri('installments/proof', {'id': '$paymentId'}),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw ApiException('โหลดหลักฐานไม่ได้', response.statusCode);
      }
      return response.bodyBytes;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('โหลดหลักฐานไม่ได้ ตรวจสอบการเชื่อมต่อ');
    }
  }

  Future<void> signIn(String email, String password) async {
    final res = await request(
      'auth/login',
      method: 'POST',
      data: {'email': email, 'password': password},
    );
    await _saveSession(res);
  }

  Future<void> register(String name, String email, String password) async {
    final res = await request(
      'auth/register',
      method: 'POST',
      data: {'name': name, 'email': email, 'password': password},
    );
    await _saveSession(res);
  }

  Future<void> updateProfile({
    required String name,
    String? password,
    String? currentPassword,
    XFile? avatar,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _uri('auth/profile'));
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.fields['name'] = name;
      if (password != null && password.isNotEmpty) {
        req.fields['password'] = password;
        req.fields['current_password'] = currentPassword ?? '';
      }
      if (avatar != null) {
        final bytes = await avatar.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024)
          throw ApiException('รูปโปรไฟล์ต้องมีขนาดไม่เกิน 2 MB');
        req.files.add(
          http.MultipartFile.fromBytes('avatar', bytes, filename: avatar.name),
        );
      }
      final stream = await _http.send(req).timeout(const Duration(seconds: 25));
      final result = await http.Response.fromStream(stream);
      final decoded = jsonDecode(result.body);
      if (decoded is! Map<String, dynamic>)
        throw ApiException('ข้อมูลตอบกลับไม่ถูกต้อง');
      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw ApiException(
          '${decoded['error'] ?? 'บันทึกข้อมูลไม่สำเร็จ'}',
          result.statusCode,
        );
      }
      user = Map<String, dynamic>.from(decoded['user']);
      notifyListeners();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('บันทึกไม่ได้ ตรวจสอบการเชื่อมต่อเซิร์ฟเวอร์');
    }
  }

  Uint8List? get avatarBytes {
    final encoded = user?['avatar_base64'];
    if (encoded is! String || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> response) async {
    token = response['token'] as String;
    user = Map<String, dynamic>.from(response['user']);
    await _storage.write(key: 'access_token', value: token);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await request('auth/logout', method: 'POST');
    } catch (_) {}
    token = null;
    user = null;
    await _storage.delete(key: 'access_token');
    notifyListeners();
  }
}

final api = ApiClient();
