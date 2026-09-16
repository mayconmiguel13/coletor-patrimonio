import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback_utils.dart';
import '../screens/config_screen.dart';
import '../screens/history_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Cabeçalho estilizado do Drawer
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Coletor de Patrimônio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Coleta ágil e offline de equipamentos',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Itens do Menu
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            title: const Text(
              'Nova Coleta',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            selected: currentRoute == 'config',
            selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.08),
            onTap: () {
              FeedbackUtils.tapFeedback();
              Navigator.of(context).pop();
              if (currentRoute != 'config') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ConfigScreen()),
                );
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.history_rounded, color: AppTheme.primaryColor),
            title: const Text(
              'Histórico de Secretarias',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            selected: currentRoute == 'history',
            selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.08),
            onTap: () {
              FeedbackUtils.tapFeedback();
              Navigator.of(context).pop();
              if (currentRoute != 'history') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.volume_up_outlined, color: AppTheme.primaryColor),
            title: const Text('Testar Bip e Vibração', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Dispara o bip de leitor e vibração física', style: TextStyle(fontSize: 11)),
            onTap: () async {
              await FeedbackUtils.successFeedback();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔊 Bip e 📳 Vibração disparados!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),

          const Divider(),

          const Spacer(),

          // Rodapé informativo
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.secondaryColor),
            title: const Text('Sobre o Aplicativo', style: TextStyle(fontSize: 13)),
            onTap: () {
              FeedbackUtils.tapFeedback();
              showAboutDialog(
                context: context,
                applicationName: 'Coletor Ágil de Patrimônio',
                applicationVersion: 'v1.0.0',
                applicationIcon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor, size: 40),
                children: const [
                  Text('Aplicativo offline de alta velocidade para conferência e inventário de equipamentos.'),
                  SizedBox(height: 8),
                  Text('• Leitura ininterrupta via câmera traseira'),
                  Text('• Bip sonoro e vibração a cada escaneamento'),
                  Text('• Exportação com 3 abas em planilha Excel e TXT'),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
