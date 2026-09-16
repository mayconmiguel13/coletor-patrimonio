import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback_utils.dart';
import '../../state/collection_provider.dart';
import 'scanner_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _localidadeController = TextEditingController();
  String _selectedTipo = AppConstants.tipoCpu;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CollectionProvider>();
    if (provider.localidade.isNotEmpty) {
      _localidadeController.text = provider.localidade;
      _selectedTipo = provider.tipoEquipamento;
    }
  }

  @override
  void dispose() {
    _localidadeController.dispose();
    super.dispose();
  }

  bool get _isFormValid => _localidadeController.text.trim().isNotEmpty;

  Future<void> _iniciarColeta() async {
    if (!_isFormValid) return;

    FeedbackUtils.tapFeedback();

    // 1. Solicita permissão da câmera explicitamente
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permissão de Câmera'),
            content: const Text(
              'O aplicativo precisa de permissão de acesso à câmera para escanear os patrimônios.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openAppSettings();
                },
                child: const Text('Abrir Configurações'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final provider = context.read<CollectionProvider>();
    provider.setLocalidade(_localidadeController.text.trim());
    provider.setTipoEquipamento(_selectedTipo);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COLETA DE EQUIPAMENTOS'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Cartão de Orientações Rápidas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_2, color: AppTheme.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coletor de Patrimônio Ágil',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Escaneamento contínuo de QR Codes e Códigos de Barras.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campo Secretaria / Localidade
              const Text(
                'Secretaria / Localidade *',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _localidadeController,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Ex: Secretaria TI, Almoxarifado, Sala 201',
                  prefixIcon: Icon(Icons.business, color: AppTheme.secondaryColor),
                ),
              ),
              const SizedBox(height: 28),

              // Seleção de Tipo de Equipamento
              const Text(
                'Tipo de Equipamento *',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildRadioOption(
                      title: 'CPU',
                      icon: Icons.computer,
                      value: AppConstants.tipoCpu,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRadioOption(
                      title: 'Monitor',
                      icon: Icons.tv,
                      value: AppConstants.tipoMonitor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Botão Iniciar Coleta
              ElevatedButton.icon(
                onPressed: _isFormValid ? _iniciarColeta : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 26),
                label: const Text('Iniciar Coleta'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isFormValid ? AppTheme.primaryColor : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedTipo == value;

    return InkWell(
      onTap: () {
        FeedbackUtils.tapFeedback();
        setState(() => _selectedTipo = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFD6D6D6),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
              ),
            ),
            const Spacer(),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
