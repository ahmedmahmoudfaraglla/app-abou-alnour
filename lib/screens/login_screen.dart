import 'package:flutter/material.dart';
import '../services/traccar_service.dart';
import '../util/i18n.dart';
import 'devices_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _server = TextEditingController(text: 'https://msncare.com'); // بدون /api
  final _phone  = TextEditingController(); // دخول برقم الهاتف فقط
  final _pass   = TextEditingController();
  bool _loading = false;
  String? _error;

  String _normalizeServer(String s) {
    var v = s.trim().replaceAll(RegExp(r'/+$'), '');
    if (v.endsWith('/api')) v = v.substring(0, v.length - 4);
    return v;
  }

  String _phoneToEmail(String phone) => '${phone.trim()}@msncare.local';

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context);
    return Directionality(
      textDirection: t.dir,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.s('login')),
          actions: [
            IconButton(
              tooltip: t.s('toggleLang'),
              onPressed: () => I18n.toggle(context),
              icon: const Icon(Icons.translate),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _server,
                  decoration: InputDecoration(labelText: t.s('server')),
                  validator: (v)=> (v==null||v.isEmpty)?t.s('required'):null,
                ),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: t.s('phone')),
                  validator: (v)=> (v==n

############################################
# lib/screens/login_screen.dart – دخول برقم الهاتف فقط
############################################
cat > lib/screens/login_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../services/traccar_service.dart';
import '../util/i18n.dart';
import 'devices_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _server = TextEditingController(text: 'https://msncare.com'); // بدون /api
  final _phone  = TextEditingController(); // دخول برقم الهاتف فقط
  final _pass   = TextEditingController();
  bool _loading = false;
  String? _error;

  String _normalizeServer(String s) {
    var v = s.trim().replaceAll(RegExp(r'/+$'), '');
    if (v.endsWith('/api')) v = v.substring(0, v.length - 4);
    return v;
  }

  String _phoneToEmail(String phone) => '${phone.trim()}@msncare.local';

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context);
    return Directionality(
      textDirection: t.dir,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.s('login')),
          actions: [
            IconButton(
              tooltip: t.s('toggleLang'),
              onPressed: () => I18n.toggle(context),
              icon: const Icon(Icons.translate),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _server,
                  decoration: InputDecoration(labelText: t.s('server')),
                  validator: (v)=> (v==null||v.isEmpty)?t.s('required'):null,
                ),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: t.s('phone')),
                  validator: (v)=> (v==null||v.isEmpty)?t.s('required'):null,
                ),
                TextFormField(
                  controller: _pass,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t.s('password')),
                  validator: (v)=> (v==null||v.isEmpty)?t.s('required'):null,
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
                        final email  = _phoneToEmail(_phone.text); // نحول لایمیل داخلي
                        final svc = TraccarService(server);
                        await svc.login(email, _pass.text);
                        if(!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_)=> DevicesScreen(service: svc)));
                      } catch (e) {
                        setState(()=>_error = e.toString());
                      } finally { if(mounted) setState(()=>_loading=false); }
                    },
                    child: Text(_loading ? t.s('loggingIn') : t.s('login')),
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
