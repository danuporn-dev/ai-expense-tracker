import 'package:flutter/material.dart';
import 'core/api.dart';
import 'core/ui.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  api.restore();
  runApp(const MyWalletApp());
}

class MyWalletApp extends StatelessWidget {
  const MyWalletApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'My Wallet AI', debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: AnimatedBuilder(animation: api, builder: (_, __) {
      if (!api.ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (api.restoreError != null) return Scaffold(body: StatusBody(api.restoreError!, retry: api.restore));
      return api.isLoggedIn ? const HomeScreen() : const AuthScreen();
    }),
  );
}