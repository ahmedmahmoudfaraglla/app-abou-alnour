import 'package:flutter/material.dart';
import '../services/traccar_service.dart';
import 'devices_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _server = TextEditingController(text: 'https://msncare.com'); // بدون /api
  final _login  = TextEditingController(); // رقم الموبايل أو الإيميل
  final _pass   = TextEditingController();
  bool _loading = false;
  String? _error;

  String _normalizeServer(String s) {
    var v = s.trim().replaceAll(RegExp(r'/+$'), '');
    if (v.endsWith('/api')) v = v.substring(0, v.length - 4);
    return v;
  }

  String _toEmail(String input) {
    final v = input.trim();
    return v.contains('@') ? v : '$v@msncare.local';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تسجيل الدخول')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _server,
                  decoration: const InputDecoration(labelText: 'رابط الخادم (بدون /api)'),
                  validator: (v)=> (v==null||v.isEmpty)?'مطلوب':null,
                ),
                TextFormField(
                  controller: _login,
                  decoration: const InputDecoration(labelText: 'رقم الموبايل أو الإيميل'),
                  validator: (v)=> (v==null||v.isEmpty)?'مطلوب':null,
                ),
                TextFormField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  validator: (v)=> (v==null||v.isEmpty)?'مطلوب':null,
                ),
                const SizedBox(height: 16),
                if (_error!=null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () async {
                      if(!_form.currentState!.validate()) return;
                      setState(()=>_loading=true); _error=null;
                      try {
                        final server = _normalizeServer(_server.text);
                        final email  = _toEmail(_login.text);
                        final svc = TraccarService(server);
                        await svc.login(email, _pass.text);
                        if(!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_)=> DevicesScreen(service: svc)));
                      } catch (e) {
                        setState(()=>_error = e.toString());
                      } finally { if(mounted) setState(()=>_loading=false); }
                    },
                    child: Text(_loading ? 'جارٍ الدخول...' : 'دخول'),

# 1) اتأكد إن المجلد موجود
mkdir -p lib/screens

# 2) اكتب/حدّث شاشة اللوجين
cat > lib/screens/login_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../services/traccar_service.dart';
import 'devices_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _server = TextEditingController(text: 'https://msncare.com'); // بدون /api
  final _login  = TextEditingController(); // رقم الموبايل أو الإيميل
  final _pass   = TextEditingController();
  bool _loading = false;
  String? _error;

  String _normalizeServer(String s) {
    var v = s.trim().replaceAll(RegExp(r'/+$'), '');
    if (v.endsWith('/api')) v = v.substring(0, v.length - 4);
    return v;
  }

  String _toEmail(String input) {
    final v = input.trim();
    return v.contains('@') ? v : '$v@msncare.local';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تسجيل الدخول')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _server,
                  decoration: const InputDecoration(labelText: 'رابط الخادم (بدون /api)'),
                  validator: (v)=> (v==null||v.isEmpty)?'مطلوب':null,
                ),
                TextFormField(
                  controller: _login,
                  decoration: const InputDecoration(labelText: 'رقم الموبايل أو الإيميل'),
                  validator: (v)=> (v==null||v.isEmpty)?'مطلوب':null,
                ),
                TextFormField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  validator: (v)=> (v==null||v.isEmpty)?'مطلوب':null,
                ),
                const SizedBox(height: 16),
                if (_error!=null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () async {
                      if(!_form.currentState!.validate()) return;
                      setState(()=>_loading=true); _error=null;
                      try {
                        final server = _normalizeServer(_server.text);
                        final email  = _toEmail(_login.text);
                        final svc = TraccarService(server);
                        await svc.login(email, _pass.text);
                        if(!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_)=> DevicesScreen(service: svc)));
                      } catch (e) {
                        setState(()=>_error = e.toString());
                      } finally { if(mounted) setState(()=>_loading=false); }
                    },
                    child: Text(_loading ? 'جارٍ الدخول...' : 'دخول'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
