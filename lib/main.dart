import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const String BASE_URL = "https://msncare.com";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MSN Care Tracker',
        theme: ThemeData.dark(useMaterial3: true),
        home: LoginPage(api: Api(BASE_URL)),
      );
}

class Api {
  final String base;
  String? _basic;
  Api(this.base);

  void setCreds(String u, String p) {
    final b = base64.encode(utf8.encode('$u:$p'));
    _basic = 'Basic $b';
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_basic != null) h['Authorization'] = _basic!;
    return h;
  }

  Future<List> devices() async {
    final r = await http.get(Uri.parse('$base/api/devices'), headers: _headers);
    if (r.statusCode == 200) return jsonDecode(r.body) as List;
    throw Exception('devices ${r.statusCode}');
  }

  Future<Map<String, dynamic>?> positionById(int id) async {
    final uri = Uri.parse('$base/api/positions')
        .replace(queryParameters: {'id': id.toString()});
    final r = await http.get(uri, headers: _headers);
    if (r.statusCode == 200) {
      final list = jsonDecode(r.body) as List;
      if (list.isNotEmpty) return Map<String, dynamic>.from(list.first);
      return null;
    }
    throw Exception('position ${r.statusCode}');
  }

  Future<List> route(int deviceId, DateTime from, DateTime to) async {
    final f = Uri.encodeComponent(from.toUtc().toIso8601String());
    final t = Uri.encodeComponent(to.toUtc().toIso8601String());
    final uri = Uri.parse('$base/api/reports/route').replace(queryParameters: {
      'deviceId': '$deviceId',
      'from': f,
      'to': t,
    });
    final r = await http.get(uri, headers: _headers);
    if (r.statusCode == 200) return jsonDecode(r.body) as List;
    throw Exception('route ${r.statusCode}');
  }

  Future<void> sendCommand(int deviceId, String type,
      [Map<String, dynamic>? params]) async {
    final body = {'deviceId': deviceId, 'type': type};
    if (params != null) body.addAll(params);
    final r = await http.post(Uri.parse('$base/api/commands/send'),
        headers: _headers, body: jsonEncode(body));
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('cmd ${r.statusCode}');
    }
  }
}

class LoginPage extends StatefulWidget {
  final Api api;
  const LoginPage({super.key, required this.api});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;
  String? err;

  Future<void> _go() async {
    setState(() {
      busy = true;
      err = null;
    });
    try {
      final user = phone.text.trim();
      final username = user.contains('@') ? user : '$user@msncare.local';
      widget.api.setCreds(username, pass.text);
      await widget.api.devices(); // probe
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => Home(api: widget.api)));
    } catch (e) {
      setState(() => err = 'فشل الدخول');
    } finally {
      setState(() => busy = false);
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
                const Text('تسجيل الدخول', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 12),
                TextField(controller: phone, decoration: const InputDecoration(labelText: 'رقم الموبايل أو البريد')),
                const SizedBox(height: 8),
                TextField(controller: pass, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
                const SizedBox(height: 12),
                if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
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

class Home extends StatefulWidget {
  final Api api;
  const Home({super.key, required this.api});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> devices = [];
  int? selectedId;
  Timer? poll;
  LatLng? cur;
  List<LatLng> pts = [];
  bool showRoute = false;
  final mapController = MapController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    poll = Timer.periodic(const Duration(seconds: 15), (_) => _pull());
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => loading = true);
    try {
      final l = await widget.api.devices();
      setState(() => devices =
          l.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {}
    setState(() => loading = false);
  }

  Future<void> _pull() async {
    if (selectedId == null) return;
    try {
      final device = devices.firstWhere((d) => d['id'] == selectedId);
      final posId = device['positionId'] as int?;
      if (posId != null) {
        final p = await widget.api.positionById(posId);
        if (p != null) {
          final lat = (p['latitude'] as num).toDouble();
          final lon = (p['longitude'] as num).toDouble();
          setState(() => cur = LatLng(lat, lon));
        }
      }
    } catch (_) {}
  }

  Future<void> _getRoute() async {
    if (selectedId == null) return;
    setState(() => loading = true);
    try {
      final to = DateTime.now();
      final from = to.subtract(const Duration(hours: 6));
      final recs = await widget.api.route(selectedId!, from, to);
      final ptsLocal = <LatLng>[];
      for (final r in recs) {
        final m = Map<String, dynamic>.from(r as Map);
        final lat = (m['latitude'] as num).toDouble();
        final lon = (m['longitude'] as num).toDouble();
        ptsLocal.add(LatLng(lat, lon));
      }
      setState(() {
        pts = ptsLocal;
        showRoute = pts.isNotEmpty;
        if (showRoute) mapController.move(pts.last, 14);
      });
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فشل تحميل المسار')));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _sendCmd(String type) async {
    if (selectedId == null) return;
    setState(() => loading = true);
    try {
      await widget.api.sendCommand(selectedId!, type);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('أُرسل: $type')));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فشل إرسال الأمر')));
    } finally {
      setState(() => loading = false);
    }
  }

  void _openExternalMap(LatLng p) {
    final url =
        Uri.encodeFull('https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext c) {
    final center = cur ?? LatLng(30.0444, 31.2357);
    return Scaffold(
      appBar: AppBar(title: const Text('أجهزتي')),
      body: Column(children: [
        SizedBox(
          height: 140,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d = devices[i];
                    final online = (d['status'] ?? '') == 'online';
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedId = d['id'] as int;
                          cur = null;
                        });
                        _pull();
                      },
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedId == d['id']
                              ? Colors.blueGrey.shade700
                              : Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.directions_car,
                                    color:
                                        online ? Colors.green : Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(d['name'] ?? 'Device',
                                        style:
                                            const TextStyle(fontSize: 16))),
                              ]),
                              const SizedBox(height: 8),
                              Text('ID: ${d['id']} • ${d['status'] ?? 'unknown'}',
                                  style: const TextStyle(fontSize: 12)),
                            ]),
                      ),
                    );
                  },
                ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(center: center, zoom: 13),
            children: [
              const TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (cur != null)
                MarkerLayer(markers: [
                  Marker(
                      point: cur!,
                      width: 40,
                      height: 40,
                      builder: (_) => const Icon(Icons.place, size: 40))
                ]),
              if (showRoute && pts.isNotEmpty)
                PolylineLayer(
                    polylines: [
                      Polyline(
                          points: pts,
                          color: Colors.orangeAccent,
                          strokeWidth: 4.0)
                    ]),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: (selectedId != null && !loading)
                        ? () => _sendCmd('engineStop')
                        : null,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('إيقاف'))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton.icon(
                    onPressed: (selectedId != null && !loading)
                        ? () => _sendCmd('engineResume')
                        : null,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('تشغيل'))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton.icon(
                    onPressed:
                        (selectedId != null && !loading) ? _getRoute : null,
                    icon: const Icon(Icons.timeline),
                    label: const Text('مسار'))),
          ]),
        ),
        const SizedBox(height: 8),
      ]),
      floatingActionButton: cur != null
          ? FloatingActionButton(
              onPressed: () => _openExternalMap(cur!),
              child: const Icon(Icons.open_in_new),
            )
          : null,
    );
  }
}
