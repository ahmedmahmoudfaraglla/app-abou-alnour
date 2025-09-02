import 'package:flutter/material.dart';
import '../services/api.dart';

class CommandsPage extends StatefulWidget {
  final Session session;
  const CommandsPage({super.key, required this.session});

  @override
  State<CommandsPage> createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> {
  final _api = TraccarApi();
  int? _deviceId;

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
                FilledButton.tonal(
                  onPressed: (_deviceId==null)?null:() async {
                    await _api.sendEngine(widget.session, _deviceId!, stop: true);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال إيقاف المحرك')));
                  },
                  child: const Text('إيقاف المحرك'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: (_deviceId==null)?null:() async {
                    await _api.sendEngine(widget.session, _deviceId!, stop: false);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال تشغيل المحرك')));
                  },
                  child: const Text('تشغيل المحرك'),
                ),
              ]),
            );
          },
        ),
      ],
    );
  }
}
