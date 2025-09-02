import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class Session {
  final String cookie; // JSESSIONID=...
  Session(this.cookie);
}

class TraccarApi {
  final _client = http.Client();

  String _fixUser(String input) {
    // لو المستخدم دخل رقم فقط نضيف الدومين الداخلي
    if (!input.contains('@')) {
      return '${input}@${AppConfig.phoneDomain}';
    }
    return input;
  }

  Future<Session> login(String userOrPhone, String password) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/session');
    final body = jsonEncode({
      'email': _fixUser(userOrPhone),
      'password': password,
    });
    final res = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode == 200) {
      final setCookie = res.headers['set-cookie'] ?? '';
      final js = setCookie.split(';').firstWhere((v) => v.startsWith('JSESSIONID='), orElse: () => '');
      if (js.isEmpty) {
        throw Exception('No session cookie');
      }
      return Session(js);
    }
    if (res.statusCode == 415) {
      throw Exception('Unsupported Media Type (تأكّد من Content-Type: application/json)');
    }
    throw Exception('Login failed: ${res.statusCode} ${res.body}');
  }

  Future<List<dynamic>> devices(Session s) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/devices');
    final res = await _client.get(url, headers: {'Cookie': s.cookie});
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    throw Exception('Devices failed: ${res.statusCode}');
  }

  Future<Map<int, Map<String, dynamic>>> latestPositions(Session s) async {
    // هنجِب الأجهزة ثم نجيب الـ positions IDs
    final devs = await devices(s);
    final ids = <int>[];
    for (final d in devs) {
      final pid = d['positionId'];
      if (pid is int) ids.add(pid);
    }
    if (ids.isEmpty) return {};
    final q = ids.map((e) => 'id=$e').join('&');
    final url = Uri.parse('${AppConfig.baseUrl}/api/positions?$q');
    final res = await _client.get(url, headers: {'Cookie': s.cookie});
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      final map = <int, Map<String, dynamic>>{};
      for (final p in list) {
        map[(p['id'] as num).toInt()] = p as Map<String, dynamic>;
      }
      return map;
    }
    throw Exception('Positions failed: ${res.statusCode}');
  }

  Future<List<Map<String, dynamic>>> route(Session s, int deviceId, DateTime from, DateTime to) async {
    // تقرير المسار بالـ POST
    final url = Uri.parse('${AppConfig.baseUrl}/api/reports/route');
    final body = jsonEncode({
      'deviceIds': [deviceId],
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    });
    final res = await _client.post(
      url,
      headers: {'Cookie': s.cookie, 'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Route failed: ${res.statusCode} ${res.body}');
  }

  Future<void> sendEngine(Session s, int deviceId, {required bool stop}) async {
    // 1) أنشئ أمر
    final createUrl = Uri.parse('${AppConfig.baseUrl}/api/commands');
    final cmdType = stop ? 'engineStop' : 'engineResume';
    final create = await _client.post(
      createUrl,
      headers: {'Cookie': s.cookie, 'Content-Type': 'application/json'},
      body: jsonEncode({'type': cmdType}),
    );
    if (create.statusCode != 200) {
      throw Exception('Create command failed: ${create.statusCode}');
    }
    final id = (jsonDecode(create.body) as Map)['id'];

    // 2) أرسل الأمر للجهاز
    final sendUrl = Uri.parse('${AppConfig.baseUrl}/api/commands/send?deviceId=$deviceId&id=$id');
    final send = await _client.post(sendUrl, headers: {'Cookie': s.cookie});
    if (send.statusCode != 204) {
      throw Exception('Send command failed: ${send.statusCode} ${send.body}');
    }
  }
}
