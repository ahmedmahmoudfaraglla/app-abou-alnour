import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

class CookieClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  String? _cookie;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (_cookie != null) request.headers['cookie'] = _cookie!;
    return _inner.send(request).then((resp) {
      final sc = resp.headers['set-cookie'];
      if (sc != null && sc.isNotEmpty) {
        // خزّن أول كوكي (JSESSIONID)
        _cookie = sc.split(',').first.split(';').first;
      }
      return resp;
    });
  }
}

class TraccarService {
  final String baseUrl; // مثل: https://msncare.com
  final CookieClient _client = CookieClient();
  TraccarService(this.baseUrl);

  Future<void> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/session');
    final resp = await _client.post(url,
      headers: {'content-type':'application/json'},
      body: jsonEncode({'email': email, 'password': password}));
    if (resp.statusCode != 200) {
      throw Exception('Login failed (${resp.statusCode})');
    }
  }

  Future<List<Device>> getDevices() async {
    final url = Uri.parse('$baseUrl/api/devices');
    final resp = await _client.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Devices failed (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as List;
    return data.map((e)=>Device.fromJson(e)).toList();
  }

  Future<void> sendEngineCommand(int deviceId, {required bool stop}) async {
    // يحاول إرسال أمر engineStop / engineResume مباشرة
    final url = Uri.parse('$baseUrl/api/commands/send');
    final body = {'deviceId': deviceId, 'type': stop ? 'engineStop' : 'engineResume'};
    final resp = await _client.post(url,
      headers: {'content-type':'application/json'},
      body: jsonEncode(body));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Command failed (${resp.statusCode}): ${resp.body}');
    }
  }
}
