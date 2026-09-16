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
  late final MobileScannerController _scannerController;
  bool _isTorchOn = false;
  bool _isZoomed = false;
  bool _isShowingContinuityDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
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
    await provider.processarCodigo(rawValue);
  }

  void _toggleZoom() async {
    FeedbackUtils.tapFeedback();
    try {
      if (_isZoomed) {
        await _scannerController.resetZoomScale();
        setState(() => _isZoomed = false);
      } else {
        await _scannerController.setZoomScale(0.4);
        setState(() => _isZoomed = true);
      }
    } catch (_) {}
  }

  void _abrirInsercaoManual() {
    FeedbackUtils.tapFeedback();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard_alt_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Digitar Patrimônio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insira o número ou código da etiqueta danificada:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Código do Patrimônio',
                hintText: 'Ex: 014523 ou PAT-102',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => textController.clear(),
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.of(ctx).pop();
                  context.read<CollectionProvider>().processarInsercaoManual(val);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.of(ctx).pop();
                context.read<CollectionProvider>().processarInsercaoManual(val);
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Adicionar'),
          ),
        ],
      ),
    );
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
            // Alternador de Modo Silencioso
            IconButton(
              icon: Icon(
                provider.isSilencioso ? Icons.volume_off : Icons.volume_up,
                color: provider.isSilencioso ? Colors.amberAccent : Colors.white,
              ),
              tooltip: provider.isSilencioso ? 'Silencioso (Só Vibra)' : 'Som e Vibração Ativos',
              onPressed: () => provider.toggleSilencioso(),
            ),

            // Inserção Manual de Código
            IconButton(
              icon: const Icon(Icons.keyboard_alt_outlined),
              tooltip: 'Digitar Patrimônio',
              onPressed: _abrirInsercaoManual,
            ),

            // Lanterna
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
              tooltip: 'Lanterna',
              onPressed: () async {
                await _scannerController.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
            ),

            // Alternar Câmera
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
                    Row(
                      children: [
                        if (provider.isSilencioso)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.volume_off, size: 14, color: Colors.deepOrange),
                                SizedBox(width: 4),
                                Text(
                                  'Mudo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            count == 1 ? '✓ 1 coletado' : '✓ $count coletados',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
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
                      errorBuilder: (context, error, child) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.orange, size: 50),
                                const SizedBox(height: 12),
                                Text(
                                  'Erro na câmera: ${error.errorCode.name}\n${error.errorDetails?.message ?? ""}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _scannerController.stop().then((_) => _scannerController.start());
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reiniciar Câmera'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Mira / Retângulo Guia
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: provider.ultimoCodigoLido != null
                              ? AppTheme.successColor
                              : Colors.white.withValues(alpha: 0.8),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    // Botão Flutuante de Zoom 1x / 2x
                    Positioned(
                      right: 16,
                      bottom: 80,
                      child: GestureDetector(
                        onTap: _toggleZoom,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isZoomed ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_in,
                                color: _isZoomed ? AppTheme.primaryColor : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isZoomed ? '2.0x' : '1.0x',
                                style: TextStyle(
                                  color: _isZoomed ? AppTheme.primaryColor : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Dica de posicionamento
                    Positioned(
                      bottom: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Atalho Digitar Código Manual
                        TextButton.icon(
                          onPressed: _abrirInsercaoManual,
                          icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                          label: const Text(
                            'Digitar Manualmente',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),

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
                            'Descartar',
                            style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                          ),
                        ),
                      ],
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
