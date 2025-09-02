      - name: Write lib/main.dart
        run: |
          mkdir -p lib
          cat <<'EOF' > lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const String BASE_URL = "https://msncare.com";

void main() => runApp(const AppRoot());

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MSN Care',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
        home: const LoginPage(),
      );
}

class Api {
  final String base;
  String? _basic;
  Api(this.base);

  void setCreds(String u, String p) =>
      _basic = 'Basic ${base64Encode(utf8.encode('$u:$p'))}';

  Map<String, String> get _h {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_basic != null && _basic!.isNotEmpty) {
      h['Authorization'] = _basic!;
    }
    return h;
  }

  Future<List> devices() async {
    final r = await http.get(Uri.parse('$base/api/devices'), headers: _h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw 'devices ${r.statusCode}';
  }

  Future<List> positions(int id) async {
    final r = await http.get(Uri.parse('$base/api/positions?deviceId=$id'), headers: _h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw 'positions ${r.statusCode}';
  }

  Future<List> route(int id, DateTime f, DateTime t) async {
    final u = Uri.parse(
        '$base/api/reports/route?deviceId=$id&from=${f.toUtc().toIso8601String()}&to=${t.toUtc().toIso8601String()}');
    final r = await http.get(u, headers: _h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw 'route ${r.statusCode}';
  }

  Future<void> cmd(int id, String type) async {
    final r = await http.post(Uri.parse('$base/api/commands/send'),
        headers: _h, body: jsonEncode({'deviceId': id, 'type': type}));
    if (r.statusCode != 200) throw 'cmd $type -> ${r.statusCode}';
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;
  String? err;

  _go() async {
    setState(() => busy = true);
    err = null;
    try {
      final api = Api(BASE_URL)..setCreds(phone.text.trim(), pass.text);
      await api.devices(); // smoke test
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => Home(api: api)));
    } catch (e) {
      err = 'فشل الدخول؛ تأكد من الرقم/الباسورد.';
    }
    setState(() => busy = false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('تسجيل الدخول')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'رقم الموبايل (Username)')),
            TextField(
                controller: pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور')),
            const SizedBox(height: 12),
            if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(
                onPressed: busy ? null : _go,
                child: busy
                    ? const CircularProgressIndicator()
                    : const Text('دخول')),
          ]),
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
  List _devices = [];
  int? id;
  Timer? t;
  LatLng? cur;
  List<LatLng> pts = [];
  bool showRoute = false;
  final map = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  _load() async {
    final fetched = await widget.api.devices();
    setState(() {
      _devices = fetched;
      if (_devices.isNotEmpty) id = _devices.first['id'];
    });
    _tick();
  }

  _tick() {
    t?.cancel();
    if (id == null) return;
    t = Timer.periodic(const Duration(seconds: 5), (_) => _pull());
    _pull();
  }

  _pull() async {
    if (id == null) return;
    final p = await widget.api.positions(id!);
    if (p.isEmpty) return;
    final last = p.last;
    final ll = LatLng((last['latitude'] as num).toDouble(),
        (last['longitude'] as num).toDouble());
    setState(() => cur = ll);
    try {
      map.move(ll, 16);
    } catch (_) {}
  }

  _route() async {
    if (id == null) return;
    final n = DateTime.now();
    final f = DateTime(n.year, n.month, n.day);
    final r = await widget.api.route(id!, f, n);
    final newPts = r
        .map<LatLng>((e) => LatLng((e['latitude'] as num).toDouble(),
            (e['longitude'] as num).toDouble()))
        .toList();
    setState(() {
      pts = newPts;
      showRoute = true;
    });
  }

  _cmd(String c) async {
    if (id == null) return;
    final m = ScaffoldMessenger.of(context);
    try {
      await widget.api.cmd(id!, c);
      m.showSnackBar(SnackBar(content: Text('تم: $c')));
    } catch (_) {
      m.showSnackBar(SnackBar(content: Text('فشل: $c')));
    }
  }

  @override
  Widget build(BuildContext c) {
    final markers = <Marker>[];
    if (cur != null) {
      markers.add(Marker(
          point: cur!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, size: 40, color: Colors.red)));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('MSN Care — خريطة حيّة')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: DropdownButton<int>(
                isExpanded: true,
                value: id,
                items: _devices
                    .map<DropdownMenuItem<int>>((d) => DropdownMenuItem(
                        value: d['id'] as int,
                        child: Text('${d['name']} (${d['uniqueId']})')))
                    .toList(),
                onChanged: (v) {
                  setState(() => id = v);
                  _tick();
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _route, child: const Text('مسار اليوم')),
          ]),
        ),
        Expanded(
            child: FlutterMap(
          mapController: map,
          options: MapOptions(
              initialCenter: cur ?? const LatLng(30.0444, 31.2357),
              initialZoom: 6),
          children: [
            TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.msncare.app'),
            MarkerLayer(markers: markers),
            if (showRoute && pts.isNotEmpty)
              PolylineLayer(
                polylines: [Polyline(points: pts, strokeWidth: 4)],
              ),
          ],
        )),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
                child: FilledButton.tonal(
                    onPressed: () => _cmd('engineStop'),
                    child: const Text('إيقاف المحرّك'))),
            const SizedBox(width: 12),
            Expanded(
                child: FilledButton(
                    onPressed: () => _cmd('engineResume'),
                    child: const Text('استئناف المحرّك'))),
          ]),
        ),
      ]),
    );
  }
}
EOF
