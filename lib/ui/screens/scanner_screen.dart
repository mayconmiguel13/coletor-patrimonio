import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
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
  MobileScannerController? _scannerController;
  bool _isCameraReady = false;
  String? _cameraError;
  bool _isShowingContinuityDialog = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isCameraReady = false;
      _cameraError = null;
    });

    // 1. Checa e solicita permissão explicitamente
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _cameraError = 'Permissão de câmera não concedida.';
          _isCameraReady = false;
        });
      }
      return;
    }

    // 2. Limpa controller anterior se existir
    if (_scannerController != null) {
      try {
        await _scannerController!.dispose();
      } catch (_) {}
      _scannerController = null;
    }

    // 3. Inicializa novo controller de forma limpa
    try {
      final controller = MobileScannerController(
        autoStart: false,
        facing: CameraFacing.back,
      );

      await controller.start();

      if (mounted) {
        setState(() {
          _scannerController = controller;
          _isCameraReady = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Erro ao inicializar câmera: $e';
          _isCameraReady = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_scannerController == null || !_isCameraReady) return;
    if (state == AppLifecycleState.resumed) {
      _scannerController?.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController?.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
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
    // Coleta contínua e ilimitada sem interrupções automáticas
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
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
              tooltip: 'Lanterna',
              onPressed: _isCameraReady
                  ? () async {
                      await _scannerController?.toggleTorch();
                      setState(() => _isTorchOn = !_isTorchOn);
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              tooltip: 'Alternar Câmera',
              onPressed: _isCameraReady ? () => _scannerController?.switchCamera() : null,
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
                        color: AppTheme.primaryColor.withOpacity(0.12),
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
                    if (_isCameraReady && _scannerController != null)
                      MobileScanner(
                        controller: _scannerController!,
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
                                    'Erro na câmera: ${error.errorCode.name}',
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _initCamera,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reiniciar Câmera'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else if (_cameraError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 54),
                              const SizedBox(height: 16),
                              const Text(
                                'Câmera não iniciada',
                                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _cameraError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final s = await Permission.camera.status;
                                  if (s.isPermanentlyDenied) {
                                    openAppSettings();
                                  } else {
                                    _initCamera();
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar Novamente / Autorizar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Iniciando câmera...',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                    // Mira / Retângulo Guia (visível quando a câmera estiver ativa)
                    if (_isCameraReady)
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
                    if (_isCameraReady)
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
