class Device {
  final int id;
  final String name;
  final String uniqueId;
  final String status; // online/offline
  Device({required this.id,required this.name,required this.uniqueId,required this.status});
  factory Device.fromJson(Map<String,dynamic> j) => Device(
    id: j['id'],
    name: j['name'] ?? '',
    uniqueId: j['uniqueId']?.toString() ?? '',
    status: j['status'] ?? 'offline',
  );
}
