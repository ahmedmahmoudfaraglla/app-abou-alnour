class Device {
  final int id;
  final String name;
  final String uniqueId;
  Device({required this.id, required this.name, required this.uniqueId});
  factory Device.fromJson(Map<String, dynamic> j) =>
      Device(id: j['id'], name: j['name'] ?? 'Device ${j['id']}', uniqueId: j['uniqueId'] ?? '');
}

class Position {
  final double lat, lon;
  final double? speed;
  final DateTime time;
  Position({required this.lat, required this.lon, this.speed, required this.time});
  factory Position.fromJson(Map<String, dynamic> j) => Position(
        lat: (j['latitude'] as num).toDouble(),
        lon: (j['longitude'] as num).toDouble(),
        speed: (j['speed'] as num?)?.toDouble(),
        time: DateTime.parse(j['fixTime']),
      );
}
