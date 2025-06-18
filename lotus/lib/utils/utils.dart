import 'package:flutter/material.dart';

void scrollToBottom(ScrollController scrollController) {
  Future.delayed(const Duration(milliseconds: 300), () {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}