import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

const String BASE_URL = "http://5.235.244.34:8082"; // عدّله لو لزم

void main() => runApp(const AppRoot());

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MSN Care Tracker',
        theme: ThemeData.dark(useMaterial3: true),
        home: LoginPage(),
      );
}

/* ======================= API ======================= */
class Api {
  final String base;
  final bool demo;
  String? _basic;
  Api(this.base, {this.demo = false});

  factory Api.demo() => Api('demo://', demo: true);

  void setCreds(String user, String pass) {
    if (demo) return;
    final b64 = base64.encode(utf8.encode('$user:$pass'));
    _basic = 'Basic $b64';
  }

  Map<String, String> get _headers {
    final h = {'Accept': 'application/json'};
    if (_basic != null) h['Authorization'] = _basic!;
    return h;
  }

  /* ---------- DEMO DATA ---------- */
  final _demoCenter = const LatLng(30.0486, 31.2336); // وسط القاهرة
  List<Map<String, dynamic>> get _demoDevices => [
        {
          'id': 1,
          'name': 'GT06N-32280',
          'status': 'online',
          'positionId': 101,
        },
        {
          'id': 2,
          'name': 'Tracker-2',
          'status': 'offline',
          'positionId': 201,
        }
      ];

  LatLng _demoPos(int seed) {
    // حركة بسيطة حوالين المركز
    final t = DateTime.now().millisecondsSinceEpoch ~/ 4000;
    final r = 0.01 + (seed == 1 ? 0.0 : 0.003);
    return LatLng(_demoCenter.latitude + r * sin(t), _demoCenter.longitude + r * cos(t));
    // sin/cos محتاجة import 'dart:math';
  }

  List<LatLng> _demoRoute() {
    final List<LatLng> pts = [];
    for (int i = 0; i < 25; i++) {
      final ang = i / 4.0;
      pts.add(LatLng(_demoCenter.latitude + 0.01 * sin(ang), _demoCenter.longitude + 0.01 * cos(ang)));
    }
    return pts;
  }

  /* ---------- Real Calls / Demo Switch ---------- */
  Future<List<Map<String, dynamic>>> devices() async {
    if (demo) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _demoDevices;
    }
    final r = await http.get(Uri.parse('$base/api/devices'), headers: _headers);
    if (r.statusCode != 200) throw Exception('devices ${r.statusCode}');
    return (jsonDecode(r.body) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>?> positionById(int id) async {
    if (demo) {
      await Future.delayed(const Duration(milliseconds: 200));
      final p = id == 101 ? _demoPos(1) : _demoPos(2);
      return {
        'id': id,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'deviceTime': DateTime.now().toIso8601String(),
      };
    }
    final uri = Uri.parse('$base/api/positions').replace(queryParameters: {'id': '$id'});
    final r = await http.get(uri, headers: _headers);
    if (r.statusCode != 200) throw Exception('pos ${r.statusCode}');
    final list = jsonDecode(r.body) as List;
    return list.isEmpty ? null : Map<String, dynamic>.from(list.first as Map);
  }

  Future<List<LatLng>> route(int deviceId, DateTime from, DateTime to) async {
    if (demo) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _demoRoute();
    }
    final uri = Uri.parse('$base/api/reports/route').replace(queryParameters: {
      'deviceId': '$deviceId',
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    });
    final r = await http.get(uri, headers: _headers);
    if (r.statusCode != 200) throw Exception('route ${r.statusCode}');
    final list = (jsonDecode(r.body) as List).cast<Map>();
    return list
        .map((m) => LatLng((m['latitude'] as num).toDouble(), (m['longitude'] as num).toDouble()))
        .toList();
  }

  Future<void> cmd(int deviceId, String type, [Map<String, dynamic>? params]) async {
    if (demo) {
      await Future.delayed(const Duration(milliseconds: 150));
      return;
    }
    final body = {'deviceId': deviceId, 'type': type, if (params != null) ...params};
    final r = await http.post(Uri.parse('$base/api/commands/send'),
        headers: {'Content-Type': 'application/json', ..._headers}, body: jsonEncode(body));
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('cmd ${r.statusCode}');
    }
  }
}

/* ===================== Login ======================= */
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;
  bool demo = true; // افتراضيًا: تجربة
  String? err;

  Future<void> _go() async {
    setState(() {
      busy = true;
      err = null;
    });
    try {
      final api = demo ? Api.demo() : Api(BASE_URL);
      if (!demo) {
        final raw = phone.text.trim();
        final username = raw.contains('@') ? raw : '$raw@msncare.local';
        api.setCreds(username, pass.text);
        await api.devices(); // يتأكد إن الدخول سليم
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Home(api: api)));
    } catch (e) {
      setState(() => err = 'فشل الدخول: تحقق من البيانات أو السيرفر.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('MSN Care Tracker', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('وضع التجربة (بدون سيرفر)'),
                  value: demo,
                  onChanged: (v) => setState(() => demo = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phone,
                  enabled: !demo,
                  decoration: const InputDecoration(labelText: 'رقم الموبايل أو البريد'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pass,
                  enabled: !demo,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  obscureText: true,
                ),
                if (err != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(err!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : _go,
                  child: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('دخول'),
                ),
              ]),
            ),
          ),
        ),
      );
}

/* =================== Home / Map ==================== */
class Home extends StatefulWidget {
  final Api api;
  const Home({super.key, required this.api});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> devices = [];
  int? selectedId;
  LatLng? cur;
  List<LatLng> routePts = [];
  bool loading = false;
  bool showRoute = false;
  final map = MapController();
  Timer? poll;

  @override
  void initState() {
    super.initState();
    _loadDevs();
    poll = Timer.periodic(const Duration(seconds: 5), (_) => _pull());
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> _loadDevs() async {
    setState(() => loading = true);
    try {
      devices = await widget.api.devices();
      if (devices.isNotEmpty) selectedId = devices.first['id'] as int?;
    } catch (_) {}
    setState(() => loading = false);
    _pull();
  }

  Future<void> _pull() async {
    if (selectedId == null) return;
    try {
      final d = devices.firstWhere((e) => e['id'] == selectedId);
      final pid = d['positionId'] as int?;
      if (pid != null) {
        final p = await widget.api.positionById(pid);
        if (p != null) {
          cur = LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble());
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRoute() async {
    if (selectedId == null) return;
    setState(() {
      loading = true;
      showRoute = false;
      routePts = [];
    });
    try {
      final now = DateTime.now();
      routePts = await widget.api.route(selectedId!, now.subtract(const Duration(hours: 6)), now);
      if (routePts.isNotEmpty) {
        showRoute = true;
        map.move(routePts.last, 14);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحميل المسار')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _cmd(String type) async {
    if (selectedId == null) return;
    setState(() => loading = true);
    try {
      await widget.api.cmd(selectedId!, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أُرسل: $type')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إرسال الأمر')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openExt(LatLng p) {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final center = cur ?? const LatLng(30.0444, 31.2357);
    return Scaffold(
      appBar: AppBar(
        title: Text('أجهزتي' + (widget.api.demo ? ' (Demo)' : '')),
      ),
      body: Column(children: [
        SizedBox(
          height: 140,
          child: loading && devices.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  scrollDirection: Axis.horizontal,
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d = devices[i];
                    final selected = d['id'] == selectedId;
                    final online = (d['status'] ?? '') == 'online';
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedId = d['id'] as int?);
                        _pull();
                      },
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.blueGrey.shade700 : Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.directions_car, color: online ? Colors.green : Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(d['name'] ?? 'Device', overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 6),
                          Text('ID: ${d['id']} • ${d['status'] ?? 'unknown'}', style: const TextStyle(fontSize: 12)),
                        ]),
                      ),
                    );
                  },
                ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: map,
            options: MapOptions(center: center, zoom: 13),
            children: [
              const TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (cur != null)
                MarkerLayer(markers: [
                  Marker(point: cur!, width: 40, height: 40, builder: (_) => const Icon(Icons.place, size: 40))
                ]),
              if (showRoute && routePts.isNotEmpty)
                PolylineLayer(polylines: [Polyline(points: routePts, color: Colors.orangeAccent, strokeWidth: 4)]),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: (selectedId != null && !loading) ? () => _cmd('engineStop') : null,
              icon: const Icon(Icons.power_settings_new), label: const Text('إيقاف'),
            )),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(
              onPressed: (selectedId != null && !loading) ? () => _cmd('engineResume') : null,
              icon: const Icon(Icons.restart_alt), label: const Text('تشغيل'),
            )),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(
              onPressed: (selectedId != null && !loading) ? _loadRoute : null,
              icon: const Icon(Icons.timeline), label: const Text('مسار 6 ساعات'),
            )),
          ]),
        ),
      ]),
      floatingActionButton: cur == null ? null : FloatingActionButton(
        onPressed: () => _openExt(cur!), child: const Icon(Icons.open_in_new),
      ),
    );
  }
}
