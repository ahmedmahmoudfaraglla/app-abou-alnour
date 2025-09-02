import 'package:flutter/material.dart';
import '../services/traccar_service.dart';
import '../models.dart';

class DevicesScreen extends StatefulWidget {
  final TraccarService service;
  const DevicesScreen({super.key, required this.service});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late Future<List<Device>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.getDevices();
  }

  Future<void> _send(Device d, bool stop) async {
    final m = ScaffoldMessenger.of(context);
    try {
      await widget.service.sendEngineCommand(d.id, stop: stop);
      m.showSnackBar(SnackBar(content: Text(stop?'تم إرسال إيقاف المحرك':'تم إرسال تشغيل المحرك')));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text('فشل إرسال الأمر: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الأجهزة')),
        body: FutureBuilder<List<Device>>(
          future: _future,
          builder: (c,s){
            if (s.connectionState!=ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return Center(child: Text('خطأ: ${s.error}'));
            }
            final devices = s.data!;
            if (devices.isEmpty) return const Center(child: Text('لا توجد أجهزة'));
            return ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemBuilder: (c,i){
                final d = devices[i];
                final online = d.status == 'online';
                return ListTile(
                  title: Text(d.name),
                  subtitle: Text('${d.uniqueId} • ${online ? 'متصل' : 'غير متصل'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'إيقاف المحرك',
                        icon: const Icon(Icons.stop_circle_outlined),
                        onPressed: ()=> _send(d, true),
                      ),
                      IconButton(
                        tooltip: 'تشغيل المحرك',
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: ()=> _send(d, false),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
