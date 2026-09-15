import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

enum ContinuityAction {
  coletarOutroTipo,
  irParaValidacao,
  cancelarEDescartar,
}

class ContinuityDialog extends StatelessWidget {
  final String localidade;
  final String tipoConcluido;
  final int totalColetado;
  final String proximoTipo;

  const ContinuityDialog({
    super.key,
    required this.localidade,
    required this.tipoConcluido,
    required this.totalColetado,
    required this.proximoTipo,
  });

  static Future<ContinuityAction?> show(
    BuildContext context, {
    required String localidade,
    required String tipoConcluido,
    required int totalColetado,
  }) {
    final proximoTipo = tipoConcluido == AppConstants.tipoCpu
        ? AppConstants.tipoMonitor
        : AppConstants.tipoCpu;

    return showDialog<ContinuityAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ContinuityDialog(
        localidade: localidade,
        tipoConcluido: tipoConcluido,
        totalColetado: totalColetado,
        proximoTipo: proximoTipo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successColor,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '✓ SUCESSO!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.successColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coleta de ${tipoConcluido}s Concluída',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: $totalColetado equipamentos',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),
            Text(
              'Deseja coletar ${proximoTipo.toUpperCase()}S\npara a mesma localidade?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Localidade: $localidade',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão 1: Coletar próximo tipo
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(ContinuityAction.coletarOutroTipo),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: Text('✓ Sim, coletar ${proximoTipo.toLowerCase()}s'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Botão 2: Ir para validação
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(ContinuityAction.irParaValidacao),
              icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryColor),
              label: const Text('Não, ir para validação'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Botão 3: Cancelar e descartar
            TextButton(
              onPressed: () => Navigator.of(context).pop(ContinuityAction.cancelarEDescartar),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text(
                'Cancelar e descartar tudo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
