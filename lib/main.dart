import 'package:flutter/material.dart';
import 'modules/auth/login.dart';
import 'widgets/app_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = AppThemeProvider();
  await themeProvider.loadPrefs();

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
      home: LoginScreen(themeProvider: widget.themeProvider),
    );
  }
}