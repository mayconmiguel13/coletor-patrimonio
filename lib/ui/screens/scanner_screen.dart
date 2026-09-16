import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback_utils.dart';
import '../../state/collection_provider.dart';
import '../widgets/continuity_dialog.dart';
import 'validation_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  bool _isShowingContinuityDialog = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isShowingContinuityDialog) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final provider = context.read<CollectionProvider>();
    final sucesso = await provider.processarCodigo(rawValue);

    if (sucesso && mounted) {
      // Verifica se atingiu a meta do lote atual (ex: 10 CPUs)
      if (provider.atingiuMetaAtual) {
        _abrirDialogoContinuidade();
      }
    }
  }

  void _abrirDialogoContinuidade() async {
    if (_isShowingContinuityDialog) return;
    _isShowingContinuityDialog = true;

    final provider = context.read<CollectionProvider>();
    final tipoAtual = provider.tipoEquipamento;
    final totalAtual = provider.contadorAtual;

    final acao = await ContinuityDialog.show(
      context,
      localidade: provider.localidade,
      tipoConcluido: tipoAtual,
      totalColetado: totalAtual,
    );

    _isShowingContinuityDialog = false;
    if (!mounted) return;

    if (acao == ContinuityAction.coletarOutroTipo) {
      final proximo = tipoAtual == AppConstants.tipoCpu
          ? AppConstants.tipoMonitor
          : AppConstants.tipoCpu;
      provider.setTipoEquipamento(proximo);
      // Mantém no scanner agora coletando o novo tipo
    } else if (acao == ContinuityAction.irParaValidacao) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ValidationScreen()),
      );
    } else if (acao == ContinuityAction.cancelarEDescartar) {
      final confirmar = await _confirmarDescarte();
      if (confirmar == true && mounted) {
        await provider.descartarTudo();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<bool?> _confirmarDescarte() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar Coleta?'),
        content: const Text('Todos os itens coletados nesta sessão serão removidos permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar Coletando'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sim, Descartar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final count = provider.contadorAtual;
    final meta = provider.metaColeta;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) FeedbackUtils.tapFeedback();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            '${provider.localidade} | ${provider.tipoEquipamento}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
              tooltip: 'Lanterna',
              onPressed: () {
                _scannerController.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              tooltip: 'Alternar Câmera',
              onPressed: () => _scannerController.switchCamera(),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Barra de Status e Contador no Topo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          provider.tipoEquipamento == AppConstants.tipoCpu
                              ? Icons.computer
                              : Icons.tv,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Coleta de ${provider.tipoEquipamento}s',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: count >= meta
                            ? AppTheme.successColor.withOpacity(0.15)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✓ $count/$meta coletados',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: count >= meta ? AppTheme.successColor : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Alerta de Duplicado ou Código Lido
              if (provider.mensagemAviso != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  color: AppTheme.warningColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.mensagemAviso!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (provider.ultimoCodigoLido != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: AppTheme.successColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Lido: ${provider.ultimoCodigoLido}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // Câmera ao vivo ocupando ~70% da tela útil
              Expanded(
                flex: 7,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),

                    // Mira / Retângulo Guia
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: provider.ultimoCodigoLido != null
                              ? AppTheme.successColor
                              : Colors.white.withOpacity(0.8),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    // Dica de posicionamento
                    Positioned(
                      bottom: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.crop_free, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Aponte para o QR Code ou Código de Barras',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Painel Inferior de Ações
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Botão Confirmar / Avançar
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              FeedbackUtils.tapFeedback();
                              _abrirDialogoContinuidade();
                            },
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('Avançar / Concluir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Botão Ir para Validação direta
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () {
                              FeedbackUtils.tapFeedback();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ValidationScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Ver Lista'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Link Cancelar Tudo
                    TextButton.icon(
                      onPressed: () async {
                        final descartar = await _confirmarDescarte();
                        if (descartar == true && mounted) {
                          await provider.descartarTudo();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor, size: 18),
                      label: const Text(
                        '⊘ Cancelar e descartar coleta',
                        style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
