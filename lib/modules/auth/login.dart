import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_bar.dart'; // donde está AppThemeProvider
import '../../widgets/input_field.dart';
import '../Map/map_screen.dart';

class LoginScreen extends StatefulWidget {
  // ── Recibe el themeProvider desde main.dart ───────────────────────────────
  final AppThemeProvider themeProvider;

  const LoginScreen({super.key, required this.themeProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const colorRed      = Color(0xFFB71C1C);
  static const colorRedLight = Color(0xFFD32F2F);
  static const colorBg       = Color(0xFFF5F5F5);
  static const colorText     = Color(0xFF1A1A1A);
  static const colorSubtext  = Color(0xFF666666);

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final result = await ApiService.login(email, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MoviMap(
            // ── Pasa el mismo themeProvider que recibiste ─────────────────
            themeProvider: widget.themeProvider,
            usuario: result['usuario'] as Map<String, dynamic>,
          ),
        ),
      );
    } else {
      setState(() => _error = result['message'] ?? 'Credenciales inválidas.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isWide = size.width > 768;

    return Scaffold(
      backgroundColor: colorBg,
      body: isWide
          ? _buildWideLayout()
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCard(),
              ),
            ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: _buildCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorRed, colorRedLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40B71C1C),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 52, color: Colors.white),
              ),

              const SizedBox(height: 24),

              const Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: colorText,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Ingresa tus credenciales para continuar',
                style: TextStyle(fontSize: 15, color: colorSubtext),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Error
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFC62828), width: 4),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Campo email
              InputField(
                controller: _emailCtrl,
                placeholder: 'Correo electrónico',
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _handleLogin(),
              ),

              const SizedBox(height: 20),

              // Campo contraseña
              InputField(
                controller: _passwordCtrl,
                placeholder: 'Contraseña',
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colorSubtext,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: colorRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Botón login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [colorRed, colorRedLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4DB71C1C),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}