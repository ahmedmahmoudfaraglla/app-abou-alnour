import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/api.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key, required this.api});
  final TraccarApi api;

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  List<Device> _devices = [];
  Device? _selected;
  Position? _pos;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await widget.api.devices();
    setState(() {
      _devices = list;
      _selected = list.isNotEmpty ? list.first : null;
    });
    _bindLive();
  }

  void _bindLive() {
    _sub?.cancel();
    final d = _selected;
    if (d == null) return;
    _sub = widget.api.livePositionStream(d.id).listen((p) {
      if (mounted) setState(() => _pos = p);
    });
  }

  Future<void> _sendCmd(bool stop) async {
    final d = _selected;
    if (d == null) return;
    try {
      await widget.api.sendEngineCommand(deviceId: d.id, stop: stop);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stop ? 'تم إرسال إيقاف المحرك' : 'تم إرسال استئناف المحرك')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال الأمر: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _pos != null ? LatLng(_pos!.lat, _pos!.lon) : const LatLng(30.0444, 31.2357);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<Device>(
                  isExpanded: true,
                  value: _selected,
                  hint: const Text('اختر جهاز'),
                  items: _devices.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                  onChanged: (d) {
                    setState(() => _selected = d);
                    _bindLive();
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _sendCmd(true),
                icon: const Icon(Icons.stop_circle),
                label: const Text('إيقاف'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _sendCmd(false),
                icon: const Icon(Icons.play_circle),
                label: const Text('تشغيل'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'msncare.tracker',
              ),
              if (_pos != null)
                MarkerLayer(markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: center,
                    child: const Icon(Icons.location_on, size: 40, color: Colors.red),
                  )
                ]),
            ],
          ),
        ),
      ],
    );
  }
}
