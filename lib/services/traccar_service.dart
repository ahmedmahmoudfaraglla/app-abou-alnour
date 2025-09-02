import 'dart:convert';
import 'package:http/http.dart' as http;

class TraccarService {
  final String baseUrl; // مثال: https://msncare.com  (بدون /api)
  String? _cookie;      // لحفظ جلسة تسجيل الدخول

  TraccarService(this.baseUrl);

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// تسجيل دخول باستخدام JSON إلى /api/session
  Future<void> login(String email, String password) async {
    final res = await http.post(
      _u('/api/session'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw Exception('Login failed (${res.statusCode})');
    }
    // التقط الكوكي لجلسة API
    final setCookie = res.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      throw Exception('Login ok but no session cookie');
    }
    // خذ أول كوكي فقط
    _cookie = setCookie.split(',').first.split(';').first.trim();
  }

  Map<String, String> _authHeaders() {
    if (_cookie == null) throw Exception('Not logged in');
    return {
      'Accept': 'application/json',
      'Cookie': _cookie!,
    };
  }

  /// قراءة الأجهزة
  Future<List<dynamic>> getDevices() async {
    final res = await http.get(_u('/api/devices'), headers: _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('Devices failed (${res.statusCode})');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  /// إرسال أمر للمحرّك (engineStop / engineResume)
  Future<void> sendCommand(int deviceId, String type) async {
    final res = await http.post(
      _u('/api/commands/send'),
      headers: {..._authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId, 'type': type}),
    );
    if (res.statusCode != 200) {
      throw Exception('Command $type failed (${res.statusCode})');
    }
  }
}
