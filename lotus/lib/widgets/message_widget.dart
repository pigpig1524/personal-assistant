import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lotus/constants.dart';
import 'dart:io';

Widget buildMessage(BuildContext context, Map<String, String> message) {
  final isUser = message['role'] == 'user';
  final String? userAvatarUrl = FirebaseAuth.instance.currentUser?.photoURL;

  final imagePath = message['image'];
  final hasImage = imagePath != null && imagePath.isNotEmpty;
  final hasText = message['content'] != null && message['content']!.trim().isNotEmpty;

  return Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser)
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/images/bot_avatar.png'),
          ),
        if (!isUser) const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: isUser ? chatusergradient : chatbotgradient,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isUser ? 12 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(),
                            body: Center(
                              child: Image.file(
                                File(imagePath!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagePath!),
                        width: 200,
                        fit: BoxFit.cover,
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (frame == null) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return child;
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, color: Colors.red);
                        },
                      ),
                    ),
                  ),
                if (hasText) ...[
                  if (hasImage) const SizedBox(height: 8),
                  Text(message['content']!, style: chatbody),
                ],
              ],
            ),
          ),
        ),
        if (isUser) const SizedBox(width: 8),
        if (isUser)
          CircleAvatar(
            radius: 18,
            backgroundImage: userAvatarUrl != null
                ? NetworkImage(userAvatarUrl)
                : const AssetImage('assets/images/default_avt.png') as ImageProvider,
          ),
      ],
    ),
  );
}