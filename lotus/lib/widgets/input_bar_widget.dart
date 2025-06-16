import 'package:flutter/material.dart';
import 'package:lotus/constants.dart';

Widget buildInputBar({
  required BuildContext context,
  required TextEditingController controller,
  required bool isListening,
  required bool isVoiceInput,
  required bool showKeyboardInput,
  required bool isLoading,
  required VoidCallback onSendMessage,
  required VoidCallback onPickImage,
  required VoidCallback onToggleListening,
  required VoidCallback onToggleKeyboard,
}) {
  if (isListening) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Center(
        child: Column(
          children: [
            const Text(
              "I'm listening...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onToggleListening,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: pautegradient,
                ),
                child: const Icon(Icons.pause, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (showKeyboardInput) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSendMessage(),
              decoration: InputDecoration(
                hintText: 'Message...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onSendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB9B5F8),
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: isLoading ? null : onPickImage,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.deepPurple.shade100),
            ),
            child: const Icon(Icons.add, color: Colors.deepPurple),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  onToggleListening();
                },
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF92A3FD),
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggleKeyboard,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.deepPurple.shade100),
            ),
            child: const Icon(Icons.keyboard, color: Colors.deepPurple),
          ),
        ),
      ],
    ),
  );
}