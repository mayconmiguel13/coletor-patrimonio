import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/export_utils.dart';
import '../../core/utils/feedback_utils.dart';
import '../../state/collection_provider.dart';
import '../widgets/equipment_item_tile.dart';
import 'scanner_screen.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportar(bool isExcel) async {
    final provider = context.read<CollectionProvider>();
    if (provider.equipamentos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum equipamento para exportar.')),
      );
      return;
    }

    setState(() => _isExporting = true);
    FeedbackUtils.tapFeedback();

    try {
      final file = isExcel
          ? await provider.exportarXLSX()
          : await provider.exportarTXT();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successColor,
            content: Text(
              '✓ Arquivo gerado: ${file.path.split(RegExp(r'[\\/]')).last}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 4),
          ),
        );

        // Abre a bandeja nativa para compartilhar ou salvar
        await ExportUtils.shareFile(
          file,
          subject: 'Relatório de Coleta - ${provider.localidade}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorColor,
            content: Text('Erro ao exportar: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final cpus = provider.cpus;
    final monitores = provider.monitores;
    final total = provider.equipamentos.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('VALIDAÇÃO - ${provider.localidade}'),
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Resumo no Topo
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Localidade: ${provider.localidade}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Total: $total itens',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildResumoBadge('CPUs', cpus.length, Icons.computer),
                      const SizedBox(width: 12),
                      _buildResumoBadge('Monitores', monitores.length, Icons.tv),
                    ],
                  ),
                ],
              ),
            ),

            // Abas de Navegação (CPUs / Monitores)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.secondaryColor,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.computer),
                    text: 'CPUs (${cpus.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.tv),
                    text: 'Monitores (${monitores.length})',
                  ),
                ],
              ),
            ),

            // Listas com rolagem e deslize para deletar
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Aba CPUs
                  _buildEquipamentosList(
                    items: cpus,
                    emptyMessage: 'Nenhuma CPU coletada ainda.',
                    onAddMore: () {
                      provider.setTipoEquipamento(AppConstants.tipoCpu);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ScannerScreen()),
                      );
                    },
                  ),

                  // Aba Monitores
                  _buildEquipamentosList(
                    items: monitores,
                    emptyMessage: 'Nenhum Monitor coletado ainda.',
                    onAddMore: () {
                      provider.setTipoEquipamento(AppConstants.tipoMonitor);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ScannerScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Botões Inferiores de Ação e Exportação
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Exportar TXT
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting ? null : () => _exportar(false),
                          icon: const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                          label: const Text('Exportar TXT'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Exportar XLSX
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : () => _exportar(true),
                          icon: const Icon(Icons.table_view_rounded, size: 20),
                          label: const Text('Exportar XLSX'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Botão Voltar para Scanner
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Continuar Escaneando'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoBadge(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.secondaryColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: AppTheme.secondaryColor),
          ),
          Text(
            '$count ✓',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipamentosList({
    required List<dynamic> items,
    required String emptyMessage,
    required VoidCallback onAddMore,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddMore,
                icon: const Icon(Icons.add),
                label: const Text('Escanear Agora'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 44),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final provider = context.read<CollectionProvider>();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final eq = items[index];
        return EquipmentItemTile(
          equipment: eq,
          index: index + 1,
          onDelete: () => provider.deletarEquipamento(eq.id),
        );
      },
    );
  }
}
