import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/material_model.dart';
import '../../../data/repositories/comparativo_repository.dart';

class ComparativoPage extends StatefulWidget {
  const ComparativoPage({super.key});
  @override
  State<ComparativoPage> createState() => _ComparativoPageState();
}

class _ComparativoPageState extends State<ComparativoPage> {
  final _repo = ComparativoRepository();
  MaterialModel? _materialSelecionado;
  Map<String, dynamic>? _resultado;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().carregarMateriais();
    });
  }

  Future<void> _buscar() async {
    if (_materialSelecionado == null) return;
    setState(() { _loading = true; _error = null; _resultado = null; });
    try {
      final r = await _repo.compararMaterial(_materialSelecionado!.id);
      setState(() { _resultado = r; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final materiais = context.watch<MaterialProvider>().materiais;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        const PageHeader(title: 'Comparativo de Fornecedores', subtitle: 'Compare preços por material'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Seletor
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                child: Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<MaterialModel?>(
                      initialValue: _materialSelecionado,
                      decoration: const InputDecoration(labelText: 'Selecione o Material', isDense: true),
                      items: materiais.map<DropdownMenuItem<MaterialModel?>>((m) {
                        return DropdownMenuItem<MaterialModel?>(
                          value: m as MaterialModel?,
                          child: Text(m.nome),
                        );
                      }).toList(),
                      onChanged: (MaterialModel? v) {
                        setState(() {
                          _materialSelecionado = v;
                          _resultado = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                    label: const Text('Comparar'),
                    onPressed: _materialSelecionado == null || _loading ? null : _buscar,
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              if (_loading) const LoadingWidget(),
              if (_error != null) ErrorWidget2(message: _error!),
              if (_resultado != null) _ResultadoComparativo(resultado: _resultado!),
              if (_resultado == null && !_loading && _error == null)
                const EmptyState(
                  icon: Icons.compare_arrows_rounded,
                  title: 'Selecione um material',
                  message: 'Escolha um material para ver a comparação de preços entre fornecedores.',
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ResultadoComparativo extends StatelessWidget {
  final Map<String, dynamic> resultado;
  const _ResultadoComparativo({required this.resultado});

  @override
  Widget build(BuildContext context) {
    //final material = resultado['material'] as Map<String, dynamic>?;
    final fornecedores = (resultado['fornecedores'] as List?) ?? [];
    final melhor = resultado['melhorFornecedor'] as Map<String, dynamic>?;

    if (fornecedores.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Nenhum fornecedor vinculado',
        message: 'Este material não possui fornecedores com preço cadastrado.',
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Destaque melhor preço
      if (melhor != null)
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.statusOk.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            
            border: Border.all(color: AppTheme.statusOk.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.statusOk.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events_rounded, color: AppTheme.statusOk, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Melhor Preço', style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              Text(melhor['fornecedorNome'] ?? '-',
                  style: GoogleFonts.raleway(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.statusOk)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(AppUtils.formatCurrency((melhor['custo'] as num?)?.toDouble() ?? 0),
                  style: GoogleFonts.raleway(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.statusOk)),
              if (melhor['prazoEntrega'] != null)
                Text(AppUtils.formatPrazo(melhor['prazoEntrega']),
                    style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
            ]),
          ]),
        ),
      // Tabela completa
      Container(
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Expanded(flex: 3, child: Text('Fornecedor', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
              Expanded(flex: 2, child: Text('Preço', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
              Expanded(flex: 2, child: Text('Prazo', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
              Expanded(flex: 1, child: Text('', style: GoogleFonts.nunito(fontSize: 11))),
            ]),
          ),
          ...fornecedores.asMap().entries.map((e) {
            final i = e.key;
            final f = e.value as Map<String, dynamic>;
            final isMelhor = f['melhorPreco'] == true;
            return Column(children: [
              if (i != 0) const Divider(height: 1, color: AppTheme.divider),
              Container(
                color: isMelhor ? AppTheme.statusOk.withValues(alpha: 0.04) : null,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Expanded(flex: 3, child: Row(children: [
                    if (isMelhor) const Icon(Icons.star_rounded, color: AppTheme.statusOk, size: 14),
                    if (isMelhor) const SizedBox(width: 4),
                    Text(f['fornecedorNome'] ?? '-',
                        style: GoogleFonts.nunito(fontWeight: isMelhor ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
                  ])),
                  Expanded(flex: 2, child: Text(
                    AppUtils.formatCurrency((f['custo'] as num?)?.toDouble() ?? 0),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13,
                        color: isMelhor ? AppTheme.statusOk : AppTheme.textPrimary),
                  )),
                  Expanded(flex: 2, child: Text(AppUtils.formatPrazo(f['prazoEntrega']),
                      style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary))),
                  Expanded(flex: 1, child: isMelhor
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.statusOk, borderRadius: BorderRadius.circular(10)),
                          child: Text('Melhor', style: GoogleFonts.nunito(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                        )
                      : const SizedBox()),
                ]),
              ),
            ]);
          }),
        ]),
      ),
    ]);
  }
}