import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api.dart';
import '../models/models.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key, required this.api});
  final TraccarApi api;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Device> _devices = [];
  Device? _selected;
  DateTimeRange? _range;
  List<LatLng> _poly = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final list = await widget.api.devices();
    setState(() {
      _devices = list;
      _selected = list.isNotEmpty ? list.first : null;
      _range = DateTimeRange(
        start: DateTime.now().subtract(const Duration(hours: 2)),
        end: DateTime.now(),
      );
    });
  }

  Future<void> _load() async {
    final d = _selected;
    final r = _range;
    if (d == null || r == null) return;
    final pts = await widget.api.route(deviceId: d.id, from: r.start, to: r.end);
    setState(() => _poly = pts.map((p) => LatLng(p.lat, p.lon)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final center = _poly.isNotEmpty ? _poly.last : const LatLng(30.0444, 31.2357);
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
                  onChanged: (d) => setState(() => _selected = d),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final r = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                    initialDateRange: _range,
                  );
                  if (r != null) setState(() => _range = r);
                },
                child: const Text('الفترة'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search),
                label: const Text('عرض'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'msncare.tracker',
              ),
              if (_poly.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(points: _poly, strokeWidth: 4),
                ]),
            ],
          ),
        ),
      ],
    );
  }
}
