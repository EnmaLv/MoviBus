import 'package:flutter/material.dart';
import 'modules/auth/login.dart';
import 'widgets/app_bar.dart'; // donde vive AppThemeProvider

void main() {
  runApp(const BusApp());
}

class BusApp extends StatefulWidget {
  const BusApp({super.key});

  @override
  State<BusApp> createState() => _BusAppState();
}

class _BusAppState extends State<BusApp> {
  // Creado una sola vez aquí — se pasa a todas las pantallas
  final _themeProvider = AppThemeProvider();

  @override
  void initState() {
    super.initState();
    // Cuando el tema cambie, reconstruye el MaterialApp
    _themeProvider.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UPTP Bienestar',
      themeMode: _themeProvider.themeMode,
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
      home: LoginScreen(themeProvider: _themeProvider),
    );
  }
}
