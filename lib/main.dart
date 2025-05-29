import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/config/app_theme.dart';
import 'package:pawtastic/config/supabase_config.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:pawtastic/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
      ],
      child: MaterialApp(
        title: 'Pawtastic',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
