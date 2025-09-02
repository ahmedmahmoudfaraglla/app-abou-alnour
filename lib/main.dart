import 'package:flutter/material.dart';
void main() => runApp(const App());
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      home: const Scaffold(
        body: Center(child: Text('MSN Care • Clean Build (v1)', style: TextStyle(fontSize: 22))),
      ),
    );
  }
}
