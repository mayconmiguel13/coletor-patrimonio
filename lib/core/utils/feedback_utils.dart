import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class FeedbackUtils {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  /// Inicializa o contexto de áudio em baixa latência para notificações instantâneas
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      _initialized = true;
    } catch (_) {}
  }

  /// Feedback de Sucesso: Bip sonoro agudo de leitor de código de barras + vibração no motor
  static Future<void> successFeedback() async {
    // 1. Vibração direta no motor físico do aparelho
    HapticFeedback.vibrate();

    // 2. Bip sonoro nítido
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.wav'), volume: 1.0);
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Feedback de Duplicata / Erro: Tom grave de aviso + vibração dupla
  static Future<void> errorFeedback() async {
    // 1. Vibração dupla de alerta
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 120), () {
      HapticFeedback.heavyImpact();
    });

    // 2. Tom de alerta sonoro
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/alert.wav'), volume: 1.0);
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  /// Feedback sutil de toque em botões
  static Future<void> tapFeedback() async {
    await HapticFeedback.selectionClick();
  }
}
