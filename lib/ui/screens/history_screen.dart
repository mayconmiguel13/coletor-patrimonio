import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/export_utils.dart';
import '../../core/utils/feedback_utils.dart';
import '../../data/models/equipment.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../state/collection_provider.dart';
import '../widgets/app_drawer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirDetalhesSecretaria(BuildContext context, String localidade) {
    FeedbackUtils.tapFeedback();
    final provider = context.read<CollectionProvider>();
    final itens = provider.getEquipamentosPorLocalidade(localidade);
    final cpus = itens.where((e) => e.tipo == AppConstants.tipoCpu).toList();
    final monitores = itens.where((e) => e.tipo == AppConstants.tipoMonitor).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            localidade,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${itens.length} itens',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.secondaryColor,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: [
                      Tab(text: 'CPUs (${cpus.length})'),
                      Tab(text: 'Monitores (${monitores.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildItensList(cpus, scrollController),
                        _buildItensList(monitores, scrollController),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItensList(List<Equipment> lista, ScrollController controller) {
    if (lista.isEmpty) {
      return const Center(
        child: Text('Nenhum item deste tipo coletado.'),
      );
    }
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final eq = lista[i];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          title: Text(
            eq.codigoLido,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            dateFormat.format(eq.timestamp),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        );
      },
    );
  }

  Future<void> _exportarSecretaria(BuildContext context, String localidade, bool isExcel) async {
    FeedbackUtils.tapFeedback();
    final provider = context.read<CollectionProvider>();
    try {
      final file = isExcel
          ? await provider.exportarLocalidadeXLSX(localidade)
          : await provider.exportarLocalidadeTXT(localidade);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successColor,
            content: Text('✓ Relatório de $localidade exportado com sucesso!'),
          ),
        );
        await ExportUtils.shareFile(
          file,
          subject: 'Relatório de Coleta - $localidade',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorColor,
            content: Text('Erro ao exportar: $e'),
          ),
        );
      }
    }
  }

  Future<void> _confirmarExclusao(BuildContext context, String localidade) async {
    FeedbackUtils.tapFeedback();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Secretaria?'),
        content: Text(
          'Deseja apagar permanentemente todos os registros de coleta de "$localidade"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sim, Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await context.read<CollectionProvider>().excluirLocalidadeHistorico(localidade);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.warningColor,
            content: Text('Registros de "$localidade" foram removidos.'),
          ),
        );
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final todas = provider.getHistorico();
    final filtradas = todas.where((s) {
      if (_filtro.isEmpty) return true;
      return s.localidade.toLowerCase().contains(_filtro.toLowerCase());
    }).toList();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTÓRICO DE COLETAS'),
      ),
      drawer: const AppDrawer(currentRoute: 'history'),
      body: SafeArea(
        child: Column(
          children: [
            // Campo de busca
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filtro = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Buscar por secretaria ou localidade...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryColor),
                  suffixIcon: _filtro.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filtro = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  isDense: true,
                ),
              ),
            ),

            // Listagem de Secretarias
            Expanded(
              child: filtradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filtro.isNotEmpty
                                ? 'Nenhuma secretaria encontrada para "$_filtro"'
                                : 'Nenhuma coleta registrada ainda.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'As secretarias finalizadas aparecerão aqui.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtradas.length,
                      itemBuilder: (context, index) {
                        final item = filtradas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabeçalho do Card
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.business_rounded,
                                            color: AppTheme.primaryColor,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.localidade,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '✓ ${item.totalGeral} itens',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Detalhes de contagem e data
                                Row(
                                  children: [
                                    _buildBadge('CPUs', item.totalCpus, Icons.computer),
                                    const SizedBox(width: 10),
                                    _buildBadge('Monitores', item.totalMonitores, Icons.tv),
                                    const Spacer(),
                                    Text(
                                      dateFormat.format(item.ultimaColeta),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 20),

                                // Ações Rápidas
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Visualizar
                                    TextButton.icon(
                                      onPressed: () => _abrirDetalhesSecretaria(context, item.localidade),
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      label: const Text('Ver Itens'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                    ),

                                    // Exportar XLSX
                                    TextButton.icon(
                                      onPressed: () => _exportarSecretaria(context, item.localidade, true),
                                      icon: const Icon(Icons.table_view_outlined, size: 18, color: AppTheme.successColor),
                                      label: const Text('Excel', style: TextStyle(color: AppTheme.successColor)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                    ),

                                    // Exportar TXT
                                    TextButton.icon(
                                      onPressed: () => _exportarSecretaria(context, item.localidade, false),
                                      icon: const Icon(Icons.description_outlined, size: 18),
                                      label: const Text('TXT'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                    ),

                                    // Excluir
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor),
                                      tooltip: 'Excluir registros desta secretaria',
                                      onPressed: () => _confirmarExclusao(context, item.localidade),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.secondaryColor),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppTheme.secondaryColor),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
