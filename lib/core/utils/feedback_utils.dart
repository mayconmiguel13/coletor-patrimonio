import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class FeedbackUtils {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Feedback de Sucesso imediato: vibração média + som
  static Future<void> successFeedback() async {
    // Vibração tátil nativa instantânea
    await HapticFeedback.mediumImpact();

    try {
      // Toca bipe curto ou som do sistema
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Silencioso se o canal não estiver disponível
    }
  }

  /// Feedback de Duplicata / Erro: vibração pesada dupla
  static Future<void> errorFeedback() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);
  }

  /// Feedback de Seleção de Botão
  static Future<void> tapFeedback() async {
    await HapticFeedback.selectionClick();
  }
}
