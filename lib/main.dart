import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/api.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (email, pwd) = await TraccarApi.readCreds();
  runApp(App(email: email, password: pwd));
}

class App extends StatelessWidget {
  const App({super.key, this.email, this.password});
  final String? email;
  final String? password;

  @override
  Widget build(BuildContext context) {
    final logged = email != null && password != null;
    return MaterialApp(
      title: 'MSN Care',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: logged ? HomeScreen(lang: 'ar', api: TraccarApi(email!, password!)) : const LoginScreen(),
    );
  }
}
