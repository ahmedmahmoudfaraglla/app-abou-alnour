import 'package:flutter/material.dart';
import '../services/traccar_service.dart';
import '../util/i18n.dart';

class DevicesScreen extends StatefulWidget {
  final TraccarService service;
  const DevicesScreen({super.key, required this.service});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late Future<List<dynamic>> _f;

  @override
  void initState() {
    super.initState();
    _f = widget.service.getDevices();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context);
    return Directionality(
      textDirection: t.dir,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.s('devices')),
          actions: [
            IconButton(
              tooltip: t.s('toggleLang'),
              onPressed: () => I18n.toggle(context),
              icon: const Icon(Icons.translate),
            )
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _f,
          builder: (c, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return Center(child: Text('Error: ${s.error}'));
            }
            final list = s.data ?? const [];
            if (list.isEmpty) return Center(child: Text(t.s('noDevices')));
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = list[i] as Map<String, dynamic>;
                final name = d['name']?.toString() ?? 'Device';
                final id = d['id'] as int;
                return ListTile(
                  title: Text(name),
                  subtitle: Text('ID: $id'),
                  trailing: Wrap(spacing: 8, children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await widget.service.sendCommand(id, 'engineStop');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.s('stopped'))),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: Text(t.s('stop')),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await widget.service.sendCommand(id, 'engineResume');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.s('resumed'))),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: Text(t.s('resume')),
                    ),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
