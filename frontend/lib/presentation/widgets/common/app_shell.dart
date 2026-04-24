import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Início', route: '/'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Estoque', route: '/estoque'),
    _NavItem(icon: Icons.people_rounded, label: 'Fornecedores', route: '/fornecedores'),
    _NavItem(icon: Icons.compare_arrows_rounded, label: 'Comparativo', route: '/comparativo'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Ordem de Compra', route: '/ordens-compra'),
    _NavItem(icon: Icons.tune_rounded, label: 'Controle de Estoque', route: '/controle-estoque'),
    _NavItem(icon: Icons.tune_rounded, label: 'Histórico de Compras', route: '/historico-compras'),
    _NavItem(icon: Icons.manage_search_rounded, label: 'Histórico Estoque', route: '/historico-estoque'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      body: Row(
        children: [
          if (isWide) _Sidebar(currentRoute: currentRoute, items: _navItems),
          Expanded(child: child),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: _SidebarContent(currentRoute: currentRoute, items: _navItems),
            ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  final List<_NavItem> items;
  const _Sidebar({required this.currentRoute, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: _SidebarContent(currentRoute: currentRoute, items: items),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final String currentRoute;
  final List<_NavItem> items;
  const _SidebarContent({required this.currentRoute, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Visual Premium',
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Gestão de Estoque e Compras',
                    style: GoogleFonts.nunito(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: items
                    .map((item) => _SidebarTile(
                          item: item,
                          isActive: currentRoute == item.route ||
                              (item.route != '/' && currentRoute.startsWith(item.route)),
                        ))
                    .toList(),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'v1.0.0',
                style: GoogleFonts.nunito(color: Colors.white24, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _SidebarTile({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(item.route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? const Border(left: BorderSide(color: AppTheme.accent, width: 3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isActive ? AppTheme.accent : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: GoogleFonts.nunito(
                    color: isActive ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}