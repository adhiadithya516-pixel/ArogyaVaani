import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';

class VoiceProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService();

  bool _isSpeaking = false;
  bool _isListening = false;
  String _recognizedText = '';

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<void> speak(String text, {required String languageCode}) async {
    _isSpeaking = true;
    notifyListeners();
    await _voiceService.speak(text, languageCode: languageCode);
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> startListening({
    required String languageCode,
    Function(String text)? onFinalResult,
  }) async {
    _recognizedText = '';
    _isListening = true;
    notifyListeners();

    await _voiceService.startListening(
      languageCode: languageCode,
      onResult: (words) {
        _recognizedText = words;
        notifyListeners();
      },
      onDone: () {
        _isListening = false;
        notifyListeners();
        if (_recognizedText.isNotEmpty) {
          onFinalResult?.call(_recognizedText);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
    _isListening = false;
    notifyListeners();
  }
}