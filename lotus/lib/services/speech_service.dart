import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lotus/utils/utils.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<void> initialize({
    required Function(String) onStatus,
    required Function(String) onError,
  }) async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onStatus: onStatus,
        onError: (error) => onError('Không thể nhận diện giọng nói: ${error.errorMsg}'),
      );
    }
  }

  void toggleListening({
    required TextEditingController controller,
    required bool isListening,
    required Function(bool) onListeningChanged,
    required Function(String) onError,
    required VoidCallback onSendMessage,
    ScrollController? scrollController,
  }) async {
    if (scrollController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom(scrollController);
      });
    }

    if (!isListening) {
      if (!_isInitialized) {
        final available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done') {
              onListeningChanged(false);
            }
          },
          onError: (error) => onError('Không thể nhận diện giọng nói: ${error.errorMsg}'),
        );

        if (!available) {
          onError('Thiết bị không hỗ trợ nhận diện giọng nói.');
          return;
        }
        _isInitialized = true;
      }

      onListeningChanged(true);
      onError('');
      _speech.listen(
        onResult: (result) {
          controller.text = result.recognizedWords;
          if (result.finalResult) {
            if (controller.text.trim().isNotEmpty) {
              onSendMessage(); // Gọi gửi tin nhắn nếu có nội dung
            } else {
              controller.clear(); // Xóa nếu không có nội dung
              onListeningChanged(false); // Tắt lắng nghe
            }
          }
        },
      );
    } else {
      onListeningChanged(false);
      _speech.stop();
      if (controller.text.trim().isEmpty) {
        controller.clear(); // Xóa nội dung nếu dừng mà không gửi
      }
    }
  }
}