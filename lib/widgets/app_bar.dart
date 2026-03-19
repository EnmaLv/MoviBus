import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE ÍTEM DE NAVEGACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class NavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? badge; // texto del badge opcional (ej: "3")

  const NavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badge,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER DE TEMA — gestiona claro/oscuro y persiste en SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────

class AppThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  AppThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDark);
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRA DE NAVEGACIÓN INFERIOR — widget reutilizable
//
// USO BÁSICO:
//   Scaffold(
//     body: ...,
//     bottomNavigationBar: AppBottomNav(
//       items: myItems,
//       currentIndex: _currentIndex,
//       onTap: (i) => setState(() => _currentIndex = i),
//       themeProvider: myThemeProvider,
//       userName: 'Carlos López',
//       onLogout: () { ... },
//     ),
//   )
// ─────────────────────────────────────────────────────────────────────────────

class AppBottomNav extends StatefulWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppThemeProvider themeProvider;
  final String? userName;
  final VoidCallback? onLogout;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.themeProvider,
    this.userName,
    this.onLogout,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  // Paleta
  static const _red      = Color(0xFFB71C1C);
  static const _redLight = Color(0xFFD32F2F);

  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double>   _expandAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOutCubic);
    _fadeAnim   = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
    _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  // Cuántos ítems mostrar en la barra compacta (máx 4 + botón expandir)
  static const _maxVisible = 4;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.themeProvider,
      builder: (context, _) {
        final isDark  = widget.themeProvider.isDark;
        final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final divider = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);
        final textCol = isDark ? Colors.white : const Color(0xFF1A1A1A);
        final subCol  = isDark ? const Color(0xFF888888) : const Color(0xFF666666);

        return AnimatedBuilder(
          animation: _expandAnim,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Panel expandido ───────────────────────────────────────
                if (_expandAnim.value > 0)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SizeTransition(
                      sizeFactor: _expandAnim,
                      axisAlignment: 1,
                      child: _ExpandedPanel(
                        items: widget.items,
                        currentIndex: widget.currentIndex,
                        onTap: (i) {
                          widget.onTap(i);
                          _toggleExpanded();
                        },
                        themeProvider: widget.themeProvider,
                        userName: widget.userName,
                        onLogout: widget.onLogout,
                        bgColor: bgColor,
                        divider: divider,
                        textCol: textCol,
                        subCol: subCol,
                        isDark: isDark,
                      ),
                    ),
                  ),

                // ── Barra compacta ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      top: BorderSide(color: divider, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // Ítems visibles
                          ...List.generate(
                            widget.items.length > _maxVisible
                                ? _maxVisible
                                : widget.items.length,
                            (i) => Expanded(
                              child: _NavBarItem(
                                item: widget.items[i],
                                isActive: widget.currentIndex == i,
                                isDark: isDark,
                                onTap: () => widget.onTap(i),
                              ),
                            ),
                          ),

                          // Botón expandir (siempre visible)
                          Expanded(
                            child: _ExpandButton(
                              expanded: _expanded,
                              isDark: isDark,
                              hasMore: widget.items.length > _maxVisible,
                              onTap: _toggleExpanded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Ítem individual de la barra compacta ────────────────────────────────────
class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  static const _red = Color(0xFFB71C1C);

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveCol = isDark ? const Color(0xFF666666) : const Color(0xFF999999);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador + icono
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _red.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isActive ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 22,
                    color: isActive ? _red : inactiveCol,
                  ),
                ),
                // Badge
                if (item.badge != null)
                  Positioned(
                    right: 6,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? _red : inactiveCol,
              ),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón expandir/contraer ──────────────────────────────────────────────────
class _ExpandButton extends StatelessWidget {
  final bool expanded;
  final bool isDark;
  final bool hasMore;
  final VoidCallback onTap;

  static const _red = Color(0xFFB71C1C);

  const _ExpandButton({
    required this.expanded,
    required this.isDark,
    required this.hasMore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveCol = isDark ? const Color(0xFF666666) : const Color(0xFF999999);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: expanded
                    ? _red.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  hasMore ? Icons.expand_less : Icons.tune,
                  size: 22,
                  color: expanded ? _red : inactiveCol,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              expanded ? 'Cerrar' : (hasMore ? 'Más' : 'Menú'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: expanded ? FontWeight.w700 : FontWeight.w400,
                color: expanded ? _red : inactiveCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Panel expandido ──────────────────────────────────────────────────────────
class _ExpandedPanel extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppThemeProvider themeProvider;
  final String? userName;
  final VoidCallback? onLogout;
  final Color bgColor;
  final Color divider;
  final Color textCol;
  final Color subCol;
  final bool isDark;

  static const _red      = Color(0xFFB71C1C);
  static const _redLight = Color(0xFFD32F2F);

  const _ExpandedPanel({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.themeProvider,
    required this.userName,
    required this.onLogout,
    required this.bgColor,
    required this.divider,
    required this.textCol,
    required this.subCol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado del panel ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_red, _redLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textCol,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'UPTP · Bienestar Estudiantil',
                        style: TextStyle(fontSize: 11, color: subCol),
                      ),
                    ],
                  ),
                ),
                // Toggle tema
                _ThemeToggle(themeProvider: themeProvider, isDark: isDark),
              ],
            ),
          ),

          Divider(color: divider, height: 1),

          // ── Todos los ítems en grid ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              'NAVEGACIÓN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: subCol,
                letterSpacing: 1.2,
              ),
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final isActive = currentIndex == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _red.withValues(alpha: 0.1)
                        : (isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF8F8F8)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? _red.withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive
                            ? (items[i].activeIcon ?? items[i].icon)
                            : items[i].icon,
                        size: 24,
                        color: isActive ? _red : subCol,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        items[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive ? _red : textCol,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Divider(color: divider, height: 1),

          // ── Cerrar sesión ─────────────────────────────────────────────
          if (onLogout != null)
            InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                onLogout!();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: subCol),
                    const SizedBox(width: 12),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(fontSize: 14, color: subCol),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Toggle modo oscuro/claro ─────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  final AppThemeProvider themeProvider;
  final bool isDark;

  static const _red = Color(0xFFB71C1C);

  const _ThemeToggle({required this.themeProvider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        themeProvider.toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? _red : const Color(0xFFE0E0E0),
        ),
        child: Stack(
          children: [
            // Icono luna
            const Positioned(
              left: 6,
              top: 5,
              child: Icon(Icons.nightlight_round, size: 16, color: Colors.white),
            ),
            // Icono sol
            const Positioned(
              right: 6,
              top: 5,
              child: Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFF999999)),
            ),
            // Thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              left: isDark ? 4 : 24,
              top: 3,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}