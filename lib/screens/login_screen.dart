import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _lang = 'ar';

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final email = '${_phone.text.trim()}@msncare.local'; // تسجيل برقم الموبايل
    final pwd = _password.text;
    try {
      // اختبار خفيف: استدعاء devices للتأكد من الاعتماديات
      final api = TraccarApi(email, pwd);
      await api.devices();
      await TraccarApi.saveCreds(email, pwd);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(lang: _lang, api: api)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الدخول: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Intl.systemLocale = _lang == 'ar' ? 'ar' : 'en';
    return Directionality(
      textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('MSN Care – تسجيل الدخول')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _lang,
                  decoration: const InputDecoration(labelText: 'اللغة / Language'),
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) => setState(() => _lang = v ?? 'ar'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                  validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  obscureText: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.login),
                    label: const Text('دخول'),
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
