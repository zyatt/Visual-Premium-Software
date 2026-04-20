import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/fornecedor_provider.dart';
import '../../providers/material_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/fornecedor_model.dart';
import 'fornecedor_form_dialog.dart';
import 'vincular_material_dialog.dart';

class FornecedorPage extends StatefulWidget {
  const FornecedorPage({super.key});
  @override
  State<FornecedorPage> createState() => _FornecedorPageState();
}

class _FornecedorPageState extends State<FornecedorPage> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FornecedorProvider>().carregarFornecedores();
      context.read<MaterialProvider>().carregarMateriais();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FornecedorProvider>();
    final filtered = prov.fornecedores
        .where((f) => f.nome.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        PageHeader(
          title: 'Fornecedores',
          subtitle: '${prov.fornecedores.length} fornecedores cadastrados',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Novo Fornecedor'),
              onPressed: () => showDialog(context: context, builder: (_) => const FornecedorFormDialog()),
            ),
            const SizedBox(width: 8),
          ],
        ),
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar fornecedor...', prefixIcon: Icon(Icons.search_rounded, size: 18), isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: prov.loading
              ? const LoadingWidget()
              : filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'Nenhum fornecedor encontrado',
                      action: ElevatedButton(
                        onPressed: () => showDialog(context: context, builder: (_) => const FornecedorFormDialog()),
                        child: const Text('Cadastrar Fornecedor'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _FornecedorCard(
                        fornecedor: filtered[i],
                        onEdit: () => showDialog(context: context, builder: (_) => FornecedorFormDialog(fornecedor: filtered[i])),
                        onDelete: () => _delete(context, filtered[i]),
                        onVincular: () => showDialog(context: context, builder: (_) => VincularMaterialDialog(fornecedor: filtered[i])),
                        onRemoverMaterial: (matId) => _removerMaterial(context, filtered[i].id, matId),
                      ),
                    ),
        ),
      ]),
    );
  }

  Future<void> _delete(BuildContext context, Fornecedor f) async {
    final confirm = await showConfirmDialog(context,
        title: 'Excluir Fornecedor', message: 'Deseja excluir "${f.nome}"?');
    if (confirm == true && context.mounted) {
      await context.read<FornecedorProvider>().deletar(f.id);
    }
  }

  Future<void> _removerMaterial(BuildContext context, int fornId, int matId) async {
    final confirm = await showConfirmDialog(context,
        title: 'Remover Material', message: 'Remover este material do fornecedor?');
    if (confirm == true && context.mounted) {
      await context.read<FornecedorProvider>().removerMaterial(fornId, matId);
    }
  }
}

class _FornecedorCard extends StatelessWidget {
  final Fornecedor fornecedor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onVincular;
  final void Function(int) onRemoverMaterial;

  const _FornecedorCard({
    required this.fornecedor,
    required this.onEdit,
    required this.onDelete,
    required this.onVincular,
    required this.onRemoverMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final f = fornecedor;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              radius: 20,
              child: Text(f.nome[0].toUpperCase(),
                  style: GoogleFonts.raleway(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.nome, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
                if (f.tipoFornecedor != null)
                  Text(f.tipoFornecedor!, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ),
            Row(children: [
              if (f.telefone != null)
                Tooltip(message: f.telefone!, child: const Icon(Icons.phone_rounded, size: 14, color: AppTheme.textHint)),
              if (f.cnpj != null) ...[
                const SizedBox(width: 4),
                Tooltip(message: 'CNPJ: ${f.cnpj}', child: const Icon(Icons.badge_rounded, size: 14, color: AppTheme.textHint)),
              ],
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.link_rounded, size: 16), tooltip: 'Vincular material', onPressed: onVincular, color: AppTheme.accent),
              IconButton(icon: const Icon(Icons.edit_rounded, size: 16), tooltip: 'Editar', onPressed: onEdit, color: AppTheme.primary),
              IconButton(icon: const Icon(Icons.delete_rounded, size: 16), tooltip: 'Excluir', onPressed: onDelete, color: AppTheme.error),
            ]),
          ]),
        ),
        if (f.materiais.where((fm) => fm.material?.status != 'INATIVO').isNotEmpty) ...[
          const Divider(height: 1, color: AppTheme.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Materiais vinculados (${f.materiais.where((fm) => fm.material?.status != 'INATIVO').length})',
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: f.materiais
                    .where((fm) => fm.material?.status != 'INATIVO')
                    .map((fm) => Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                  decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(fm.material?.nome ?? 'Material',
                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text('· ${AppUtils.formatCurrency(fm.custo)}',
                        style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
                    if (fm.prazoEntrega != null)
                      Text(' · ${AppUtils.formatPrazo(fm.prazoEntrega)}',
                          style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textHint)),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onRemoverMaterial(fm.materialId),
                      child: const Icon(Icons.close_rounded, size: 13, color: AppTheme.textHint),
                    ),
                  ]),
                )).toList(),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}