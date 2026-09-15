import 'package:flutter/services.dart';

class FeedbackUtils {
  /// Feedback de Sucesso imediato: vibração média + som nativo
  static Future<void> successFeedback() async {
    await HapticFeedback.mediumImpact();
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Feedback de Duplicata / Erro: vibração pesada dupla + som de alerta
  static Future<void> errorFeedback() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Feedback de Seleção de Botão
  static Future<void> tapFeedback() async {
    await HapticFeedback.selectionClick();
  }
}
