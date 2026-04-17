import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ordem_compra_provider.dart';
import '../../providers/fornecedor_provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/ordem_compra_model.dart';
import 'ordem_compra_form_page.dart';
import 'ordem_compra_detalhe_page.dart';

class OrdemCompraPage extends StatefulWidget {
  const OrdemCompraPage({super.key});
  @override
  State<OrdemCompraPage> createState() => _OrdemCompraPageState();
}

class _OrdemCompraPageState extends State<OrdemCompraPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdemCompraProvider>().carregarOrdens();
      context.read<FornecedorProvider>().carregarFornecedores();
      context.read<MaterialProvider>().carregarMateriais();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<OrdemCompra> _filterByStatus(List<OrdemCompra> all, String status) =>
      all.where((o) => o.status == status && (o.numeroOC.toLowerCase().contains(_search.toLowerCase()) ||
          (o.fornecedor?.nome.toLowerCase().contains(_search.toLowerCase()) ?? false))).toList();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrdemCompraProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        PageHeader(
          title: 'Ordens de Compra',
          subtitle: '${prov.ordens.length} ordens no total',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nova OC'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdemCompraFormPage())),
            ),
            const SizedBox(width: 8),
          ],
        ),
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar por nº OC ou fornecedor...', prefixIcon: Icon(Icons.search_rounded, size: 18), isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            TabBar(
              controller: _tabs,
              labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              tabs: [
                Tab(text: 'Em Andamento (${prov.ordensEmAndamento.length})'),
                Tab(text: 'Finalizadas (${prov.ordensFinalizadas.length})'),
                Tab(text: 'Canceladas (${prov.ordensCanceladas.length})'),
              ],
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: prov.loading
              ? const LoadingWidget()
              : TabBarView(controller: _tabs, children: [
                  _OCList(ordens: _filterByStatus(prov.ordens, 'EM_ANDAMENTO'), onTap: _openDetalhe, onCancelar: _cancelar, onFinalizar: _finalizar),
                  _OCList(ordens: _filterByStatus(prov.ordens, 'FINALIZADO'), onTap: _openDetalhe),
                  _OCList(ordens: _filterByStatus(prov.ordens, 'CANCELADO'), onTap: _openDetalhe),
                ]),
        ),
      ]),
    );
  }

  void _openDetalhe(OrdemCompra oc) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrdemCompraDetalhePage(ordemCompraId: oc.id)));
  }

  Future<void> _cancelar(OrdemCompra oc) async {
    final confirm = await showConfirmDialog(context, title: 'Cancelar OC', message: 'Cancelar a OC ${oc.numeroOC}?', confirmLabel: 'Cancelar OC');
    if (confirm != true) return;
    if (!mounted) return;
    await context.read<OrdemCompraProvider>().cancelar(oc.id);
  }

  Future<void> _finalizar(OrdemCompra oc) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Finalizar OC',
      message: 'Finalizar a OC ${oc.numeroOC}? O estoque será atualizado automaticamente.',
      confirmLabel: 'Finalizar',
      confirmColor: AppTheme.statusOk,
    );

    if (confirm != true) return;

    if (!mounted) return;

    final result = await context.read<OrdemCompraProvider>().finalizar(oc.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result != null
              ? 'OC finalizada! Estoque atualizado.'
              : context.read<OrdemCompraProvider>().error ?? 'Erro',
        ),
      ),
    );

    if (result != null) {
      context.read<MaterialProvider>().carregarMateriais();
    }
  }
}

class _OCList extends StatelessWidget {
  final List<OrdemCompra> ordens;
  final void Function(OrdemCompra) onTap;
  final void Function(OrdemCompra)? onCancelar;
  final void Function(OrdemCompra)? onFinalizar;

  const _OCList({required this.ordens, required this.onTap, this.onCancelar, this.onFinalizar});

  @override
  Widget build(BuildContext context) {
    if (ordens.isEmpty) {
      return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Nenhuma ordem encontrada');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: ordens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final o = ordens[i];
        return Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(o),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('OC ${o.numeroOC}',
                      style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  StatusBadge(status: o.status),
                  const Spacer(),
                  Text(AppUtils.formatCurrency(o.valorTotal),
                      style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.people_rounded, size: 13, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(o.fornecedor?.nome ?? '-', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(AppUtils.formatDate(o.data), style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 16),
                  const Icon(Icons.inventory_2_rounded, size: 13, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text('${o.itens.length} item(s)', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
                if (onCancelar != null || onFinalizar != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (onCancelar != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 14),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => onCancelar!(o),
                      ),
                    const SizedBox(width: 8),
                    if (onFinalizar != null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                        label: const Text('Finalizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusOk,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => onFinalizar!(o),
                      ),
                  ]),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }
}