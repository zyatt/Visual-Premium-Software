import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ordem_compra_provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/ordem_compra_model.dart';
import '../../../data/repositories/comparativo_repository.dart';

class OrdemCompraDetalhePage extends StatefulWidget {
  final int ordemCompraId;
  const OrdemCompraDetalhePage({super.key, required this.ordemCompraId});
  @override
  State<OrdemCompraDetalhePage> createState() => _OrdemCompraDetalhePageState();
}

class _OrdemCompraDetalhePageState extends State<OrdemCompraDetalhePage> {
  //OrdemCompra? _oc;
  Map<String, dynamic>? _comparativo;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    context.read<OrdemCompraProvider>();
    context.read<OrdemCompraProvider>().ordens.firstWhere(
      (o) => o.id == widget.ordemCompraId,
      orElse: () => throw Exception('não encontrado'),
    );

    // busca detalhada
    try {
      final repo = ComparativoRepository();
      final comp = await repo.compararPorOrdemCompra(widget.ordemCompraId);
      if (mounted) setState(() { _comparativo = comp; });
    } catch (_) {
      if (mounted) {}
    }
  }

  Future<void> _finalizar() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Finalizar OC',
      message: 'Finalizar esta OC? O estoque será atualizado.',
      confirmLabel: 'Finalizar',
      confirmColor: AppTheme.statusOk,
    );

    if (confirm != true) return;

    if (!mounted) return;

    final result = await context.read<OrdemCompraProvider>().finalizar(widget.ordemCompraId);

    if (!mounted) return;

    if (result != null) {
      context.read<MaterialProvider>().carregarMateriais();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OC finalizada!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _cancelar() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Cancelar OC',
      message: 'Cancelar esta OC?',
      confirmLabel: 'Cancelar OC',
    );

    if (confirm != true) return;

    if (!mounted) return;

    await context.read<OrdemCompraProvider>().cancelar(widget.ordemCompraId);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ocProv = context.watch<OrdemCompraProvider>();
    final oc = ocProv.ordens.where((o) => o.id == widget.ordemCompraId).firstOrNull;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(oc != null ? 'OC ${oc.numeroOC}' : 'Ordem de Compra'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          if (oc?.status == 'EM_ANDAMENTO') ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4))),
              onPressed: _cancelar, child: const Text('Cancelar OC'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusOk),
              onPressed: _finalizar, child: const Text('Finalizar OC'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: oc == null
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Info geral
                _InfoCard(oc: oc),
                const SizedBox(height: 20),
                // Itens
                _ItensCard(oc: oc),
                const SizedBox(height: 20),
                // Comparativo
                if (_comparativo != null) _ComparativoCard(comparativo: _comparativo!),
              ]),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final OrdemCompra oc;
  const _InfoCard({required this.oc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Informações', style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          StatusBadge(status: oc.status),
        ]),
        const SizedBox(height: 16),
        _InfoRow('Nº OC', oc.numeroOC),
        _InfoRow('Data', AppUtils.formatDate(oc.data)),
        _InfoRow('Fornecedor', oc.fornecedor?.nome ?? '-'),
        _InfoRow('Forma de Pagamento', oc.formaPagamento),
        if (oc.observacoes != null) _InfoRow('Observações', oc.observacoes!),
        const Divider(color: AppTheme.divider),
        Row(children: [
          Text('Total Geral', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text(AppUtils.formatCurrency(oc.valorTotal),
              style: GoogleFonts.raleway(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary)),
        ]),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 150, child: Text(label, style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}

class _ItensCard extends StatelessWidget {
  final OrdemCompra oc;
  const _ItensCard({required this.oc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Itens (${oc.itens.length})', style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...oc.itens.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(children: [
            if (i != 0) const Divider(height: 16, color: AppTheme.divider),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.material?.nome ?? 'Material ${item.materialId}',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
                if (item.prazoEntrega != null)
                  Text('Prazo: ${AppUtils.formatPrazo(item.prazoEntrega)}',
                      style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
              ])),
              Text('${AppUtils.formatNumber(item.quantidade)} x ${AppUtils.formatCurrency(item.precoUnitario)}',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 16),
              Text(AppUtils.formatCurrency(item.precoTotal),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
            ]),
          ]);
        }),
      ]),
    );
  }
}

class _ComparativoCard extends StatelessWidget {
  final Map<String, dynamic> comparativo;
  const _ComparativoCard({required this.comparativo});

  @override
  Widget build(BuildContext context) {
    final comps = (comparativo['comparativos'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.compare_arrows_rounded, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Text('Comparativo de Fornecedores', style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        ...comps.map<Widget>((c) {
          final fornecedores = (c['fornecedores'] as List?) ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['materialNome'] ?? '-', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
              Text('Preço nesta OC: ${AppUtils.formatCurrency((c['precoNaOC'] as num?)?.toDouble() ?? 0)}',
                  style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              ...fornecedores.map<Widget>((f) {
                final melhor = f['melhorPreco'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: melhor ? AppTheme.statusOk.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: melhor ? AppTheme.statusOk.withValues(alpha: 0.4) : AppTheme.divider),
                  ),
                  child: Row(children: [
                    if (melhor) const Icon(Icons.star_rounded, color: AppTheme.statusOk, size: 14),
                    if (melhor) const SizedBox(width: 6),
                    Expanded(child: Text(f['fornecedorNome'] ?? '-',
                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: melhor ? FontWeight.w700 : FontWeight.w500))),
                    Text(AppUtils.formatCurrency((f['custo'] as num?)?.toDouble() ?? 0),
                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700,
                            color: melhor ? AppTheme.statusOk : AppTheme.textPrimary)),
                    if (f['prazoEntrega'] != null) ...[
                      const SizedBox(width: 8),
                      Text(AppUtils.formatPrazo(f['prazoEntrega']),
                          style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
                    ],
                  ]),
                );
              }),
            ]),
          );
        }),
      ]),
    );
  }
}