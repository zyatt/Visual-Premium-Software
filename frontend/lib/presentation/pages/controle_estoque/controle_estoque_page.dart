import 'package:flutter/material.dart';
import '../../../data/models/material_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/historico_model.dart';
import '../estoque/saida_material_dialog.dart';

class ControleEstoquePage extends StatefulWidget {
  const ControleEstoquePage({super.key});
  @override
  State<ControleEstoquePage> createState() => _ControleEstoquePageState();
}

class _ControleEstoquePageState extends State<ControleEstoquePage> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().carregarMateriais();
      context.read<MaterialProvider>().carregarHistoricoGeral();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MaterialProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        PageHeader(
          title: 'Controle de Estoque',
          subtitle: 'Gerencie entradas e saídas de materiais',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.output_rounded, size: 18),
              label: const Text('Saída de Material'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusBaixo),
              onPressed: () => _showSaidaSelector(context, prov.materiais.cast<MaterialModel>()),
            ),
            const SizedBox(width: 8),
          ],
        ),
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabs,
            labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: 'Situação do Estoque'),
              Tab(text: 'Histórico de Movimentações'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            _SituacaoEstoque(prov: prov, onSaida: (m) => showDialog(context: context, builder: (_) => SaidaMaterialDialog(material: m))),
            _HistoricoMovimentacoes(historico: prov.historico, loading: prov.loading),
          ]),
        ),
      ]),
    );
  }

  void _showSaidaSelector(BuildContext context, List<MaterialModel> materiais) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Selecionar Material', style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 12),
            ...materiais.map((m) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              title: Text(m.nome, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text('Estoque: ${AppUtils.formatNumber(m.quantidadeAtual)}',
                  style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
              trailing: StatusBadge(status: m.status),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => SaidaMaterialDialog(material: m));
              },
            )),
          ]),
        ),
      ),
    );
  }
}

class _SituacaoEstoque extends StatelessWidget {
  final MaterialProvider prov;
  final void Function(MaterialModel) onSaida;
  const _SituacaoEstoque({required this.prov, required this.onSaida});

  @override
  Widget build(BuildContext context) {
    if (prov.loading) return const LoadingWidget();
    final materiais = prov.materiais.whereType<MaterialModel>().toList();
    final criticos = materiais.where((m) => m.status == 'CRITICO').toList();
    final baixos = materiais.where((m) => m.status == 'BAIXO').toList();
    final oks = materiais.where((m) => m.status == 'OK').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (criticos.isNotEmpty) ...[
          _StatusGroup(label: 'Crítico — Sem Estoque', materiais: criticos, color: AppTheme.statusCritico, onSaida: onSaida),
          const SizedBox(height: 20),
        ],
        if (baixos.isNotEmpty) ...[
          _StatusGroup(label: 'Baixo — Estoque Reduzido', materiais: baixos, color: AppTheme.statusBaixo, onSaida: onSaida),
          const SizedBox(height: 20),
        ],
        if (oks.isNotEmpty)
          _StatusGroup(label: 'Ok — Em Estoque', materiais: oks, color: AppTheme.statusOk, onSaida: onSaida),
      ]),
    );
  }
}

class _StatusGroup extends StatelessWidget {
  final String label;
  final List<MaterialModel> materiais;
  final Color color;
  final void Function(MaterialModel) onSaida;
  const _StatusGroup({
    required this.label,
    required this.materiais,
    required this.color,
    required this.onSaida
  });
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 8),
        Text('(${materiais.length})', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textHint)),
      ]),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.divider)),
        child: Column(
          children: materiais.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final pct = m.estoqueMinimo > 0 ? (m.quantidadeAtual / m.estoqueMinimo).clamp(0.0, 1.0) : 1.0;
            return Column(children: [
              if (i != 0) const Divider(height: 1, color: AppTheme.divider),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Text(m.nome, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13))),
                    Text('${AppUtils.formatNumber(m.quantidadeAtual)} / ${AppUtils.formatNumber(m.estoqueMinimo)} min',
                        style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.output_rounded, size: 13),
                      label: const Text('Saída', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.statusBaixo),
                      onPressed: () => onSaida(m),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ]),
              ),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }
}

class _HistoricoMovimentacoes extends StatelessWidget {
  final List<HistoricoEstoque> historico;
  final bool loading;
  const _HistoricoMovimentacoes({required this.historico, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingWidget();
    if (historico.isEmpty) {
      return const EmptyState(icon: Icons.history_rounded, title: 'Nenhuma movimentação registrada');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: historico.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
      itemBuilder: (_, i) {
        final h = historico[i];
        final isEntrada = h.tipoMovimento == 'ENTRADA';
        final matNome = (h.material?['nome'] as String?) ?? 'Material';
        final ocNum = (h.ordemCompra?['numeroOC'] as String?);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: (isEntrada ? AppTheme.statusOk : AppTheme.statusOk.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEntrada ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isEntrada ? AppTheme.statusOk : AppTheme.statusCritico,
              size: 16,
            ),
          ),
          title: Row(children: [
            Text(isEntrada ? 'Entrada' : 'Saída',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13,
                    color: isEntrada ? AppTheme.statusOk : AppTheme.statusCritico)),
            const SizedBox(width: 6),
            Text('· $matNome', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textPrimary)),
          ]),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Qtd: ${AppUtils.formatNumber(h.quantidade)} · ${AppUtils.formatNumber(h.quantidadeAntes)} → ${AppUtils.formatNumber(h.quantidadeDepois)}',
                style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
            if (ocNum != null)
              Text('OC: $ocNum', style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.accent)),
            if (h.observacoes != null)
              Text(h.observacoes!, style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
          ]),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppUtils.formatDateTime(h.createdAt), style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textHint)),
            if (h.custo != null)
              Text(AppUtils.formatCurrency(h.custo!), style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        );
      },
    );
  }
}