import 'package:flutter/services.dart';

class FeedbackUtils {
  static const MethodChannel _channel = MethodChannel('com.coletor.patrimonio/feedback');

  /// Inicialização do canal de feedback nativo
  static Future<void> init() async {
    // Canal nativo não requer inicialização assíncrona pesada
  }

  /// Feedback de Sucesso: Bip sonoro agudo de leitor de código de barras + vibração no motor físico
  static Future<void> successFeedback({bool silent = false}) async {
    // 1. Vibração direta no motor físico do aparelho
    HapticFeedback.vibrate();

    // 2. Feedback nativo (Vibração forçada + Bip opcional)
    try {
      if (silent) {
        await _channel.invokeMethod('vibrateOnly');
      } else {
        await _channel.invokeMethod('beepSuccess');
      }
    } catch (_) {
      if (!silent) {
        try {
          await SystemSound.play(SystemSoundType.click);
        } catch (_) {}
      }
    }
  }

  /// Feedback de Duplicata / Erro: Tom grave de aviso + vibração dupla
  static Future<void> errorFeedback({bool silent = false}) async {
    // 1. Vibração dupla de alerta
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 120), () {
      HapticFeedback.heavyImpact();
    });

    // 2. Feedback nativo de erro
    try {
      if (silent) {
        await _channel.invokeMethod('vibrateOnly');
      } else {
        await _channel.invokeMethod('beepError');
      }
    } catch (_) {
      if (!silent) {
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
    }
  }

  /// Feedback sutil de toque em botões
  static Future<void> tapFeedback() async {
    await HapticFeedback.selectionClick();
  }
}
