import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api.dart';

class TripsPage extends StatefulWidget {
  final Session session;
  const TripsPage({super.key, required this.session});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final _api = TraccarApi();
  int? _deviceId;
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(hours: 1)),
    end: DateTime.now(),
  );
  List<LatLng> _points = [];

  Future<void> _load() async {
    if (_deviceId == null) return;
    final rows = await _api.route(widget.session, _deviceId!, _range.start, _range.end);
    final pts = <LatLng>[];
    for (final r in rows) {
      final lat = (r['latitude'] as num).toDouble();
      final lon = (r['longitude'] as num).toDouble();
      pts.add(LatLng(lat, lon));
    }
    setState(() => _points = pts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: _api.devices(widget.session),
          builder: (context, snap) {
            final devs = (snap.data ?? []) as List;
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: const Text('اختر الجهاز'),
                    value: _deviceId,
                    items: devs.map((d) => DropdownMenuItem(
                      value: (d['id'] as num).toInt(), child: Text('${d['name']} (#${d['id']})'),
                    )).toList(),
                    onChanged: (v){ setState(() => _deviceId = v); },
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
                FilledButton(onPressed: _load, child: const Text('عرض')),
              ]),
            );
          },
        ),
        Expanded(
          child: FlutterMap(
            options: const MapOptions(initialCenter: LatLng(30.0444, 31.2357), initialZoom: 11),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'msncare.tracker'),
              PolylineLayer(polylines: [
                Polyline(points: _points, strokeWidth: 4),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
