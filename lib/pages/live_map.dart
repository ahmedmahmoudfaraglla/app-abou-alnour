import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api.dart';

class LiveMapPage extends StatefulWidget {
  final Session session;
  const LiveMapPage({super.key, required this.session});

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final MapController _map = MapController();
  final _api = TraccarApi();
  Timer? _timer;
  List<Marker> _markers = [];

  Future<void> _refresh() async {
    try {
      final devs = await _api.devices(widget.session);
      final posMap = await _api.latestPositions(widget.session);
      final markers = devs.where((d) => d['positionId'] != null).map<Marker>((d) {
        final p = posMap[(d['positionId'] as num).toInt()];
        if (p == null) return Marker(point: const LatLng(0,0), builder: (_) => const SizedBox());
        final lat = (p['latitude'] as num).toDouble();
        final lon = (p['longitude'] as num).toDouble();
        final name = (d['name'] ?? '').toString();
        final speed = (p['speed'] ?? 0).toString();
        return Marker(
          point: LatLng(lat, lon),
          width: 160, height: 48,
          builder: (_) => Card(
            color: Colors.black.withOpacity(0.7),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text('$name • $speed km/h', style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      }).toList();
      setState(() => _markers = markers);
      if (markers.isNotEmpty) {
        _map.move(markers.first.point, 14);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _map,
      options: const MapOptions(initialCenter: LatLng(30.0444, 31.2357), initialZoom: 11),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'msncare.tracker'),
        MarkerLayer(markers: _markers),
      ],
    );
  }
}
