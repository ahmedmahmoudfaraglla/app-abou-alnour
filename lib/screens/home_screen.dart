import 'package:flutter/material.dart';
import '../services/api.dart';
import 'live_map_screen.dart';
import 'trips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.lang, required this.api});
  final String lang;
  final TraccarApi api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = widget.lang == 'ar';
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MSN Care'),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(icon: Icon(Icons.location_pin), text: 'الخريطة'),
              Tab(icon: Icon(Icons.alt_route), text: 'المسارات'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () async {
                await TraccarApi.clearCreds();
                if (mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.logout),
            )
          ],
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            LiveMapScreen(api: widget.api),
            TripsScreen(api: widget.api),
          ],
        ),
      ),
    );
  }
}
