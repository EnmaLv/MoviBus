import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Configuración ────────────────────────────────────────────────────────────
// Cambia esta URL por la de tu servidor Laravel
const String kBaseUrl = 'http://192.168.1.34:8000/api';
// Para pruebas locales con Android emulator: 'http://10.0.2.2:8000/api'
// Para pruebas locales con dispositivo físico: 'http://TU_IP_LOCAL:8000/api'

void main() {
  runApp(const BusApp());
}

class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoviBus',
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const LoginScreen(),
    );
  }
}

// ─── Servicio API ─────────────────────────────────────────────────────────────
class ApiService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        // Guardar token y datos básicos localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('usuario', jsonEncode(data['usuario']));
        await prefs.setString('modulos', jsonEncode(data['modulos']));
      }

      return {'statusCode': response.statusCode, ...data};
    } catch (e) {
      return {
        'statusCode': 0,
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      await http
          .post(
            Uri.parse('$kBaseUrl/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
    }

    await prefs.clear();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('usuario');
    return raw != null ? jsonDecode(raw) as Map<String, dynamic> : null;
  }
}

// ─── Pantalla de Login ────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const primary = Color(0xFFE61926);
  static const bgDark = Color(0xFF332A2A);
  static const bgLightDarkRed = Color(0xFF633737);
  static const textWhite = Color(0xFFD9D9D9);

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ApiService.login(email, password);

    setState(() => _loading = false);

    if (result['success'] == true) {
      final usuario = result['usuario'] as Map<String, dynamic>;
      final modulos = result['modulos'] as List<dynamic>;

      if (!mounted) return;

      // Navegar al home pasando los datos del usuario
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(usuario: usuario, modulos: modulos),
        ),
      );
    } else {
      setState(() {
        _error = result['message'] ?? 'Error al iniciar sesión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgDark, bgLightDarkRed, primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Icon(Icons.directions_bus, size: 90, color: textWhite),
                  const SizedBox(height: 20),
                  const Text(
                    'MoviBus',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Transporte estudiantil en tiempo real',
                    style: TextStyle(color: textWhite, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // ── Card del formulario ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 20),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email / usuario
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Usuario o correo',
                            prefixIcon: const Icon(Icons.person),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Contraseña
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),

                        // Mensaje de error
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 25),

                        // Botón de login
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              disabledBackgroundColor: primary.withValues(
                                alpha: 0.6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    '© 2026 MoviBus',
                    style: TextStyle(color: textWhite, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pantalla Home (post-login) ───────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final List<dynamic> modulos;

  const HomeScreen({super.key, required this.usuario, required this.modulos});

  static const primary = Color(0xFFE61926);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: Text('Hola, ${usuario['nombre'] ?? 'Usuario'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Módulos disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: modulos.isEmpty
                  ? const Center(child: Text('No tienes módulos asignados.'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                      itemCount: modulos.length,
                      itemBuilder: (_, i) {
                        final mod = modulos[i] as Map<String, dynamic>;
                        return _ModuloCard(modulo: mod);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final Map<String, dynamic> modulo;
  const _ModuloCard({required this.modulo});

  static const primary = Color(0xFFE61926);

  IconData _iconForKey(String key) {
    switch (key) {
      case 'salud':
        return Icons.local_hospital;
      case 'comedor':
        return Icons.restaurant;
      case 'administracion':
        return Icons.settings;
      default:
        return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Aquí navegas al módulo correspondiente
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Módulo: ${modulo['nombre']}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconForKey(modulo['key'] ?? ''), size: 36, color: primary),
              const SizedBox(height: 10),
              Text(
                modulo['nombre'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
