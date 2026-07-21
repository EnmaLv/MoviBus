import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'modules/splash/splash_screen.dart';
import 'widgets/app_bar.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // 1. Asegurar la vinculación de los bindings de Flutter
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Inicializar Firebase con las opciones de la plataforma actual (Android/iOS)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Cargar preferencias del tema
  final themeProvider = AppThemeProvider();
  await themeProvider.loadPrefs();

  // 4. Iniciar la aplicación
  runApp(BusApp(themeProvider: themeProvider));
}

class BusApp extends StatefulWidget {
  final AppThemeProvider themeProvider;
  const BusApp({super.key, required this.themeProvider});

  @override
  State<BusApp> createState() => _BusAppState();
}

class _BusAppState extends State<BusApp> {
  @override
  void initState() {
    super.initState();
    widget.themeProvider.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UPTP Bienestar',
      themeMode: widget.themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: MoviBusSplashScreen(themeProvider: widget.themeProvider),
    );
  }
}