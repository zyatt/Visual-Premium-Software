import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../providers/ordem_compra_provider.dart';
import '../../providers/fornecedor_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<MaterialProvider>().carregarMateriais(),
      context.read<OrdemCompraProvider>().carregarOrdens(),
      context.read<FornecedorProvider>().carregarFornecedores(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final matProv = context.watch<MaterialProvider>();
    final ocProv = context.watch<OrdemCompraProvider>();
    final fornProv = context.watch<FornecedorProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Dashboard',
            subtitle: 'Visão geral do sistema',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Atualizar',
                onPressed: _load,
              ),
            ],
          ),
          Expanded(
            child: matProv.loading
                ? const LoadingWidget()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row
                        _StatsGrid(matProv: matProv, ocProv: ocProv, fornProv: fornProv),
                        const SizedBox(height: 28),
                        // Alert row
                        if (matProv.totalCritico > 0 || matProv.totalBaixo > 0)
                          _AlertBanner(matProv: matProv),
                        const SizedBox(height: 28),
                        // Quick access
                        Text('Acesso Rápido',
                            style: GoogleFonts.raleway(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        _QuickAccessGrid(),
                        const SizedBox(height: 28),
                        // Recent OC
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ordens de Compra Recentes',
                                style: GoogleFonts.raleway(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            TextButton(
                              onPressed: () => context.go('/ordens-compra'),
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _RecentOCList(ordens: ocProv.ordens.take(5).toList()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final MaterialProvider matProv;
  final OrdemCompraProvider ocProv;
  final FornecedorProvider fornProv;
  const _StatsGrid({required this.matProv, required this.ocProv, required this.fornProv});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          StatCard(
            label: 'Materiais',
            value: '${matProv.totalMateriais}',
            icon: Icons.inventory_2_rounded,
            color: AppTheme.primary,
            subtitle: 'cadastrados',
          ),
          StatCard(
            label: 'Em Estoque',
            value: '${matProv.totalOk}',
            icon: Icons.check_circle_rounded,
            color: AppTheme.statusOk,
            subtitle: 'status ok',
          ),
          StatCard(
            label: 'OC em Andamento',
            value: '${ocProv.ordensEmAndamento.length}',
            icon: Icons.receipt_long_rounded,
            color: AppTheme.accent,
            subtitle: 'pendentes',
          ),
          StatCard(
            label: 'Fornecedores',
            value: '${fornProv.fornecedores.length}',
            icon: Icons.people_rounded,
            color: AppTheme.primaryLight,
            subtitle: 'ativos',
          ),
        ],
      );
    });
  }
}

class _AlertBanner extends StatelessWidget {
  final MaterialProvider matProv;
  const _AlertBanner({required this.matProv});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.statusCritico.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statusCritico.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.statusCritico, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Atenção ao estoque!',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusCritico,
                      fontSize: 14)),
              Text(
                '${matProv.totalCritico} crítico(s) · ${matProv.totalBaixo} baixo(s)',
                style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ]),
          ),
          TextButton(
            onPressed: () => context.go('/estoque'),
            child: const Text('Ver estoque'),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      const _QAItem(Icons.add_box_rounded, 'Novo Material', '/estoque', AppTheme.primary),
      const _QAItem(Icons.person_add_rounded, 'Novo Fornecedor', '/fornecedores', AppTheme.accent),
      const _QAItem(Icons.add_shopping_cart_rounded, 'Nova OC', '/ordens-compra', AppTheme.statusOk),
      const _QAItem(Icons.output_rounded, 'Saída de Material', '/controle-estoque', AppTheme.statusBaixo),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: items
          .map((item) => _QuickCard(item: item))
          .toList(),
    );
  }
}

class _QAItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _QAItem(this.icon, this.label, this.route, this.color);
}

class _QuickCard extends StatelessWidget {
  final _QAItem item;
  const _QuickCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(item.route),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 28),
              const SizedBox(height: 8),
              Text(item.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOCList extends StatelessWidget {
  final List ordens;
  const _RecentOCList({required this.ordens});

  @override
  Widget build(BuildContext context) {
    if (ordens.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhuma ordem de compra',
        message: 'Crie a primeira ordem de compra.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: ordens.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          return Column(
            children: [
              if (i != 0) const Divider(height: 1, color: AppTheme.divider),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_rounded, color: AppTheme.primary, size: 18),
                ),
                title: Text('OC ${o.numeroOC}',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text(
                  '${o.fornecedor?.nome ?? '-'} · ${AppUtils.formatDate(o.data)}',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge(status: o.status),
                    const SizedBox(width: 8),
                    Text(AppUtils.formatCurrency(o.valorTotal),
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
                  ],
                ),
                onTap: () => context.go('/ordens-compra'),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}