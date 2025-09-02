import 'package:flutter/material.dart';
import '../services/api.dart';

class LoginPage extends StatefulWidget {
  final void Function(Session) onLogged;
  const LoginPage({super.key, required this.onLogged});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _api = TraccarApi();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _err;

  Future<void> _doLogin() async {
    setState(() { _loading = true; _err = null; });
    try {
      final s = await _api.login(_user.text.trim(), _pass.text);
      widget.onLogged(s);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('تسجيل الدخول', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(controller: _user, decoration: const InputDecoration(labelText: 'رقم الموبايل أو الإيميل')),
                const SizedBox(height: 8),
                TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة السر')),
                const SizedBox(height: 12),
                if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _doLogin,
                  child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('دخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
