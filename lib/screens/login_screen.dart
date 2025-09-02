import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/traccar_service.dart';
import 'devices_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _server = TextEditingController(text: 'https://msncare.com'); // عدلها لو عايز
  final _email  = TextEditingController();
  final _pass   = TextEditingController();
  bool _loading = false;
  String? _error;

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
                  decoration: const InputDecoration(labelText: 'رابط الخادم (Server URL)'),
                  validator: (v)=> (v==null||v.isEmpty)?'مطلوب':null,
                ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'البريد/اسم المستخدم'),
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
                        final svc = TraccarService(_server.text.trim());
                        await svc.login(_email.text.trim(), _pass.text);
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
