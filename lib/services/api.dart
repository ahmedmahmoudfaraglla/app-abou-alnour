import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// عدّل الدومين لو محتاج
const String BASE_URL = 'https://msncare.com';

class TraccarApi {
  TraccarApi(this._email, this._password);
  final String _email;
  final String _password;

  Map<String, String> get _authHeader => {
        'Authorization': 'Basic ${base64.encode(utf8.encode("$_email:$_password"))}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<List<Device>> devices() async {
    final r = await http.get(Uri.parse('$BASE_URL/api/devices'), headers: _authHeader);
    if (r.statusCode != 200) throw Exception('Devices failed: ${r.statusCode}');
    final list = (json.decode(r.body) as List).cast<Map<String, dynamic>>();
    return list.map(Device.fromJson).toList();
  }

  Future<List<Position>> lastPositions({int? deviceId}) async {
    final uri = deviceId == null
        ? Uri.parse('$BASE_URL/api/positions')
        : Uri.parse('$BASE_URL/api/positions?deviceId=$deviceId');
    final r = await http.get(uri, headers: _authHeader);
    if (r.statusCode != 200) throw Exception('Positions failed: ${r.statusCode}');
    final list = (json.decode(r.body) as List).cast<Map<String, dynamic>>();
    return list.map(Position.fromJson).toList();
  }

  Future<List<Position>> route({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final f = Uri.encodeQueryComponent(from.toUtc().toIso8601String());
    final t = Uri.encodeQueryComponent(to.toUtc().toIso8601String());
    final uri = Uri.parse('$BASE_URL/api/reports/route?deviceId=$deviceId&from=$f&to=$t');
    final r = await http.get(uri, headers: _authHeader);
    if (r.statusCode != 200) throw Exception('Route failed: ${r.statusCode}');
    final list = (json.decode(r.body) as List).cast<Map<String, dynamic>>();
    return list.map(Position.fromJson).toList();
  }

  Future<void> sendEngineCommand({required int deviceId, required bool stop}) async {
    // يحاول نوع قياسي، ولو مش مدعوم يقعّد Custom
    final body = json.encode({'deviceId': deviceId, 'type': stop ? 'engineStop' : 'engineResume'});
    final r = await http.post(Uri.parse('$BASE_URL/api/commands/send'), headers: _authHeader, body: body);
    if (r.statusCode == 200) return;
    // fallback كـ custom (قد يفشل حسب البروتوكول)
    final custom = json.encode({
      'deviceId': deviceId,
      'type': 'custom',
      'attributes': {'data': stop ? 'engineStop' : 'engineResume'}
    });
    final r2 = await http.post(Uri.parse('$BASE_URL/api/commands/send'), headers: _authHeader, body: custom);
    if (r2.statusCode != 200) {
      throw Exception('Command failed: ${r.statusCode} / ${r2.statusCode}');
    }
  }

  /// polling بسيط كل 5 ثواني للحصول على أحدث إحداثيات
  Stream<Position?> livePositionStream(int deviceId) async* {
    while (true) {
      try {
        final list = await lastPositions(deviceId: deviceId);
        yield list.isNotEmpty ? list.first : null;
      } catch (_) {
        yield null;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// حفظ بيانات الدخول
  static Future<void> saveCreds(String email, String password) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('email', email);
    await sp.setString('password', password);
  }

  static Future<(String?, String?)> readCreds() async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getString('email'), sp.getString('password'));
  }

  static Future<void> clearCreds() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('email');
    await sp.remove('password');
  }
}
