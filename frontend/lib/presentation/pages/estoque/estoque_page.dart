import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/material_model.dart';
import 'material_form_dialog.dart';
import 'saida_material_dialog.dart';
import 'historico_material_dialog.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});
  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  String _search = '';
  String _filterStatus = 'TODOS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().carregarMateriais();
    });
  }

  List<MaterialModel> _filtered(List<MaterialModel> all) {
    return all.where((m) {
      final matchSearch = m.nome.toLowerCase().contains(_search.toLowerCase());
      final matchStatus = _filterStatus == 'TODOS' || m.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MaterialProvider>();
    final filtered = _filtered(prov.materiais);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Estoque',
            subtitle: '${prov.totalMateriais} materiais cadastrados',
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Novo Material'),
                onPressed: () => _showMaterialForm(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Stats row
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                _MiniStat('Ok', prov.totalOk, AppTheme.statusOk),
                const SizedBox(width: 12),
                _MiniStat('Baixo', prov.totalBaixo, AppTheme.statusBaixo),
                const SizedBox(width: 12),
                _MiniStat('Crítico', prov.totalCritico, AppTheme.statusCritico),
              ],
            ),
          ),
          // Search & filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppTheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar material...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textPrimary),
                    borderRadius: BorderRadius.circular(8),
                    items: const [
                      DropdownMenuItem(value: 'TODOS', child: Text('Todos')),
                      DropdownMenuItem(value: 'OK', child: Text('Ok')),
                      DropdownMenuItem(value: 'BAIXO', child: Text('Baixo')),
                      DropdownMenuItem(value: 'CRITICO', child: Text('Crítico')),
                      DropdownMenuItem(value: 'INATIVO', child: Text('Inativo')),
                    ],
                    onChanged: (v) => setState(() => _filterStatus = v!),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: prov.loading
                ? const LoadingWidget()
                : prov.error != null
                    ? ErrorWidget2(message: prov.error!, onRetry: prov.carregarMateriais)
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'Nenhum material encontrado',
                            action: ElevatedButton(
                              onPressed: () => _showMaterialForm(context),
                              child: const Text('Cadastrar Material'),
                            ),
                          )
                        : _MaterialTable(
                            materiais: filtered,
                            onEdit: (m) => _showMaterialForm(context, material: m),
                            onDesativar: (m) => _desativar(context, m),
                            onReativar: (m) => _reativar(context, m),
                            onSaida: (m) => _showSaida(context, m),
                            onHistorico: (m) => _showHistorico(context, m),
                          ),
          ),
        ],
      ),
    );
  }

  void _showMaterialForm(BuildContext context, {MaterialModel? material}) {
    showDialog(
      context: context,
      builder: (_) => MaterialFormDialog(material: material),
    );
  }

  void _showSaida(BuildContext context, MaterialModel m) {
    showDialog(context: context, builder: (_) => SaidaMaterialDialog(material: m));
  }

  void _showHistorico(BuildContext context, MaterialModel m) {
    showDialog(context: context, builder: (_) => HistoricoMaterialDialog(material: m));
  }

  Future<void> _desativar(BuildContext context, MaterialModel m) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Desativar Material',
      message:
          'Deseja desativar "${m.nome}"? O material permanecerá no estoque como Inativo e poderá ser reativado depois.',
      confirmLabel: 'Desativar',
    );
    if (confirm == true && context.mounted) {
      // Chama o provider para atualizar apenas o status para INATIVO
      final ok = await context.read<MaterialProvider>().desativar(m.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Material desativado.'
              : context.read<MaterialProvider>().error ?? 'Erro'),
        ));
      }
    }
  }

  Future<void> _reativar(BuildContext context, MaterialModel m) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Reativar Material',
      message: 'Deseja reativar "${m.nome}"?',
      confirmLabel: 'Reativar',
      confirmColor: AppTheme.statusOk,
    );
    if (confirm == true && context.mounted) {
      final ok = await context.read<MaterialProvider>().reativar(m.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Material reativado.'
              : context.read<MaterialProvider>().error ?? 'Erro'),
        ));
      }
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $value',
            style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _MaterialTable extends StatelessWidget {
  final List<MaterialModel> materiais;
  final void Function(MaterialModel) onEdit;
  final void Function(MaterialModel) onDesativar;
  final void Function(MaterialModel) onReativar;
  final void Function(MaterialModel) onSaida;
  final void Function(MaterialModel) onHistorico;

  const _MaterialTable({
    required this.materiais,
    required this.onEdit,
    required this.onDesativar,
    required this.onReativar,
    required this.onSaida,
    required this.onHistorico,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  _Th('Material', flex: 3),
                  _Th('Qtd. Atual', flex: 2),
                  _Th('Unidade', flex: 2),
                  _Th('Est. Mínimo', flex: 2),
                  _Th('Saldo', flex: 2),
                  _Th('Últ. Valor Pago', flex: 2),
                  _Th('Status', flex: 2),
                  _Th('Ações', flex: 2, align: TextAlign.center),
                ],
              ),
            ),
            ...materiais.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value;
              final saldo = m.quantidadeAtual - m.estoqueInicial;
              final isInativo = m.status == 'INATIVO';
              return Column(
                children: [
                  if (i != 0) const Divider(height: 1, color: AppTheme.divider),
                  Container(
                    color: isInativo
                        ? AppTheme.divider.withValues(alpha: 0.3)
                        : i.isOdd
                            ? AppTheme.surfaceVariant.withValues(alpha: 0.4)
                            : null,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              if (isInativo)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.block_rounded,
                                      size: 13, color: AppTheme.textHint),
                                ),
                              Flexible(
                                child: Text(m.nome,
                                    style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isInativo
                                            ? AppTheme.textHint
                                            : AppTheme.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(AppUtils.formatNumber(m.quantidadeAtual),
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: isInativo
                                      ? AppTheme.textHint
                                      : AppTheme.textPrimary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            m.unidade?.isNotEmpty == true ? m.unidade! : '—',
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: m.unidade?.isNotEmpty == true
                                    ? (isInativo
                                        ? AppTheme.textHint
                                        : AppTheme.textPrimary)
                                    : AppTheme.textHint),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(AppUtils.formatNumber(m.estoqueMinimo),
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: isInativo
                                      ? AppTheme.textHint
                                      : AppTheme.textPrimary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Icon(
                                saldo >= 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 14,
                                color: isInativo
                                    ? AppTheme.textHint
                                    : saldo >= 0
                                        ? AppTheme.statusOk
                                        : AppTheme.statusCritico,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${saldo >= 0 ? '+' : ''}${AppUtils.formatNumber(saldo)}',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isInativo
                                      ? AppTheme.textHint
                                      : saldo >= 0
                                          ? AppTheme.statusOk
                                          : AppTheme.statusCritico,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(AppUtils.formatCurrency(m.ultimoValorPago),
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: isInativo
                                      ? AppTheme.textHint
                                      : AppTheme.textPrimary)),
                        ),
                        Expanded(flex: 2, child: StatusBadge(status: m.status)),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isInativo) ...[
                                _ActionBtn(Icons.output_rounded, 'Saída',
                                    AppTheme.statusBaixo, () => onSaida(m)),
                                _ActionBtn(Icons.edit_rounded, 'Editar',
                                    AppTheme.primary, () => onEdit(m)),
                                _ActionBtn(Icons.history_rounded, 'Histórico',
                                    AppTheme.textSecondary, () => onHistorico(m)),
                                _ActionBtn(
                                  Icons.block_rounded,
                                  'Desativar',
                                  AppTheme.error,
                                  () => onDesativar(m),
                                ),
                              ] else ...[
                                _ActionBtn(Icons.history_rounded, 'Histórico',
                                    AppTheme.textSecondary, () => onHistorico(m)),
                                _ActionBtn(
                                  Icons.check_circle_outline_rounded,
                                  'Reativar',
                                  AppTheme.statusOk,
                                  () => onReativar(m),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  const _Th(this.text, {this.flex = 1, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            textAlign: align,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.3)),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.tooltip, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      );
}