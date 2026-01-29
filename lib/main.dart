import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/config/app_theme.dart';
import 'package:pawtastic/config/supabase_config.dart';
import 'package:pawtastic/widgets/connectivity_wrapper.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:pawtastic/screens/splash_screen.dart';
import 'package:pawtastic/providers/payment_provider.dart';
import 'package:pawtastic/providers/service_catalog_provider.dart';
import 'package:pawtastic/services/connectivity_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pawtastic/providers/hotel_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseConfig.initialize();
  // Inicializar datos de formato para los locales que usarás (ej. español de México)

  await initializeDateFormatting('es_MX', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ServiceCatalogProvider()),
        ChangeNotifierProvider(
          create: (_) => HotelProvider(Supabase.instance.client),
        ),
      ],
      child: MaterialApp(
        title: 'Pawtastic',
        theme: AppTheme.lightTheme,
        home: const ConnectivityWrapper(
          child: SplashScreen(),
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'MX'),
        ],
        locale: const Locale('es', 'MX'),
      ),
    );
  }
}
